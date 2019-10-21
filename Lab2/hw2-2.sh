#!/usr/local/bin/bash

CPU_INFO(){
	model=`sysctl -n hw.model`
	machine=`sysctl -n hw.machine_arch`
	core=`sysctl -n hw.ncpu`
	dialog --title "SIM" --msgbox "CPU INFO\nCPU Model: $model\nCPU Machine: $machine\nCPU Core: $core" 30 100
	MAIN_MENU
}

#0: b 1:B 2:KB 3:MB 4: GB 5: TB
CALCULATOR(){
	local number="$1"
	local base="$2"
	while true; do
		if [ `echo "$number" | awk '{if ($1<1024.0) print "1"; else print "0"}'` -eq 1 ]; then
			echo "$number" "$base"
			break
		else
			if [ $base -eq 0 ]; then
				base=$((base+1))
				number=`echo "$number" | awk '{printf "%.2f", $1/8.0}'`
			else
				base=$((base+1))
				number=`echo "$number" | awk '{printf "%.2f", $1/1024.0}'`
			fi
		fi
	done
}

MEMORY_INFO(){
	unit_array=(b B KB MB GB TB)
	while true; do
		msg="Memory Info and Usage\n"
		total_memory=`sysctl -n hw.realmem`
		page_size=`sysctl -n hw.pagesize`
		free_pages=`sysctl -n vm.stats.vm.v_free_count`
		cache_pages=`sysctl -n vm.stats.vm.v_cache_count`
		inactive_pages=`sysctl -n vm.stats.vm.v_inactive_count`
		avail_pages=$((free_pages+cache_pages+inactive_pages))
		avail_memory=$((page_size*avail_pages))
		used_memory=$((total_memory-avail_memory))
		percentage=`echo "$used_memory" "$total_memory" | awk '{printf "%d", ($1/$2)*100}'`

		read number base < <(CALCULATOR $total_memory 1)
		msg="${msg}Total: ${number} ${unit_array[${base}]}\n"
		read number base < <(CALCULATOR $used_memory 1)
		msg="${msg}Used: ${number} ${unit_array[${base}]}\n"
		read number base < <(CALCULATOR $avail_memory 1)
		msg="${msg}Free: ${number} ${unit_array[${base}]}\n"

		dialog --title "SIM" --mixedgauge "$msg" 30 100 "$percentage"
		read -n 1 -t 3
		if [ $? -eq 0 ]; then
			input=`printf '%d' "'$REPLY"`
			input=`echo -e "$input"`
			if [ $input -eq 0 ]; then
				break
			fi
		fi
	done
	MAIN_MENU
}

NETWORK_INFO(){
	ipv4=`ifconfig "$1" | grep inet | grep -v inet6 | awk '{print $2}'`
	netmask=`ifconfig "$1" | grep inet | grep -v inet6 | awk '{print $4}'`
	mac=`ifconfig "$1" | grep ether | awk '{print $2}'`
	dialog --title "SIM" --msgbox "Interface Name: $1\nIPv4: $ipv4\nNetmask: $netmask\nMac: $mac" 30 100
	NETWORK_INTERFACE
}

NETWORK_INTERFACE(){
	network_interface=`ifconfig -a | grep "^[a-z]" | awk -F ":" '{print $1}' | xargs echo`
	read -a network_interface_array <<< "$network_interface"
	command="dialog --title 'SIM' --stdout --menu 'Network Interfaces' 30 100 5"
	for i in "${network_interface_array[@]}"; do
		command="${command} ${i} '*'"
	done
	network_interface_index=`eval $command`
	if [ $? -eq 0 ]; then
		NETWORK_INFO "$network_interface_index"
	else
		MAIN_MENU
	fi
}

FILE_INFO(){
	unit_array=(b B KB MB GB TB)
	file_info=`file "$1" | awk -F ': ' '{print $2}'`
	file_size=`ls -ll "$1" | awk '{print $5}'`
	read number base < <(CALCULATOR $file_size 1)
	temp=`file "$1" | grep text`
	if [ "$?" -eq 1 ]; then
		dialog --title "SIM" --msgbox "<File Name>: $1\n<File Info>: $file_info\n<File Size>: $number ${unit_array[${base}]}" 30 100
	else
		dialog --title "SIM" --no-label "Edit" --yesno "<File Name>: $1\n<File Info>: $file_info\n<File Size>: $number ${unit_array[${base}]}" 30 100
		if [ "$?" -eq 1 ]; then
			$EDITOR "$1"
		fi
	fi
	FILE_BROWSER
}

