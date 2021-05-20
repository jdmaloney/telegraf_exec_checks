#!/bin/bash

## Built to monitor basic stats on FC connected tape drives

drives=($(ls /sys/class/fc_host))

for d in ${drives[@]}
do
	if [ "$(cat /sys/class/fc_host/${d}/speed)" != "unknown" ]; then
	line="tape_stats,drive_device=${d} "
	counters=(rx_words tx_words)
	for c in ${counters[@]}
	do
		hex_value=$(cat /sys/class/fc_host/${d}/statistics/${c})
		value=$(printf "%d\n" ${hex_value})
		line=${line},${c}=${value}
	done
	line=$(echo $line | sed 's/\ ,/\ /')
	echo ${line}
	fi
done
