#!/bin/bash

#********************************************************************************#
# 下载other package
download_other_package()
{
	local plugin_path=$1
	
	print_log "INFO" "custom config" "获取otherpackage仓库代码..."
	
	local url="https://github.com/lysgwl/openwrt-package.git/otherpackage?ref=master"	
	if ! get_remote_spec_contents "$url" "other" ${plugin_path} ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取otherpackage仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

# 下载golang
download_golang()
{
	local -n source_array_ref=$1
	local source_path=${source_array_ref["Path"]}
	
	print_log "INFO" "custom config" "获取golang仓库代码..."
	
	local url="https://github.com/sbwml/packages_lang_golang.git?ref=23.x"
	if ! clone_repo_contents "$url" "${source_path}/feeds/packages/lang/golang" ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取golang仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

# 下载shidahuilang package
download_shidahuilang_package()
{
	local plugin_path=$1
	
	print_log "INFO" "custom config" "获取shidahuilang仓库代码..."
	
	local url="https://github.com/lysgwl/openwrt-package.git/shidahuilang?ref=master"
	if ! get_remote_spec_contents "$url" ${plugin_path} ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取shidahuilang仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

# 下载kiddin9 package
download_kiddin9_package()
{
	local plugin_path=$1
	
	print_log "INFO" "custom config" "获取kiddin9仓库代码..."
	
	local url="https://github.com/lysgwl/openwrt-package.git/kiddin9/master?ref=master"
	if ! get_remote_spec_contents "$url" ${plugin_path} ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取kiddin9仓库代码失败, 请检查!"
		return 1
	fi
		
	return 0		
}

# 下载siropboy package
download_siropboy_package()
{
	local plugin_path=$1
	
	print_log "INFO" "custom config" "获取sirpdboy-package仓库代码..."
		
	local url="https://github.com/sirpdboy/sirpdboy-package.git?ref=main"
	if ! clone_repo_contents "$url" "${plugin_path}" ${NETWORK_PROXY_CMD}; then
		print_log "ERROR" "custom config" "获取sirpdboy-package仓库代码失败, 请检查!"
		return 1
	fi
	
	return 0
}

#********************************************************************************#
# 设置light插件
set_light_depends()
{
	local source_path=$1
	
	# 删除luci-light插件
	print_log "INFO" "custom config" "[设置插件luci-light依赖]"
	
	local file="${source_path}/feeds/luci/collections/luci-light"
	if [ -d ${file} ]; then	
		rm -rf ${file}
	fi
	
	# 取消luci-ssl对luci-light依赖
	print_log "INFO" "custom config" "[设置插件luci-ssl依赖]"
	
	local file="${source_path}/feeds/luci/collections/luci-ssl/Makefile"
	remove_keyword_file "+luci-light" ${file}
	
	# 取消luci-ssl-openssl对luci-light依赖
	print_log "INFO" "custom config" "[设置插件luci-ssl-openssl依赖]"
	
	local file="${source_path}/feeds/luci/collections/luci-ssl-openssl/Makefile"
	remove_keyword_file "+luci-light" ${file}
}

# 设置uhttpd插件依赖
set_uhttpd_depends()
{
	local source_path=$1
	
	if [ "${USER_CONFIG_ARRAY["nginxcfg"]}" != "1" ]; then
		return
	fi
	
	print_log "INFO" "custom config" "[设置uhttpd编译依赖]"
	local file="${source_path}/feeds/luci/collections/luci/Makefile"
	
	# 取消uhttpd依赖
	remove_keyword_file "+uhttpd" ${file}
	
	# 取消uhttpd-mod-ubus依赖
	remove_keyword_file "+uhttpd-mod-ubus" ${file}
}

# 设置bootstrap插件
set_bootstrap_depends()
{
	local source_path=$1
	
	# 取消luci-nginx对luci-theme-bootstrap依赖
	print_log "INFO" "custom config" "[设置插件luci-nginx依赖]"
	
	local file="${source_path}/feeds/luci/collections/luci-nginx/Makefile"
	remove_keyword_file "+luci-theme-bootstrap" ${file}
	
	# 取消luci-ssl-nginx对luci-theme-bootstrap依赖
	print_log "INFO" "custom config" "[设置插件luci-ssl-nginx依赖]"
	
	local file="${source_path}/feeds/luci/collections/luci-ssl-nginx/Makefile"
	remove_keyword_file "+luci-theme-bootstrap" ${file}
}

# 设置docker插件
set_docker_depends()
{
	local source_path=$1
	
	# 取消luci-app-dockerman对docker-compose依赖
	print_log "INFO" "custom config" "[设置插件luci-app-dockerman依赖]"
	
	local file="${source_path}/feeds/luci/applications/luci-app-dockerman/Makefile"
	remove_keyword_file "+docker-compose" ${file}
}

# 设置nginx插件
set_nginx_plugin()
{
	local -n source_array_ref=$1
	local source_path=${source_array_ref["Path"]}
	
	if [ "${USER_CONFIG_ARRAY["nginxcfg"]}" != "1" ]; then
		return
	fi
	
	print_log "INFO" "custom config" "[设置nginx配置文件]"
	
	# 修改nginx配置文件
	local nginx_cfg="${source_path}/feeds/packages/net/nginx-util/files/nginx.config"
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

# 设置插件依赖
set_plugin_depends()
{
	local -n source_array_ref=$1
	
	local source_path=${source_array_ref["Path"]}
	
	# 设置uhttpd依赖
	set_uhttpd_depends ${source_path}
	
	# 设置light依赖
	set_light_depends ${source_path}
	
	# 设置bootstrap依赖
	set_bootstrap_depends ${source_path}
	
	# 设置docker依赖
	#set_docker_depends ${source_path}
}

# 设置插件UI 
set_plugin_webui()
{
	local -n source_array_ref=$1
	
	local source_type=${source_array_ref["Type"]}
	local source_path=${source_array_ref["Path"]}
}

# 设置插件移除
set_plugin_remove()
{
	local plugin_path=$1
	local -n source_array_ref=$2
	
	local source_path=${source_array_ref["Path"]}
	if [ -z "${source_path}" ] || [ ! -d "${source_path}" ]; then
		return
	fi
	
	local source_alias=${source_array_ref["Alias"]}
	if [ -z "${source_alias}" ]; then
		return
	fi
	
	local user_array=()
	local source_array=("${source_path}/package" "${source_path}/feeds")
	
	for value in "${source_array[@]}"; do
		# tr 命令来去除空格
		local last_field=$(echo "${value##*/}" | tr -d '[:space:]')
		
		# 排除数组
		local exclude_array=()
		if [ "$last_field" == "package" ]; then
			exclude_array=("${plugin_path}")
		elif [ "$last_field" == "feeds" ]; then
			exclude_array=()
		fi
		
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
	
	# common_config
	local user_config="common_config"
	remove_plugin_package "${user_config}" "${OPENWRT_PLUGIN_FILE}" "${user_json_array}"
	
	#
	user_config="${source_alias}_config"
	remove_plugin_package "${user_config}" "${OPENWRT_PLUGIN_FILE}" "${user_json_array}"
	
	# 删除golang源码目录
	rm -rf ${source_path}/feeds/packages/lang/golang
}

#********************************************************************************#
# 下载插件
download_user_plugin()
{
	if [ ${USER_STATUS_ARRAY["autocompile"]} -eq 0 ]; then
		if ! input_prompt_confirm "是否需要下载用户插件?"; then
			return 0
		fi
	fi
	
	# 设置插件移除
	set_plugin_remove $1 $2
	
	# other package
	if ! download_other_package $1; then
		return 1
	fi

	# golang
	if ! download_golang $2; then
		return 1
	fi
	
	return 0
}

# 设置插件配置
set_plugin_config()
{
	# 设置nginx插件
	set_nginx_plugin $1
	
	# 设置插件依赖
	set_plugin_depends $1
	
	# 设置插件UI
	set_plugin_webui $1
}

# 设置自定义插件
set_user_plugin()
{
	local plugin_path=$1
	
	# 下载插件
	if ! download_user_plugin ${plugin_path} $2; then
		return 1
	fi
	
	# 设置插件配置
	set_plugin_config $2
	
	return 0
}