#!/bin/bash

#********************************************************************************#
# 设置主机名称
set_host_name()
{
	local -n source_array_ref=$1
	
	local source_type=${source_array_ref["Type"]}
	local source_path=${source_array_ref["Path"]}
	
	print_log "INFO" "custom config" "[设置主机名称]"
	
	if [ ${source_type} -eq ${SOURCE_TYPE[openwrt]} ] || [ ${source_type} -eq ${SOURCE_TYPE[immortalwrt]} ]; then
		local file="${source_path}/package/base-files/files/bin/config_generate"
		if [ -e ${file} ]; then
			local host_name=$(sed -n "s/.*system\.@system\[-1\]\.hostname='\([^']*\)'/\1/p" ${file})
			local default_name="${USER_CONFIG_ARRAY["defaultname"]}"
			
			if [ -z "${host_name}" ]; then
				sed -i '/.*add system system$/a\ \t\tset system.@system[-1].hostname='\''${default_name}'\''' ${file}
			else
				if [ "${host_name}" != "${default_name}" ]; then
					sed -i "s/\(set system.@system\[-1\].hostname=\).*/\1'${default_name}'/" ${file}
				fi
			fi
		fi
	elif [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
		local file="${source_path}/package/lean/default-settings/files/zzz-default-settings"
		if [ -e ${file} ]; then
			local host_name=$(sed -n 's/.*hostname=\(.*\)/\1/p' ${file})
			local default_name="${USER_CONFIG_ARRAY["defaultname"]}"
			
			if [ -z ${host_name} ]; then
				sed -i "/uci commit system/i\uci set system.@system[0].hostname=${default_name}" ${file}
			else
				if [ "${host_name}" != "${default_name}" ]; then
					sed -i "s/\(.*hostname=\).*$/\1${default_name}/" ${file}
				fi
			fi
		fi
	fi
}

# 设置用户密码
set_user_passwd()
{
	local -n source_array_ref=$1
	local source_path=${source_array_ref["Path"]}
	
	print_log "INFO" "custom config" "[设置用户缺省密码]"
	
	local file="${source_path}/package/base-files/files/etc/shadow"
	if [ -e ${file} ]; then
		local default_passwd="${USER_CONFIG_ARRAY["defaultpasswd"]}"
		if [ -z "${default_passwd}" ]; then
			default_passwd="password"
		fi
		
		#SALT=$(openssl rand -hex 8)
		#if [ $? -ne 0 ]; then
		#	return
		#fi
		
		#HASH=$(echo -n "${default_passwd}${SALT}" | openssl dgst -md5 -binary | openssl enc -base64)
		#if [ $? -ne 0 ]; then
		#	return
		#fi
		
		local user_passwd=$(openssl passwd -1 ${default_passwd})
		if [ -z "${user_passwd}" ]; then
			print_log "ERROR" "custom config" "生成密文数据失败, 请检查!"
			return
		fi

		#echo "$user_passwd"
		#sed -i "/^root:/s/:\([^:]*\):[^:]*/:${user_passwd}:0/" ${file}
		sed -i "/^root:/s#:\([^:]*\):[^:]*#:${user_passwd}:0#"  ${file}
	fi
}

# 设置默认中文
set_default_chinese()
{
	local -n source_array_ref=$1
	local source_path=${source_array_ref["Path"]}
	
	print_log "INFO" "custom config" "[设置缺省中文]"
	
	{
		local file="${source_path}/feeds/luci/modules/luci-base/root/etc/config/luci"
		if [ -e ${file} ]; then
			sed -i "/option lang/s/auto/zh_cn/" ${file}
		fi
	}
	
	{
		local file="${source_path}/package/base-files/files/etc/uci-defaults/99-defaults-settings"
		cat > ${file} <<-EOF
			uci set luci.main.lang=zh_cn
			uci commit luci
		EOF
	}	
}

# 设置时区
set_system_timezone()
{
	local -n source_array_ref=$1
	local source_path=${source_array_ref["Path"]}
	
	print_log "INFO" "custom config" "[设置系统时区]"
	
	local file="${source_path}/package/base-files/files/bin/config_generate"
	if [ -e ${file} ]; then
		local time_zone=$(sed -n "s/.*system\.@system\[-1\]\.timezone='\([^']*\)'/\1/p" ${file})
		local default_timezone="${USER_CONFIG_ARRAY["timezone"]}"
		
		if [ -n "${time_zone}" ]; then
			if [ "${time_zone}" != "${default_timezone}" ]; then
				sed -i "s/\(set system.@system\[-1\].timezone=\).*/\1'${default_timezone}'/" ${file}
			fi
		fi
		
		local zone_name=$(sed -n "s/.*system\.@system\[-1\]\.zonename='\([^']*\)'/\1/p" ${file})
		local default_zonename="${USER_CONFIG_ARRAY["zonename"]}"
		
		if [ -z "${zone_name}" ]; then
			#sed -i "/.*system.@system\[-1\].timezone.*$/a\ \t\tset system.@system[-1].zonename='\$defaultzonename'" ${file}
			sed -i "/.*system.@system\[-1\].timezone.*\$/a\ \t\tset system.@system[-1].zonename='${default_zonename}'" ${file}
		else
			if [ "${zone_name}" != "${default_zonename}" ]; then
				sed -i "s|\(set system.@system\[-1\].zonename=\).*|\1'${default_zonename}'|" ${file}
			fi
		fi
	fi
}

# 设置默认编译
set_compile_option()
{
	local -n source_array_ref=$1
	
	local source_type=${source_array_ref["Type"]}
	local source_path=${source_array_ref["Path"]}
	
	{ # 编译O2优化
		
		print_log "INFO" "custom config" "[编译O2优化]"
		
		local file="${source_path}/include/target.mk"
		if [ -e ${file} ]; then
			sed -i 's/Os/O2/g' ${file}
		fi
	}
	
	{ # 设置编译信息
		
		if [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
			print_log "INFO" "custom config" "[设置编译信息]"
			
			local file="${source_path}/package/lean/default-settings/files/zzz-default-settings"
			if [ -e ${file} ]; then
				local build_info="C95wl build $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt"
				sed -i "s/\(echo \"DISTRIB_DESCRIPTION='\)[^\']*\( '\"\s>> \/etc\/openwrt_release\)/\1${build_info}\2/g" ${file}
			fi
		fi
	}
}

# 设置PWM FAN
set_pwm_fan()
{
	local -n source_array_ref=$1
	
	local source_type=${source_array_ref["Type"]}
	local source_path=${source_array_ref["Path"]}
	
	if [ "${USER_CONFIG_ARRAY["userdevice"]}" != "r2s" ] && [ "${USER_CONFIG_ARRAY["userdevice"]}" != "r5s" ]; then
		return
	fi
	
	print_log "INFO" "custom config" "[设置PWM风扇]"
	
	{
		# rk3328-pwmfan
		local path="${source_path}/target/linux/rockchip/armv8/base-files/etc/init.d/"
		if [ ! -f "${path}/rk3328-pwmfan" ]; then
			if [ ! -f "${OPENWRT_CONFIG_PATH}/pwm-fan/rk3328-pwmfan" ]; then
				local url="https://github.com/friendlyarm/friendlywrt/raw/master-v19.07.1/target/linux/rockchip-rk3328/base-files/etc/init.d/fa-rk3328-pwmfan"
				${NETWORK_PROXY_CMD} wget -P "${path}" -O "${path}/rk3328-pwmfan" "${url}"
			else
				cp -rf "${OPENWRT_CONFIG_PATH}/pwm-fan/rk3328-pwmfan"  "${path}"
			fi
		fi
		
		# rk3328-pwm-fan.sh
		local path="${source_path}/target/linux/rockchip/armv8/base-files/usr/bin/"
		if [ ! -f "${path}/rk3328-pwm-fan.sh" ]; then
			# 创建目录
			mkdir -p ${path}
			
			if [ ! -f "${OPENWRT_CONFIG_PATH}/pwm-fan/rk3328-pwm-fan.sh" ]; then
				local url="https://github.com/friendlyarm/friendlywrt/raw/master-v19.07.1/target/linux/rockchip-rk3328/base-files/usr/bin/start-rk3328-pwm-fan.sh"
				${NETWORK_PROXY_CMD} wget -P "${path}" -O "${path}/rk3328-pwm-fan.sh" "${url}"
			else
				cp -rf "${OPENWRT_CONFIG_PATH}/pwm-fan/rk3328-pwm-fan.sh"  "${path}"
			fi
		fi
	}
	
	{
		local file="${source_path}/package/base-files/files/etc/uci-defaults/99-defaults-settings"
		cat >> ${file} <<-EOF
		
		if [ -f "/etc/init.d/rk3328-pwmfan" ]; then
		    chmod 777 /etc/init.d/rk3328-pwmfan
		fi
		
		if [ -f "/usr/bin/rk3328-pwm-fan.sh" ]; then
		    chmod 777 /usr/bin/rk3328-pwm-fan.sh
		fi
		
		EOF
	}
}

#  设置系统功能
set_system_func()
{
	local -n source_array_ref=$1
	
	local source_type=${source_array_ref["Type"]}
	local source_path=${source_array_ref["Path"]}
	
	# irqbalance 
	{
		print_log "INFO" "custom config" "[设置irqbalance]"
		
		local file="${source_path}/feeds/packages/utils/irqbalance/files/irqbalance.config"
		if [ -f "${file}" ]; then
			sed -i "s/enabled '0'/enabled '1'/g" ${file}
		fi
	}
	
	# ttyd
	{
		print_log "INFO" "custom config" "[设置ttyd]"
		
		local file="${source_path}/feeds/packages/utils/ttyd/files/ttyd.config"
		if [ -f "${file}" ]; then
			sed -i "s?/bin/login?/usr/libexec/login.sh?g" ${file}
		fi
	}
}

#********************************************************************************#
# 设置系统配置
set_system_config()
{
	# 设置主机名称
	set_host_name $1
	
	# 设置用户密码
	set_user_passwd $1
	
	# 设置默认中文
	set_default_chinese $1
	
	# 设置时区
	set_system_timezone $1
	
	# 设置默认编译
	set_compile_option $1
}

# 设置系统脚本
set_system_script()
{
	# 设置PWM FAN
	set_pwm_fan $1
	
	#  设置系统功能
	set_system_func $1
}

# 设置自定义配置
set_user_config()
{
	# 设置系统配置
	set_system_config $1
	
	# 设置系统脚本
	set_system_script $1
}