#!/bin/bash

#********************************************************************************#
# 下载 argon主题
download_themes_argon()
{
	local plugin_path=$1
	local -n source_array_ref=$2
	
	local source_type=${source_array_ref["Type"]}

	# luci-theme-argon
	{
		print_log "INFO" "custom config" "获取luci-theme-argon仓库代码..."
		
		if [ ${source_type} -eq ${SOURCE_TYPE[openwrt]} ] || [ ${source_type} -eq ${SOURCE_TYPE[immortalwrt]} ]; then
			local url="https://github.com/jerrykuku/luci-theme-argon.git?ref=master"
		elif [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
			#url="https://github.com/jerrykuku/luci-theme-argon.git?ref=18.06"
			local url="https://github.com/jerrykuku/luci-theme-argon.git?ref=master"
		fi
		
		if ! clone_repo_contents $url "${plugin_path}/luci-theme-argon" ${NETWORK_PROXY_CMD}; then
			print_log "ERROR" "custom config" "获取luci-theme-argons仓库代码失败, 请检查!"
			return 1
		fi
	}
	
	# luci-theme-argon-config
	{
		print_log "INFO" "custom config" "获取luci-theme-argon-config仓库代码..."
		
		if [ ${source_type} -eq ${SOURCE_TYPE[openwrt]} ] || [ ${source_type} -eq ${SOURCE_TYPE[immortalwrt]} ]; then
			local url="https://github.com/jerrykuku/luci-app-argon-config.git?ref=master"
		elif [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
			#url="https://github.com/jerrykuku/luci-app-argon-config.git?ref=18.06"
			local url="https://github.com/jerrykuku/luci-app-argon-config.git?ref=master"
		fi
		
		if ! clone_repo_contents $url "${plugin_path}/luci-theme-argon-config" ${NETWORK_PROXY_CMD}; then
			print_log "ERROR" "custom config" "获取luci-theme-argon-config仓库代码失败, 请检查!"
			return 1
		fi
	}
	
	return 0
}

# 下载 edge主题
download_themes_edge()
{
	print_log "INFO" "custom config" "获取luci-theme-edge仓库代码..."
	
	local plugin_path=$1

	# luci-theme-edge	
	local url="https://github.com/kiddin9/luci-theme-edge.git?ref=18.06"
	if ! clone_repo_contents $url "${plugin_path}/luci-theme-edge" ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取luci-theme-edge仓库代码失败, 请检查!"
		return 1
	fi

	return 0
}

#********************************************************************************#
# 设置默认主题
set_default_themes()
{
	print_log "INFO" "custom config" "[修改默认主题]"
	
	local -n source_array_ref=$1
	
	local source_type=${source_array_ref["Type"]}
	local source_path=${source_array_ref["Path"]}
	
	local file="${source_path}/feeds/luci/collections/luci/Makefile"
	
	if [ -e ${file} ]; then
		if [ ${source_type} -eq ${SOURCE_TYPE[openwrt]} ] || [ ${source_type} -eq ${SOURCE_TYPE[immortalwrt]} ]; then
			sed -i 's/luci-light/luci-theme-argon/g' ${file}
		elif [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
			sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' ${file}
		fi
	fi
}

# 设置主题移除
set_themes_remove()
{
	local plugin_path=$1
	local -n source_array_ref=$2
	
	local source_path=${source_array_ref["Path"]}
	if [ -z "${source_path}" ] || [ ! -d "${source_path}" ]; then
		return
	fi
	
	local user_array=()
	local source_array=("${source_path}")
	
	for value in "${source_array[@]}"; do
		# 排除数组
		local exclude_array=()
		
		# 排除json数组
		local exclude_json_array=$(build_json_array exclude_array)
		
		# 对象关联数组
		declare -A object_array=(
			["source_path"]="$value"
			["exclude_path"]=${exclude_json_array}
		)
		
		# 对象json数组
		object_json=$(build_json_object object_array)
		user_array+=("$object_json")
	done
	
	local user_json_array=$(build_json_array user_array)
	echo $user_json_array
	
	# themes-config
	local user_config="themes-config"
	remove_plugin_package "${user_config}" "${OPENWRT_PLUGIN_FILE}" "${user_json_array}"
}

#********************************************************************************#
# 下载用户主题
download_user_themes()
{
	if [ ${USER_STATUS_ARRAY["autocompile"]} -eq 0 ]; then
		if ! input_prompt_confirm "是否需要下载用户主题?"; then
			return 0
		fi
	fi
	
	# 设置插件移除
	set_themes_remove $1 $2
	
	# 下载 argon 主题
	if ! download_themes_argon $1 $2; then
		return 1
	fi
	
	return 0
}

# 设置主题配置
set_themes_config()
{
	# 设置默认主题
	set_default_themes $1
}

# 设置自定义主题
set_user_themes()
{
	local plugin_path=$1
	
	# 下载用户主题
	if ! download_user_themes ${plugin_path} $2; then
		return 1
	fi
	
	# 设置主题配置
	set_themes_config $2
	
	return 0
}