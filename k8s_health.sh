#!/bin/bash

### Fill in these two variables
kubectl_path="" ## path to kubectl command that has permissions on cluster
cni="" ## cni-pod name in use, eg. kube-flannel

tfile=$(mktemp /tmp/k8.XXXXXXX)
${kubectl_path} get pods -n kube-system -o wide > ${tfile}

core_services=(kube-apiserver kube-proxy kube-scheduler kube-controller-manager coredns)
core_services+=("$cni")

for c in ${core_services[@]}
do
	while read l; do
		match=$(echo ${l} | grep ${c})
		if [ -n "${match}" ]; then
			restarts=$(echo ${l} | awk '{print $4}')
			raw_uptime=$(echo ${l} | awk '{print $5}')

			##Convert Time
			days=$(echo $raw_uptime | grep d | cut -d'd' -f 1)
			hours=$(echo $raw_uptime | grep h | cut -d'h' -f 1 | cut -d'd' -f 2)
			minutes=$(echo $raw_uptime | grep m | cut -d'm' -f 1 | cut -d'h' -f 2)
			seconds=$(echo $raw_uptime | grep s | cut -d's' -f 1 | cut -d'm' -f 2)
			uptime=$(((days*86400)+(hours*3600)+(minutes*60)+seconds))

			instance_count=$(echo ${l} | awk '{print $2}' | cut -d'/' -f 1)
			node=$(echo ${l} | awk '{print $7}')
			state=$(echo ${l} | awk '{print $3}')
			case "$state" in
				Running) state_code=0
				;;
				CrashLoopBackOff) state_code=1
				;;
				Terminating) state_code=2
				;;
				*) state_code=3
				;;
			esac

			echo k8s_health,service=${c},k8host=${node} restarts=${restarts},uptime=${uptime},instances=${instance_count},state=${state},state_code=${state_code}
		fi
	done <${tfile}
done

rm -rf ${tfile}
