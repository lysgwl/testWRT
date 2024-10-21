#!/bin/bash

# 缺省duty
default_duty=50000
default_threshold=3

pwm_path="/sys/class/pwm/pwmchip0/pwm0"
cpu_temp_path="/sys/class/thermal/thermal_zone0/temp"

# 不同温度对应不同占空比设置
declare -a CpuTemps=(75000 63000 58000 52000 49000)			# 数值越大温度越高，“55000”即55℃。
declare -a PwmDutyCycles=(25000 35000 45000 46990 48000)	# 数值越小速度越快，PWM 占空比。

# 检查和初始化PWM设备
init_pwm()
{
	# 检查是否支持PWM
	if [ ! -d ${pwm_path%/pwm0} ]; then
		echo -e "\033[1;41;37mFAILURE\033[0m: 硬件设备不支持PWM!"
		return 1
	fi
	
	# 导出pwm0
	if [ ! -d $pwm_path ]; then
		echo -n 0 > ${pwm_path%/pwm0}/export
		 
		 # 等待pwm0目录生成
		while [ ! -d $pwm_path ]; do
			sleep 1
		done
	fi
	
	# 停止pwm0
	if [ "$(cat $pwm_path/enable)" -eq 1 ]; then
		echo -n 0 > $pwm_path/enable
	fi
	
	# 设置周期为50微秒（50000纳秒）
	echo -n 50000 > $pwm_path/period
	echo -n 1 > $pwm_path/enable
	
	# 风扇最大转速
	echo -n ${default_duty} > $pwm_path/duty_cycle
	return 0
}

# 执行循环
exec_loop()
{
	local count=0
	local current_index=-1
	local no_match_count=0
	
	while true; do
		# 读取CPU温度
		local temp=$(cat $cpu_temp_path)
		
		# 获取当前的占空比
		local cur_duty_cycle=$(cat $pwm_path/duty_cycle)
		
		# 设置当前的占空比值
		local duty_cycle=$default_duty
		
		# 更新占空比状态
		local update_cycle=false
		
		# 根据CPU温度获取占空比
		for i in "${!CpuTemps[@]}"; do
			echo "$i, temp=$temp, cpu=${CpuTemps[$i]}, cycle=$cur_duty_cycle, index=$current_index"
			
			if [[ "$temp" =~ ^[0-9]+$ ]] && [ "$temp" -gt "${CpuTemps[$i]}" ]; then
				if [ "$current_index" -eq "$i" ]; then
					((count++))
				else
					count=1
					current_index=$i
				fi
				
				echo "$i, temp($temp)>cpu(${CpuTemps[$i]}), count=$count, duty=${PwmDutyCycles[$i]}, cycle=$cur_duty_cycle"
				
				if [ $count -ge $default_threshold ]; then
					duty_cycle=${PwmDutyCycles[$i]}
					update_cycle=true
				fi
				
				no_match_count=0;
				break
			else
				if [ "$current_index" -eq "$i" ]; then
					current_index=-1
					count=0
				fi
			fi
		done
		
		# 如果没有匹配的温度区间，重置计数器和索引
		if [ "$current_index" -eq -1 ]; then
			echo "no_match=$no_match_count, temp=$temp, duty=$duty_cycle, cycle=$cur_duty_cycle"
			
			if [ $no_match_count -lt $default_threshold ]; then
				((no_match_count++))
				count=0
			else
				no_match_count=0
				update_cycle=true
			fi
		fi
		
		# 更新占空比
		if [[ $update_cycle = true ]]; then
			echo "index=$current_index, temp=$temp, duty=$duty_cycle, count=$count"
			
			if [ "$cur_duty_cycle" -ne "$duty_cycle" ]; then
				echo -n $duty_cycle > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
			fi
			
			count=0
			current_index=-1
		fi
		
		sleep 3s;
	done
}

if ! init_pwm; then
	exit 1
fi

exec_loop