#!/bin/sh

#********************************************************************************#
# 执行功能
exeCmdShell()
{
	# 执行命令
	local cmd=$1
	local -n array=$2
	
	local ret=0
	case ${cmd} in
	${CMD_TYPE[autoCompileOpenwrt]})
		# 自动编译openwrt
		auto_compile_openwrt $2; ret=$?
		;;
	${CMD_TYPE[cloneOpenWrtSrc]})
		# 获取OpenWrt源码
		clone_openwrt_source $2; ret=$?
		;;
	${CMD_TYPE[setOpenWrtFeeds]})
		# 设置OpenWrt feeds源 
		set_openwrt_feeds $2; ret=$?
		;;
	${CMD_TYPE[updateOpenWrtFeeds]})
		# 更新OpenWrt feeds源
		update_openwrt_feeds $2; ret=$?
		;;
	${CMD_TYPE[setCustomConfig]})
		# 设置自定义配置
		set_custom_config $2; ret=$?
		;;
	${CMD_TYPE[setMenuOptions]})
		# 设置软件包目录
		set_menu_options $2; ret=$?
		;;
	${CMD_TYPE[downloadOpenWrtPackage]})
		# 下载openwrt包
		download_openwrt_package $2; ret=$?
		;;
	${CMD_TYPE[compileOpenWrtFirmware]})
		# 编译OpenWrt固件
		compile_openwrt_firmware $2; ret=$?
		;;
	${CMD_TYPE[getOpenWrtFirmware]})
		# 获取OpenWrt固件
		get_openwrt_firmware $2; ret=$?
		;;
	*)
		ret=1; print_log "TRACE" "" "输入的命令参数有误, 请检查!"
		;;
	esac
	
	# 关闭自动编译状态
	USER_STATUS_ARRAY["autocompile"]=0
	return $ret
}

