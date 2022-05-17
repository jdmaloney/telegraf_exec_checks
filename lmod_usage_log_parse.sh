#!/bin/bash

## NOTE: Telegraf user needs either permissions or ability to sudo to acces module usage file
tfile=$(mktemp /tmp/lmp.XXXXXXX)
log_path=""

## Last Minute
## Get any log lines from past 60 seconds and chunk it to only what we need
date_filter=$(date +"%b %d %H:%M:" -d -1minute)
cat ${log_path} | grep "${date_filter}" | cut -d'=' -f 2,4,6 | sed -e 's/module=//g' -e 's/host=//g' > "${tfile}"

## Parse lines
while read -r line; do
	IFS=" " read -r username mod_path load_time_raw <<< "${line}"
	load_time=$(echo "${load_time_raw}" | sed 's/\.//g')
	echo "lmod_usage_stats,username=${username},module=${mod_path} count=1 ${load_time}000"
done < ${tfile}

## Cleanup
rm -rf ${tfile}
