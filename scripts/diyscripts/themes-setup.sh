#!/bin/bash

#********************************************************************************#
# 下载 argon主题
download_themes_argon()
{
	local source_type=$1
	local source_path=$2
	
	local plugins_path=$3
	local url=""
	
	# luci-theme-argon
	{
		find ${source_path} -name luci-theme-argon | xargs rm -rf;
		print_log "INFO" "custom config" "获取luci-theme-argon仓库代码..."
		
		if [ ${source_type} -eq ${SOURCE_TYPE[openwrt]} ] || [ ${source_type} -eq ${SOURCE_TYPE[immortalwrt]} ]; then
			url="https://github.com/jerrykuku/luci-theme-argon.git?ref=master"
		elif [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
			url="https://github.com/jerrykuku/luci-theme-argon.git?ref=18.06"
		fi
		
		if ! clone_repo_contents $url "${plugins_path}/luci-theme-argon" ${NETWORK_PROXY_CMD}; then
			print_log "ERROR" "custom config" "获取luci-theme-argons仓库代码失败, 请检查!"
			return 1
		fi
	}
	
	# luci-theme-argon-config
	{
		find ${source_path} -name luci-theme-argon-config | xargs rm -rf;
		print_log "INFO" "custom config" "获取luci-theme-argon-config仓库代码..."
		
		if [ ${source_type} -eq ${SOURCE_TYPE[openwrt]} ] || [ ${source_type} -eq ${SOURCE_TYPE[immortalwrt]} ]; then
			url="https://github.com/jerrykuku/luci-app-argon-config.git?ref=master"
		elif [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
			url="https://github.com/jerrykuku/luci-app-argon-config.git?ref=18.06"
		fi
		
		if ! clone_repo_contents $url "${plugins_path}/luci-theme-argon-config" ${NETWORK_PROXY_CMD}; then
			print_log "ERROR" "custom config" "获取luci-theme-argon-config仓库代码失败, 请检查!"
			return 1
		fi
	}
	
	return 0
}

# 下载 edge主题
download_themes_edge()
{
	local source_path=$1
	local plugins_path=$2
	
	local url=""
	
	# luci-theme-edge
	{
		find ${source_path} -name luci-theme-edge | xargs rm -rf;
		print_log "INFO" "custom config" "获取luci-theme-edge仓库代码..."
		
		url="https://github.com/kiddin9/luci-theme-edge.git?ref=18.06"
		if ! clone_repo_contents $url "${plugins_path}/luci-theme-edge" ${NETWORK_PROXY_CMD}; then
			print_log "ERROR" "custom config" "获取luci-theme-edge仓库代码失败, 请检查!"
			return 1
		fi
	}
	
	return 0
}

#********************************************************************************#
# 设置默认主题
set_default_themes()
{
	local source_type=$1
	local source_path=$2
	
	{
		local file="${source_path}/feeds/luci/collections/luci/Makefile"
		print_log "INFO" "custom config" "[修改默认主题]"
		
		if [ -e ${file} ]; then
			if [ ${source_type} -eq ${SOURCE_TYPE[openwrt]} ] || [ ${source_type} -eq ${SOURCE_TYPE[immortalwrt]} ]; then
				sed -i 's/luci-light/luci-theme-argon/g' ${file}
			elif [ ${source_type} -eq ${SOURCE_TYPE[coolsnowwolf]} ]; then
				sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' ${file}
			fi
		fi
	}
}

#********************************************************************************#
# 下载用户主题
download_user_themes()
{
	local source_type=$1
	local source_path=$2
	
	local plugins_path=$3
	
	if [ ${USER_STATUS_ARRAY["autocompile"]} -eq 0 ]; then
		if ! input_prompt_confirm "是否需要下载用户主题?"; then
			return 0
		fi
	fi
	
	# 下载 argon 主题
	if ! download_themes_argon ${source_type} ${source_path} ${plugins_path}; then
		return 1
	fi
	
	return 0
}

# 设置主题配置
set_themes_config()
{
	local source_type=$1
	local source_path=$2
	
	# 设置默认主题
	set_default_themes ${source_type} ${source_path}
}

# 设置自定义主题
set_user_themes()
{
	local source_type=$1
	local source_path=$2
	
	local plugins_path=$3
	
	# 下载用户主题
	if ! download_user_themes ${source_type} ${source_path} ${plugins_path}; then
		return 1
	fi
	
	# 设置主题配置
	set_themes_config ${source_type} ${source_path}
	
	return 0
}