# 设置命令目录
setCmdMenu()
{
	local cmd_array=("${CMD_ARRAY[@]}")
	if [ ${#cmd_array[@]} -eq 0 ]; then
		print_log "ERROR" "command menu" "命令信息配置有误, 请检查!"
		return 1
	fi
	
	clear
	while [ 1 ]; do
		local -n cmd_source_array="$1"
		
		# 显示命令目录
		show_cmd_menu cmd_array[@] cmd_source_array
		
		# 获取用户输入
		local index=`input_user_index`
		
		# 判断输入值是否有效
		if [ $index -lt 0 ] || [ $index -gt ${#cmd_array[@]} ]; then
			clear; print_log "WARNING" "cmd menu" "请输入正确的命令序号!"
			continue
		fi
		
		# 退出选择列表
		[ $index -eq 0 ] && { ret=0; break; }
		
		# 执行命令功能
		exeCmdShell ${index} cmd_source_array
		
		if [ $? -ne 0 ]; then
			pause "press any key to continue..."
		fi
		
		clear
	done
}

# 设置源码目录 
setSourceMenu()
{
	clear
	while [ 1 ]; do
		local source_name_array=("${@}")
		
		# 名称进行排序
		local sorted_source_name_array=($(for i in "${source_name_array[@]}"; do echo "$i"; done | sort -r))
		
		# 显示源码目录
		show_source_menu ${sorted_source_name_array[@]}
		
		# 获取用户输入
		local index=`input_user_index`
		
		# 判断输入值是否有效
		if [ $index -lt 0 ] || [ $index -gt ${#sorted_source_name_array[@]} ]; then
			clear; print_log "WARNING" "source menu" "请输入正确的命令序号!"
			continue
		fi
		
		# 退出选择列表
		[ $index -eq 0 ] && { break; }
		
		# 获取源码名称
		local source_name=${sorted_source_name_array[$index-1]}
		
		# 获取源码类型
		local source_type=${SOURCE_TYPE[${source_name}]}
		
		declare -A source_array
		get_struct_field SOURCE_CONFIG_ARRAY ${source_type} source_array
		
		if [ ${#source_array[@]} -eq 0 ]; then
			clear; print_log "WARNING" "source menu" "获取源码配置有误, 请检查!"
			continue
		fi
		
		# 设置命令目录
		setCmdMenu source_array
		
		# 执行成功清屏
		if [ $? -eq 0 ]; then
			clear
		fi
	done
}

# 运行linux环境
runLinuxEnv()
{
	print_log "TRACE" "run linux" "正在运行linux环境，请等待..."
	
	local source_name_array=()
	enum_struct_field SOURCE_CONFIG_ARRAY "Name" source_name_array

	if [ ${#source_name_array[@]} -eq 0 ]; then
		print_log "ERROR" "run linux" "获取配置信息失败, 请检查!"
		return
	fi
	
	if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[local_compile]} ]; then
		# 设置源码目录 
		setSourceMenu ${source_name_array[@]}
	else
		for key in "${!source_name_array[@]}"; do
			# 获取源码名称
			local source_name="${source_name_array[$key]}"
			
			# 获取源码类型
			local source_type=${SOURCE_TYPE[${source_name}]}

			declare -A source_array
			get_struct_field SOURCE_CONFIG_ARRAY ${source_type} source_array
			if [ ${#source_array[@]} -eq 0 ]; then
				continue
			fi

			if [ ${source_array["Action"]} -eq 1 ]; then
				# 自动编译openwrt
				auto_compile_openwrt source_array
				break
			fi
		done
	fi
}

# 设置linux环境
setLinuxEnv()
{
	print_log "TRACE" "setting linux" "正在设置linux环境，请等待..."

	# 创建工作目录
	if [ ! -d $OPENWRT_WORK_PATH ]; then
		sudo mkdir -p $OPENWRT_WORK_PATH
	fi
	
	if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[local_compile]} ]; then
		if [ ! -d $OPENWRT_CONFIG_PATH ]; then
			sudo mkdir -p $OPENWRT_CONFIG_PATH
		fi
		
		if [ ! -d $OPENWRT_OUTPUT_PATH ]; then
			sudo mkdir -p $OPENWRT_OUTPUT_PATH
		fi

		if dpkg -s proxychains4 >/dev/null 2>&1; then
			NETWORK_PROXY_CMD="proxychains4 -q -f /etc/proxychains4.conf"
		fi
		
		set +e
	else
		# exit on error
		set -e
	fi
	
	# 为工作目录赋予权限
	sudo chown $USER:$GROUPS $OPENWRT_WORK_PATH
	
	print_log "TRACE" "setting linux" "完成linux环境的设置!"
}

# 更新linux环境
updateLinuxEnv()
{
	print_log "TRACE" "update linux" "正在更新linux环境，请等待..."
	
	if [ ${USER_CONFIG_ARRAY["mode"]} -eq ${COMPILE_MODE[remote_compile]} ]; then
		# 列出前100个比较大的包
		#dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -n 100
		
		print_log "INFO" "update linux" "正在删除大的软件包，请等待..."
		
		# ^ghc-8.*
		remove_packages '^ghc-8.*'

		# ^dotnet-.*
		remove_packages '^dotnet-.*'

		# ^llvm-.*
		remove_packages '^llvm-.*'
		
		# php.*
		remove_packages 'php.*'
		
		# temurin-.*
		remove_packages 'temurin-.*'
		
		# mono-.*
		remove_packages 'mono-.*'
		
		remove_packages_list=("azure-cli" "google-cloud-sdk" "hhvm" "google-chrome-stable" "firefox" "powershell" "microsoft-edge-stable")
		
		for package in "${packages_to_remove[@]}"; do
			echo "正在尝试删除包：$package"
			remove_packages "$package"
		done
		
		sudo rm -rf \
            /etc/apt/sources.list.d/* \
            /usr/share/dotnet \
            /usr/local/lib/android \
            /opt/ghc \
            /opt/hostedtoolcache/CodeQL
	fi
	
	sudo -E apt-get -qq update
	sudo -E apt-get -qq upgrade
	
	sudo -E apt-get -qq install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential bzip2 ccache clang cmake cpio curl device-tree-compiler fastjar file flex g++-multilib gawk gcc-multilib gettext git gperf haveged help2man intltool jq libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev libssl-dev libtool lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-distutils python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs unzip upx-ucl vim wget xmlto xxd zlib1g-dev
	
	sudo -E apt-get -qq autoremove --purge
	sudo -E apt-get -qq clean

	df -hT
	
	sudo timedatectl set-timezone "${USER_CONFIG_ARRAY["zonename"]}"
	print_log "TRACE" "update linux" "完成linux环境的更新!"
}

# 初始化linux环境
initLinuxEnv()
{
	print_log "TRACE" "init linux" "正在初始化linux环境，请等待..."

	if ! init_user_config "${OPENWRT_CONF_FILE}"; then
		exit 1
	fi
	
	# 判断插件列表文件
	if [ ! -f "${OPENWRT_PLUGIN_FILE}" ]; then
		touch "${OPENWRT_PLUGIN_FILE}"
	fi
	
	print_log "TRACE" "init linux" "完成linux环境的初始化!"
}

#********************************************************************************#
# 运行linux脚本
runAppLinux()
{
	# 初始化linux环境
	initLinuxEnv
	
	# 更新linux环境
	updateLinuxEnv
	
	# 设置linux环境
	setLinuxEnv
	
	# 运行linux环境
	runLinuxEnv
}