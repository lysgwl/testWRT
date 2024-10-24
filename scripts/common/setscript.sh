#!/bin/bash

. diyscripts/plugin-setup.sh
. diyscripts/themes-setup.sh
. diyscripts/system-setup.sh
. diyscripts/network-setup.sh

# 脚本运行参数
SCRIPT_CMD_ARGS=$1
#********************************************************************************#
# 自定义插件
set_openwrt_plugins()
{
	local -n local_source_array="$1"
	print_log "TRACE" "custom config" "正在获取第三方插件..."
	
	local source_type=${local_source_array["Type"]}
	local source_path=${local_source_array["Path"]}
	
	# 自定义插件路径
	local plugins_path="${source_path}/package/${USER_CONFIG_ARRAY["plugins"]}/plugins" 
	if [ ! -d "${plugins_path}" ]; then
		mkdir -p "${plugins_path}"
	fi
	
	# 设置自定义插件
	if ! set_user_plugins ${source_type} ${source_path} ${plugins_path}; then
		return 1
	fi

	return 0
}

# 自定义主题
set_openwrt_themes()
{
	local -n local_source_array="$1"
	print_log "TRACE" "custom config" "正在设置自定义主题..."

	local source_type=${local_source_array["Type"]}
	local source_path=${local_source_array["Path"]}
	
	# 自定义插件路径
	local plugins_path="${source_path}/package/${USER_CONFIG_ARRAY["plugins"]}/themes" 
	if [ ! -d "${plugins_path}" ]; then
		mkdir -p "${plugins_path}"
	fi
	
	# 设置自定义主题
	if ! set_user_themes ${source_type} ${source_path} ${plugins_path}; then
		return 1
	fi
	
	return 0
}

# 自定义配置
set_openwrt_config()
{
	local -n local_source_array="$1"
	print_log "TRACE" "custom config" "正在设置缺省配置..."
	
	local source_type=${local_source_array["Type"]}
	local source_path=${local_source_array["Path"]}
	
	# 设置自定义配置
	set_user_config ${source_type} ${source_path}
	
	# 设置自定义网络
	set_user_network ${source_type} ${source_path}
}

