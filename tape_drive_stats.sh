#!/bin/bash

## Built to monitor basic stats on FC connected tape drives

## Get list of tape drives
drives=($(ls /sys/class/scsi_tape | grep ^st | rev | grep ^[0-9] | rev))

## For each drive get stats
for d in ${drives[@]}
do
	line="tape_stats,drive_device=${d} "
	counters=($(ls /sys/class/scsi_tape/${d}/stats/))

	## For each counter get stats
	for c in ${counters[@]}
	do
		value=$(cat /sys/class/scsi_tape/${d}/stats/${c})
		line=${line},${c}=${value}
	done

	## Strip out extra leading comma
	line=$(echo ${line} | sed 's/\ ,/\ /')
	echo ${line}
done
