#!/bin/bash

users=($(ps axo user:20 | sort -u | grep -v USER))

for u in ${users[@]}
do
	cpu_percent=$(ps axo user:20,pid,pcpu,pmem | egrep ^${u} | awk '{print $3}' | paste -s -d+ - | bc)
	mem_percent=$(ps axo user:20,pid,pcpu,pmem | egrep ^${u} | awk '{print $4}' | paste -s -d+ - | bc)
	mem_kb=$(ps -U ${u} --no-headers -o rss | awk '{ sum+=$1} END {print int(sum)}')
	num_processes=$(ps aux | awk -v user=${u} '$1 == user {print $0}' | wc -l)
	echo "login_node_user_resource_usage,user=${u} cpu_percent=${cpu_percent},mem_percent=${mem_percent},mem_kb=${mem_kb},num_processes=${num_processes}"
done
