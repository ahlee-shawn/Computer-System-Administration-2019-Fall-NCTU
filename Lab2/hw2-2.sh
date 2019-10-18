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
	file "$1" | grep text
	if [ "$?" -eq 1 ]; then
		dialog --title "SIM" --msgbox "<File Name>: $2\n<File Info>: $file_info\n<File Size>: $number ${unit_array[${base}]}" 30 100
	else
		dialog --title "SIM" --no-label "Edit" --yesno "<File Name>: $2\n<File Info>: $file_info\n<File Size>: $number ${unit_array[${base}]}" 30 100
		if [ "$?" -eq 1 ]; then
			$EDITOR "$1"
		fi
	fi
	FILE_BROWSER "$(dirname "$1")"
}

FILE_BROWSER(){
	if [ "$1" != "/" ]; then
		current_dir=`echo "$1" | awk '{print $1 "/"}'`
	else
		current_dir="$1"
	fi
	command="dialog --title 'SIM' --stdout --menu '$1' 30 100 50"
	file_type=`ls -a -ll "$current_dir" | grep '^[-d]' | awk '{if($1 ~ /^d/) {print "d"} else {print "f"}}' | xargs echo`
	read -a file_type_array <<< "$file_type"
	file_name=`ls -a -ll "$current_dir" | grep '^[-d]' | awk '{print $9}' | xargs echo`
	read -a file_name_array <<< "$file_name"
	temp=`ls -a -ll "$current_dir" | grep '^[-d]' | awk '{print $9}' | xargs echo`
	read -a temp_array <<< "$temp"
	for ((i = 0 ; i < "${#temp_array[@]}" ; i++)); do
		temp_array["$i"]=`echo $1 "${temp_array[$i]}" | awk '{print $1 "/" $2}'`
	done
	file_mime=`printf "%s\n" "${temp_array[@]}" | xargs file --mime-type | awk '{print $2}' | xargs echo`
	read -a file_mime_array <<< "$file_mime"
	for ((i = 0 ; i < "${#file_type_array[@]}" ; i++)); do
  		command="${command} '${file_name_array[$i]}' '${file_mime_array[$i]}'"
	done
	file_name_index=`eval $command`
	if [ "$file_name_index" == "." ]; then
		FILE_BROWSER "$1"
	elif [ "$file_name_index" == ".." ]; then
		FILE_BROWSER "$(dirname "$1")"
	else
		if [ "$1" != "/" ]; then
			next_dir="$1/$file_name_index"
		else
			next_dir="$1$file_name_index"
		fi
		for ((i = 0 ; i < "${#file_type_array[@]}" ; i++)); do
			if [ "$file_name_index" == "${file_name_array[$i]}" ]; then
				if [ "d" == "${file_type_array[$i]}" ]; then
					FILE_BROWSER $next_dir
				else
					FILE_INFO $next_dir $file_name_index
				fi
			fi
		done
	fi
}

FILE_MENU(){
	FILE_BROWSER $1
	MAIN_MENU
}

CPU_USAGE(){
	sleep 3
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
			FILE_MENU `pwd`
		;;
		5)
			CPU_USAGE
		;;
	esac
}

# Main Function
trap "clear; exit 1" 2
MAIN_MENU
clear
exit 0