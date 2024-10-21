#!/bin/bash

#********************************************************************************#
# 下载other package
download_other_package()
{
	local source_path=$1
	local plugins_path=$2
	
	print_log "INFO" "custom config" "获取otherpackage仓库代码..."
		
	local user_array=("${plugins_path}")
	remove_plugin_package "other_config" "${source_path}/package" "${OPENWRT_PLUGIN_FILE}" user_array
	
	user_array=()
	remove_plugin_package "other_config" "${source_path}/feeds" "${OPENWRT_PLUGIN_FILE}" user_array

	local url="https://github.com/lysgwl/openwrt-package.git/otherpackage?ref=master"	
	if ! get_remote_spec_contents "$url" "other" ${plugins_path} ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取otherpackage仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

# 下载golang
download_golang()
{
	local source_path=$1
	
	rm -rf ${source_path}/feeds/packages/lang/golang
	print_log "INFO" "custom config" "获取golang仓库代码..."
	
	local url="https://github.com/sbwml/packages_lang_golang.git?ref=22.x"
	if ! clone_repo_contents "$url" "${source_path}/feeds/packages/lang/golang" ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取golang仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

# 下载shidahuilang package
download_shidahuilang_package()
{
	local plugins_path=$1
	print_log "INFO" "custom config" "获取shidahuilang仓库代码..."
		
	local url="https://github.com/lysgwl/openwrt-package.git/shidahuilang?ref=master"
	if ! get_remote_spec_contents "$url" ${plugins_path} ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取shidahuilang仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

# 下载kiddin9 package
download_kiddin9_package()
{
	local plugins_path=$1
	print_log "INFO" "custom config" "获取kiddin9仓库代码..."
		
	local url="https://github.com/lysgwl/openwrt-package.git/kiddin9/master?ref=master"
	if ! get_remote_spec_contents "$url" ${plugins_path} ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取kiddin9仓库代码失败, 请检查!"
		return 1
	fi
		
	return 0		
}

# 下载siropboy package
download_siropboy_package()
{
	local plugins_path=$1
	print_log "INFO" "custom config" "获取sirpdboy-package仓库代码..."
		
	local url="https://github.com/sirpdboy/sirpdboy-package.git?ref=main"
	if ! clone_repo_contents "$url" "${plugins_path}" ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取sirpdboy-package仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

#********************************************************************************#
# 设置light插件
set_light_plugin()
{
	local source_path=$1
	
	# 删除luci-light插件
	{
		local file="${source_path}/feeds/luci/collections/luci-light"
		print_log "INFO" "custom config" "[删除插件luci-light]"
		
		if [ -d ${file} ]; then	
			rm -rf ${file}
		fi
	}
	
	# 取消luci-ssl对luci-light依赖
	{
		local file="${source_path}/feeds/luci/collections/luci-ssl/Makefile"
		print_log "INFO" "custom config" "[修改插件luci-ssl]"
		
		if [ -e ${file} ] && grep -q "+luci-light" ${file}; then	
			#sed -i 's/\s*+luci-light\s*//g' ${file}
			#sed -i 's/\s\+luci-light\s\+//g' ${file}
			sed -i 's/[[:space:]]*+luci-light[[:space:]]*//g' ${file}
		fi
	}
	
	# 取消luci-ssl-openssl对luci-light依赖
	{
		local file="${source_path}/feeds/luci/collections/luci-ssl-openssl/Makefile"
		print_log "INFO" "custom config" "[修改插件luci-ssl-openssl]"
		
		if [ -e ${file} ] && grep -q "+luci-light" ${file}; then	
			#sed -i 's/\s*+luci-light\s*//g' ${file}
			sed -i 's/[[:space:]]*+luci-light[[:space:]]*//g' ${file}
		fi
	}
}

# 设置uhttpd插件依赖
set_uhttpd_plugin()
{
	local source_path=$1
	
	if [ "${USER_CONFIG_ARRAY["nginxcfg"]}" != "1" ]; then
		return
	fi
	
	{
		local file="${source_path}/feeds/luci/collections/luci/Makefile"
		print_log "INFO" "custom config" "[修改uhttpd编译]"
		
		if [ -e ${file} ]; then
			# 取消uhttpd依赖
			if grep -q "+uhttpd" ${file}; then
				#sed -i 's/\+uhttpd//g; s/^\s*//; s/\s*$//' ${file}
				sed -i 's/\+\(uhttpd\)[[:space:]]\+//g' ${file}
			fi
			
			# 取消uhttpd-mod-ubus依赖
			if grep -q "+uhttpd" ${file}; then
				#sed -i 's/[[:space:]]*+uhttpd-mod-ubus[[:space:]]*//g' ${file}
				sed -i 's/\+\(uhttpd-mod-ubus\)[[:space:]]\+//g' ${file}
			fi
		fi
	}
}

# 设置bootstrap插件
set_bootstrap_plugin()
{
	local source_path=$1
	
	# 取消luci-nginx对luci-theme-bootstrap依赖
	{
		local file="${source_path}/feeds/luci/collections/luci-nginx/Makefile"
		print_log "INFO" "custom config" "[修改插件luci-nginx]"
		
		if [ -e ${file} ] && grep -q "+luci-theme-bootstrap" ${file}; then	
			#sed -i 's/\s*+luci-theme-bootstrap//g' ${file}
			sed -i 's/[[:space:]]*+luci-theme-bootstrap//g' ${file}
		fi	
	}
	
	# 取消luci-ssl-nginx对luci-theme-bootstrap依赖
	{
		local file="${source_path}/feeds/luci/collections/luci-ssl-nginx/Makefile"
		print_log "INFO" "custom config" "[修改插件luci-ssl-nginx]"
		
		if [ -e ${file} ]; then	
			if grep -q "+luci-theme-bootstrap" ${file}; then
				#sed -i 's/\s*+luci-theme-bootstrap//g' ${file}
				sed -i 's/[[:space:]]*+luci-theme-bootstrap//g' ${file}
			fi
		fi	
	}
}

# 设置nginx插件
set_nginx_plugin()
{
	local source_path=$1
	
	if [ "${USER_CONFIG_ARRAY["nginxcfg"]}" != "1" ]; then
		return
	fi
	
	# 修改nginx配置文件
	{
		local nginx_cfg="${source_path}/feeds/packages/net/nginx-util/files/nginx.config"
		print_log "INFO" "custom config" "[设置nginx配置文件]"
		
		if [ -f ${nginx_cfg} ]; then
			if grep -q "302 https://\$host\$request_uri" $nginx_cfg; then
				if ! grep -q "^#.*302 https://\$host\$request_uri" $nginx_cfg; then
					sed -i "/.*302 https:\/\/\$host\$request_uri/s/^/#/g" $nginx_cfg
				fi
			fi
			
			if ! grep -A 1 '302 https://$host$request_uri' $nginx_cfg | grep -q 'restrict_locally'; then
				sed -i "/302 https:\/\/\$host\$request_uri/ a\ \tlist include 'restrict_locally'\n\tlist include 'conf.d/*.locations'" $nginx_cfg
			fi
		fi
	}
}

# 设置插件依赖
set_plugin_depends()
{
	local source_type=$1
	local source_path=$2
	
	{
		case ${source_type} in
		${SOURCE_TYPE[openwrt]} | ${SOURCE_TYPE[immortalwrt]})
			# 设置light插件
			set_light_plugin ${source_path}
			;;
		${SOURCE_TYPE[coolsnowwolf]})
			# 设置uhttpd插件依赖
			set_uhttpd_plugin ${source_path}
			;;
		*)
			;;	
		esac
		
		# 设置bootstrap插件
		set_bootstrap_plugin ${source_path}
	}
}

# 设置插件UI 
set_plugin_webui()
{
	local source_type=$1
	local source_path=$2
	
	# upnp插件
	{
		case ${source_type} in
		${SOURCE_TYPE[openwrt]} | ${SOURCE_TYPE[immortalwrt]})
			file="${source_path}/feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json"
			if [ -e ${file} ]; then
				sed -i 's/services/network/g' ${file}
			fi
			;;
		*)
			;;	
		esac
	}
}

#********************************************************************************#
# 下载插件
download_user_plugin()
{
	local source_path=$1
	local plugins_path=$2
	
	if [ ${USER_STATUS_ARRAY["autocompile"]} -eq 0 ]; then
		if ! input_prompt_confirm "是否需要下载用户插件?"; then
			return 0
		fi
	fi
	
	# other package
	if ! download_other_package ${source_path} ${plugins_path}; then
		return 1
	fi

	# golang
	if ! download_golang ${source_path}; then
		return 1
	fi
	
	return 0
}

# 设置插件配置
set_plugin_config()
{
	local source_type=$1
	local source_path=$2
	
	# 设置nginx插件
	set_nginx_plugin ${source_path}
	
	# 设置插件依赖
	set_plugin_depends ${source_type} ${source_path}
	
	# 设置插件UI
	set_plugin_webui ${source_type} ${source_path}
}

# 设置自定义插件
set_user_plugins()
{
	local source_type=$1
	local source_path=$2
	local plugins_path=$3
	
	# 下载插件
	if ! download_user_plugin ${source_path} ${plugins_path}; then
		return 1
	fi
	
	# 设置插件配置
	set_plugin_config ${source_type} ${source_path}
	
	return 0
}