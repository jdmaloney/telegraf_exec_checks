#!/bin/bash

tfile=$(mktemp /tmp/user_resource.XXXXXXXXX)
users=($(ps axo user:20 | sort -u | grep -v USER))
ps axo user:20,pid,pcpu,pmem,rss > "${tfile}"

for u in ${users[@]}
do
	cpu_percent=$(egrep ^${u} ${tfile} | awk '{print $3}' | paste -s -d+ - | bc)
	mem_percent=$(egrep ^${u} ${tfile} | awk '{print $4}' | paste -s -d+ - | bc)
	mem_kb=$(egrep ^${u} ${tfile} | awk '{ sum+=$5} END {print int(sum)}')
	num_processes=$(awk -v user=${u} '$1 == user {print $0}' ${tfile} | wc -l)
	echo "login_node_user_resource_usage,user=${u} cpu_percent=${cpu_percent},mem_percent=${mem_percent},mem_kb=${mem_kb},num_processes=${num_processes}"
done

rm -rf ${tfile}
