#!/bin/bash

tfile=$(mktemp /tmp/ib.XXXXXX)

devices=($(ibstat -l | xargs))

for d in ${devices[@]}
do
	ibstat ${d} | grep -B3 "Rate:" | grep -v "\-\-" > "${tfile}"
	ports=($(grep Port "${tfile}" | cut -d':' -f 1 | cut -d' ' -f 2))
	for p in ${ports[@]}
	do
		state=$(grep -A3 "Port ${p}" "${tfile}" | grep "State:" | cut -d' ' -f 2)
		link=$(grep -A3 "Port ${p}" "${tfile}" | grep "Physical" | cut -d' ' -f 3)
		rate=$(grep -A3 "Port ${p}" "${tfile}" | grep "Rate:" | cut -d' ' -f 2)
		if [ "${state}" == "Active" ]; then
			active_code=1
		else
			active_code=0
		fi
		if [ "${link}" == "LinkUp" ]; then
			link_code=1
		else
			link_code=0
		fi
		echo "ib_health,device=${d},port=port_${p} state=\"${state}\",active_code=${active_code},phys_state=\"${link}\",link_code=${link_code},rate=${rate}"
	done
done

rm -rf ${tfile}
