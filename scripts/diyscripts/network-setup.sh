#!/bin/bash

#********************************************************************************#
# 设置网络地址
set_network_addr()
{
	local -n source_array_ref=$1
	source_path=${source_array_ref["Path"]}
	
	# 设置缺省IP地址
	{
		print_log "INFO" "custom config" "[设置Lan接口缺省IP地址]"
		
		local file="${source_path}/package/base-files/files/bin/config_generate"
		if [ -e ${file} ]; then
			local ip_addr=$(sed -n 's/.*lan) ipad=\${ipaddr:-"\([0-9.]\+\)"}.*/\1/p' ${file})
			local default_ip="${NETWORK_CONFIG_ARRAY["lanaddr"]}"
			
			if [ "${ip_addr}" != "${default_ip}" ]; then
				sed -i "s/lan) ipad=\${ipaddr:-\"$ip_addr\"}/lan) ipad=\${ipaddr:-\"${default_ip}\"}/" ${file}
			fi
		fi
	}
	
	# 配置网络接口
	{
		print_log "INFO" "custom config" "[设置网络接口地址]"
		
		local file="${source_path}/package/base-files/files/etc/uci-defaults/99-defaults-settings"
		# 配置lan接口
		{
			# lan地址
			local lan_ipaddr="${NETWORK_CONFIG_ARRAY["lanaddr"]}"
			if [ -z "${lan_ipaddr}" ]; then
				lan_ipaddr="192.168.2.1"
			fi
			
			# lan子网掩码
			local lan_netmask="${NETWORK_CONFIG_ARRAY["lannetmask"]}"
			if [ -z "${lan_netmask}" ]; then
				lan_netmask="255.255.255.0"
			fi
			
			# lan广播地址
			local lan_broadcast="${NETWORK_CONFIG_ARRAY["lanbroadcast"]}"
			if [ -z "${lan_broadcast}" ]; then
				lan_broadcast="192.168.2.255"
			fi
			
			# dhcp服务开关
			local lan_ignore_dhcp=0
			local lan_dhcp_start=""
			local lan_dhcp_number=""
			
			# dhcp起始地址
			if [ -z "${NETWORK_CONFIG_ARRAY["landhcpstart"]}" ]; then
				lan_dhcp_start="40"
			else
				lan_dhcp_start="${NETWORK_CONFIG_ARRAY["landhcpstart"]}"
			fi
			
			# dhcp限制数量
			if [ -z "${NETWORK_CONFIG_ARRAY["landhcpnumber"]}" ]; then
				lan_dhcp_number="60"
			else
				lan_dhcp_number="${NETWORK_CONFIG_ARRAY["landhcpnumber"]}"
			fi
			
			cat >> ${file} <<-EOF
			
				uci -q batch << EOI
				set network.lan.proto='static'
				set network.lan.ipaddr='${lan_ipaddr}'
				set network.lan.netmask='${lan_netmask}'
				set network.lan.broadcast='${lan_broadcast}'
				commit network

				uci set dhcp.lan.ignore='${lan_ignore_dhcp}'
				set dhcp.lan.start='${lan_dhcp_start}'
				set dhcp.lan.limit='${lan_dhcp_number}'
				set dhcp.lan.leasetime='12h'
				uci commit dhcp
				EOI
			EOF
		}
		
		# 配置wan接口
		{
			# wan地址
			local wan_ipaddr="${NETWORK_CONFIG_ARRAY["wanaddr"]}"
			if [ -z "${wan_ipaddr}" ]; then
				wan_ipaddr="192.168.1.1"
			fi
			
			# wan子网掩码
			local wan_netmask="${NETWORK_CONFIG_ARRAY["wannetmask"]}"
			if [ -z "${wan_netmask}" ]; then
				wan_netmask="255.255.255.0"
			fi
			
			# wan广播地址
			local wan_broadcast="${NETWORK_CONFIG_ARRAY["wanbroadcast"]}"
			if [ -z "${wan_broadcast}" ]; then
				wan_broadcast="192.168.2.255"
			fi
			
			# wan网关
			local wan_gateway="${NETWORK_CONFIG_ARRAY["wangateway"]}"
			if [ -z "${wan_gateway}" ]; then
				wan_gateway="192.168.1.1"
			fi
			
			# wan的dns
			local wan_dnsaddr="${NETWORK_CONFIG_ARRAY["wandnsaddr"]}"
			if [ -z "${wan_dnsaddr}" ]; then
				wan_dnsaddr="192.168.1.1"
			fi
			
			cat >> ${file} <<-EOF
			
				uci -q batch << EOI
				set network.wan.proto='static'
				set network.wan.ipaddr='${wan_ipaddr}'
				set network.wan.netmask='${wan_netmask}'
				set network.wan.broadcast='${wan_broadcast}'
				set network.wan.gateway='${wan_gateway}'
				set network.wan.dns='${wan_dnsaddr}'
				commit network
				EOI
			EOF
		}
	}
}

#********************************************************************************#
# 设置自定义网络
set_user_network()
{
	# 设置网络地址
	set_network_addr $1
}