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

## Verifies Mellanox Card PCIe Link Speeds
is_cap=1
ibcard_pcie_link_err=0
while IFS= read -r line; do
	if [ "${is_cap}" -eq 1 ]; then
		expected=${line}
		is_cap=0
	else
		if [ "${expected}" != "${line}" ]; then
			ibcard_pcie_link_err=1
		fi
		is_cap=1
	fi
done < <(lspci -vv | grep -A25 Infiniband | grep 'LnkSta:\|LnkCap:' | grep -oP "Width\s+\K\w+")

echo "ib_health,check_type=pcie_link_speed pcie_link_error=${ibcard_pcie_link_err}"

## Check Log for IB Errors
is_iso=$(tail -n 1 /var/log/messages | awk '{print $1}' | grep "-")

if [ -n "${is_iso}" ]; then
	## Log uses RFC 5424 format timestamps
	current_minute=$(date +%Y-%m-%dT%H:%M)
	interfaces=($(ip a | grep "ib[0-9]:" | cut -d':' -f 2 | cut -c 2- | xargs))
	for i in ${interfaces[@]}
	do
		ib_timeout_count=$(grep "${current_minute}" /var/log/messages | grep "transmit timeout" | grep "${i}" | wc -l)
		echo "ib_health,interface=${i},check_type=transmit_timeout count=${ib_timeout_count}"
	done
else
	## Log uses RFC 3164 format timestamps
	current_minute=$(date +'%b %d %H:%M')
	interfaces=($(ip a | grep "ib[0-9]:" | cut -d':' -f 2 | cut -c 2- | xargs))
	for i in ${interfaces[@]}
        do
                ib_timeout_count=$(grep "${current_minute}" /var/log/messages | grep "transmit timeout" | grep "${i}" | wc -l)
                echo "ib_health,interface=${i},check_type=transmit_timeout count=${ib_timeout_count}"
        done
fi

rm -rf ${tfile}