FILE_BROWSER(){
	command="dialog --title 'SIM' --stdout --menu "`pwd`" 30 100 50"
	file_type=`ls -a -ll | grep '^[-d]' | awk '{if($1 ~ /^d/) {print "d"} else {print "f"}}' | xargs echo`
	read -a file_type_array <<< "$file_type"
	file_name=`ls -a -ll | grep '^[-d]' | awk '{print $9}' | xargs echo`
	read -a file_name_array <<< "$file_name"
	temp=`ls -a -ll | grep '^[-d]' | awk '{print $9}' | xargs echo`
	read -a temp_array <<< "$temp"
	file_mime=`printf "%s\n" "${temp_array[@]}" | xargs file --mime-type | awk '{print $2}' | xargs echo`
	read -a file_mime_array <<< "$file_mime"
	for ((i = 0; i < "${#file_type_array[@]}"; i++)); do
  		command="${command} '${file_name_array[$i]}' '${file_mime_array[$i]}'"
	done
	file_name_index=`eval $command`
	if [ "$file_name_index" == "." ]; then
		cd .
		FILE_BROWSER
	elif [ "$file_name_index" == ".." ]; then
		if [ `pwd` == "/home" ]; then
			cd /usr
		else
			cd ..
		fi
		FILE_BROWSER
	else
		for ((i = 0; i < "${#file_type_array[@]}"; i++)); do
			if [ "$file_name_index" == "${file_name_array[$i]}" ]; then
				if [ "d" == "${file_type_array[$i]}" ]; then
					cd "$file_name_index"
					FILE_BROWSER
				else
					FILE_INFO $file_name_index
				fi
			fi
		done
	fi
}

FILE_MENU(){
	FILE_BROWSER
	MAIN_MENU
}

CPU_USAGE(){
	while true; do
		msg="CPU Loading\n"
		cpu_core=`sysctl -n hw.ncpu`
		cpu_info=`top -P -d 2 -s 0.5 | grep '^CPU' | tail -n "$cpu_core" | awk '{print $2 " " $3+$5 " " $7+$9 " " $11+0}' | xargs echo`
		read -a cpu_info_array <<< "$cpu_info"
		cpu_loading=`echo "$cpu_core" | awk '{print $1*100.0}'`
		for ((i = 0; i < "$cpu_core"; i++)); do
			index0=$((i*4))
			index1=$((i*4+1))
			index2=$((i*4+2))
			index3=$((i*4+3))
			cpu_loading=`echo "$cpu_loading" "${cpu_info_array[$index3]}" | awk '{printf "%.2f", $1-$2}'`
			msg="${msg}CPU${cpu_info_array[$index0]} USER: ${cpu_info_array[$index1]}% SYST: ${cpu_info_array[$index2]}% IDLE: ${cpu_info_array[$index3]}%\n"
		done

		percentage=`echo "$cpu_loading" "$cpu_core" | awk '{printf "%d", $1/$2}'`
		command="dialog --title 'SIM' --mixedgauge '$msg' 30 100 "$percentage""
		dialog --title "SIM" --mixedgauge "$msg" 30 100 "$percentage"
		read -n 1 -t 3
		if [ $? -eq 0 ]; then
			input=`printf '%d' "'$REPLY"`
			input=`echo -e "$input"`
			if [ $input -eq 0 ]; then
				break
			fi
		fi
	done
	MAIN_MENU
}

#Main Menu
MAIN_MENU(){
	menu_index=`dialog --title "SIM" --stdout --menu "SYS INFO" 30 100 5 1 "CPU INFO" 2 "MEMORY INFO" 3 "NETWORK INFO" 4 "FILE BROWSER" 5 "CPU USAGE"`
	case $menu_index in
		1)
			CPU_INFO
		;;
		2)
			MEMORY_INFO
		;;
		3)
			NETWORK_INTERFACE
		;;
		4)
			cd "$present_working_directory"
			FILE_MENU
		;;
		5)
			CPU_USAGE
		;;
	esac
}

# Main Function
present_working_directory=`pwd`
trap "clear; exit 1" 2
MAIN_MENU
clear
exit 0