#********************************************************************************#
# 获取源码配置
get_source_config()
{
	file=$1
	
	# _config
	{
		local section_array=()
		get_config_section "_config" "${file}" section_array
		
		if [ ${#section_array[@]} -eq 0 ]; then
			print_log "ERROR" "user config" "没有获取到配置信息, 请检查!"
			return 1
		fi
		
		for section in "${section_array[@]}"; do
			declare -A source_array
			
			if ! get_config_list "${section}" "${file}" source_array; then
				continue
			fi

			# 源码名称
			local source_name="${source_array["Name"]}"
			
			# 源码别名
			local alias_name=${source_array["Alias"]}
			
			if [ -z ${source_name} ] || [ -z ${alias_name} ]; then
				continue
			fi
			
			# 获取源码类型
			local source_type=${SOURCE_TYPE[${source_name}]}
			
			source_array["Type"]=${source_type}
			
			# 判断关联数组是否有效
			if [ ${#source_array[@]} -gt 0 ]; then
				# 源码路径
				source_array["Path"]="${OPENWRT_WORK_PATH}/${alias_name}"
				
				# 设置源码项目结构体
				set_struct_field SOURCE_CONFIG_ARRAY ${source_type} source_array
			fi	
		done
		
		if [ ${#SOURCE_CONFIG_ARRAY[@]} -eq 0 ]; then
			print_log "ERROR" "user config" "获取到配置信息有误, 请检查!"
			return 1
		fi
	}
}

# 获取自定义配置
get_diy_config()
{
	local file=$1
	
	# diyconfig
	{
		declare -A fields_array
		
		if ! get_config_list "diyconfig" "${file}" fields_array; then
			print_log "ERROR" "user config" "无法获取diyconfig配置信息, 请检查!"
			reutrn 1
		fi
		
		# 用户设备
		USER_CONFIG_ARRAY["userdevice"]="${fields_array["user_device"]}"
		
		# 时区
		USER_CONFIG_ARRAY["timezone"]="${fields_array["time_zone"]}"
		
		# 时区名称
		USER_CONFIG_ARRAY["zonename"]="${fields_array["zone_name"]}"
		
		# 缺省名称
		USER_CONFIG_ARRAY["defaultname"]="${fields_array["user_name"]}"
		
		# 缺省密码
		USER_CONFIG_ARRAY["defaultpasswd"]="${fields_array["user_passwd"]}"
		
		# nginx配置
		USER_CONFIG_ARRAY["nginxcfg"]="${fields_array["nginx_cfg"]}"
	}
}

# 获取network接口配置
get_network_config()
{
	local file=$1
	
	# lanconfig
	{
		declare -A fields_array
		
		if ! get_config_list "lanconfig" "${file}" fields_array; then
			print_log "ERROR" "user config" "无法获取lanconfig配置信息, 请检查!"
			reutrn 1
		fi
		
		# lan接口地址
		NETWORK_CONFIG_ARRAY["lanaddr"]="${fields_array["lan_ipaddr"]}"
		
		# lan接口子网掩码
		NETWORK_CONFIG_ARRAY["lannetmask"]="${fields_array["lan_netmask"]}"
		
		# lan接口广播地址
		NETWORK_CONFIG_ARRAY["lanbroadcast"]="${fields_array["lan_broadcast"]}"
		
		# lan接口dhcp起始地址
		NETWORK_CONFIG_ARRAY["landhcpstart"]="${fields_array["lan_dhcp_start"]}"
		
		# lan接口dhcp地址数量
		NETWORK_CONFIG_ARRAY["landhcpnumber"]="${fields_array["lan_dhcp_number"]}"
	}
	
	# wanconfig
	{
		declare -A fields_array
		
		if ! get_config_list "wanconfig" "${file}" fields_array; then
			print_log "ERROR" "user config" "无法获取wanconfig配置信息, 请检查!"
			reutrn 1
		fi
		
		# wan接口地址
		NETWORK_CONFIG_ARRAY["wanaddr"]="${fields_array["wan_ipaddr"]}"
		
		# wan接口子网掩码
		NETWORK_CONFIG_ARRAY["wannetmask"]="${fields_array["wan_netmask"]}"
		
		# wan接口广播地址
		NETWORK_CONFIG_ARRAY["wanbroadcast"]="${fields_array["wan_broadcast"]}"
		
		# wan接口网关地址
		NETWORK_CONFIG_ARRAY["wangateway"]="${fields_array["wan_gateway"]}"
		
		# wan接口dns地址
		NETWORK_CONFIG_ARRAY["wandnsaddr"]="${fields_array["wan_dnsaddr"]}"
	}
}

# 获取用户配置
get_user_config()
{
	if [ $# -eq 0 ]; then
		print_log "ERROR" "user config" "获取配置函数操作有误, 请检查!"
		return 1
	fi
	
	local conf_file=$1
	if [ ! -e "${conf_file}" ]; then
		print_log "ERROR" "user config" "脚本配置文件不存在, 请检查!"
		return 1
	fi
	
	# 获取源码配置
	get_source_config ${conf_file}
	
	# 获取自定义匹配值
	get_diy_config ${conf_file}
	
	# 获取network接口配置
	get_network_config ${conf_file}

	return 0
}

# 设置用户状态
set_user_status()
{
	# 自动编译
	USER_STATUS_ARRAY["autocompile"]=0
	
	# 等待超时
	USER_STATUS_ARRAY["waittimeout"]=5
	
	# 尝试次数
	USER_STATUS_ARRAY["retrycount"]=10

	if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[remote_compile]} ]; then
		USER_STATUS_ARRAY["waittimeout"]=0
		USER_STATUS_ARRAY["retrycount"]=1
	fi
}

# 初始用户配置
init_user_config()
{
	if [ -z "${SCRIPT_CMD_ARGS}" ]; then
		# 0:本地编译环境
		USER_CONFIG_ARRAY["mode"]=${COMPILE_MODE[local_compile]}
		
		# 当前脚本路径
		SCRIPT_CUR_PATH=$(cd `dirname "$0}"` >/dev/null 2>&1; pwd)
		
		# openwrt工作路径
		OPENWRT_WORK_PATH="$SCRIPT_CUR_PATH/$OPENWRT_WORKDIR_NAME"
	else
		# 1:远程编译环境
		USER_CONFIG_ARRAY["mode"]=${COMPILE_MODE[remote_compile]}
		
		# 当前脚本路径
		SCRIPT_CUR_PATH="$GITHUB_WORKSPACE"
		
		# openwrt工作路径
		OPENWRT_WORK_PATH="/$OPENWRT_WORKDIR_NAME"
	fi
	
	# 输出路径
	OPENWRT_OUTPUT_PATH="${SCRIPT_CUR_PATH}/output"

	# 配置路径
	OPENWRT_CONFIG_PATH="${SCRIPT_CUR_PATH}/config"
	
	# 脚本配置文件
	OPENWRT_CONF_FILE="${OPENWRT_CONFIG_PATH}/basic.conf"
	
	# 脚本种子配置文件
	OPENWRT_FEEDS_CONF_FILE="${OPENWRT_CONFIG_PATH}/feeds.conf.default"

	# 种子文件
	OPENWRT_SEED_FILE="${OPENWRT_CONFIG_PATH}/seed.config"
	
	# 插件列表文件
	OPENWRT_PLUGIN_FILE="${OPENWRT_CONFIG_PATH}/plugin_list"
	
	# 获取用户配置
	if ! get_user_config "${OPENWRT_CONF_FILE}"; then
		print_log "ERROR" "user config" "获取用户配置失败, 请检查!"
		return 1
	else
		# 工作目录
		USER_CONFIG_ARRAY["workdir"]="openwrt"
		
		# 缺省配置名称
		USER_CONFIG_ARRAY["defaultconf"]=".config"
		
		# 插件名称
		USER_CONFIG_ARRAY["plugins"]="wl"
		
		# 缺省feeds配置文件
		USER_CONFIG_ARRAY["defaultfeeds"]=""
		
		# 自定义feeds配置文件
		USER_CONFIG_ARRAY["customfeeds"]=""
	fi
	
	# 设置用户状态
	set_user_status
	return 0
}

# 获取固件信息
get_firmware_info()
{
	# 源码数组
	local -n set_source_array="$1"
	
	# 传出结果数组
	local -n result=$2
	
	# 清空结果数组
	result=()
	
	local source_path=${set_source_array["Path"]}
	local source_type=${set_source_array["Type"]}
	
	# 缺省配置文件
	local defaultconf="${USER_CONFIG_ARRAY["defaultconf"]}"
	if [ ! -f "${source_path}/${defaultconf}" ]; then
		print_log "ERROR" "custom config" "配置文件不存在, 请检查!"
		return 1
	fi
	
	# 获取版本号
	if [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
		local file="${source_path}/package/lean/default-settings/files/zzz-default-settings"
		if [ -e ${file} ]; then
			version_num=$(sed -n "s/echo \"DISTRIB_REVISION='\([^\']*\)'.*$/\1/p" $file)
		fi
	else
		local file="${source_path}/include/version.mk"
		if [ -e ${file} ]; then
			line=$(awk -F ':=' '/^VERSION_NUMBER:/ {line=$2} END {print line}' $file)
			if [ -n "${line}" ]; then
				version_num=$(echo $line | sed -E 's/.*\(([^,]+),[^,]+,([^)]*)\).*/\2/')
			fi
		fi
	fi
	
	# 架构名称
	arch_name=$(sed -n -r 's/^CONFIG_TARGET_DEVICE_(.*)_DEVICE.*=y/\1/p' "${source_path}/${defaultconf}" | head -n 1)
	arch_name=$(echo "${arch_name}" | sed 's/_/-/g')
	
	result["name"]="openwrt-${arch_name}"
	result["path"]="${OPENWRT_OUTPUT_PATH}/$(date +"%Y%m%d")"
	result["version"]="${version_num}"
	
	# 获取设备名称
	local device_array=()
	while IFS= read -r line; do
		if [[ ! $line =~ ^CONFIG_TARGET.*DEVICE.*=y ]]; then
			continue
		fi
		
		local device_name=$(echo "$line" | sed -r 's/.*DEVICE_(.*)=y/\1/')
		if [ -z "${device_name}" ]; then
			continue
		fi
		
		# 获取固件名称
		local firmware_name="openwrt"
		if [ -n "${version_num}" ]; then
			firmware_name="${firmware_name}-${version_num}"
		fi
		
		local file_date=$(date +"%Y%m%d%H%M")
		firmware_name="${firmware_name}-${device_name}-${file_date}"
		
		device_array+=("${device_name}:${firmware_name}")
	done < "${source_path}/${defaultconf}"
	
	result["devices"]="${device_array[@]}"
	return 0
}

# 移除插件包
remove_plugin_package()
{
	local section_name=$1
	local source_path=$2
	
	local conf_file=$3
	local -n fields_array=$4
	
	if [ ! -e "${conf_file}" ]; then
		print_log "ERROR" "user config" "插件配置文件不存在, 请检查!"
		return
	fi
	
	local plugin_array=()
	if ! get_config_list "${section_name}" "${conf_file}" plugin_array; then
		return
	fi
	
	# 查找要排除的部分
	local exclude_expr=""
	
	if [ ${#fields_array[@]} -gt 0 ]; then
		for path in "${fields_array[@]}"; do
			exclude_expr+=" -path ${path} -o"
		done
		
		# 去掉最后一个 '-o'
		exclude_expr="${exclude_expr% -o}"
	fi
	
	for value in "${plugin_array[@]}"; do
		if [ -z "${exclude_expr}" ]; then
			find ${source_path} -name "${value}" | xargs rm -rf;
		else
			find ${source_path} \( ${exclude_expr} \) -prune -o -name ${value} -print0 | xargs -0 rm -rf;
		fi
	done
}