#!/bin/bash

tfile=$(mktemp /tmp/condor.XXXXXXX)

condor_q > "${tfile}"

## Overall Summary Stats
read -r tot_jobs tot_completed tot_removed tot_idle tot_running tot_held tot_suspended <<< "$(grep "Total for all users" ${tfile} | awk '{print $5" "$7" "$9" "$11" "$13" "$15" "$17}')"
echo "condor_agg_stats,type=jobs total_jobs=${tot_jobs},completed_jobs=${tot_completed},removed_jobs=${tot_removed},running_jobs=${tot_running},held_jobs=${tot_held},suspended_jobs=${tot_suspended}"

## User Current Running information
users=($(head -n -4 "${tfile}" | tail -n +5 | awk '{print $1}' | sort -u | xargs))

for u in "${users[@]}"
do
	read -r tot_jobs tot_completed tot_removed tot_idle tot_running tot_held tot_suspended <<< "$(condor_q -submitter ${u} | grep "Total for query" | awk '{print $4" "$6" "$8" "$10" "$12" "$14" "$16}')"
	echo "condor_user_stats,user=${u} total_jobs=${tot_jobs},completed_jobs=${tot_completed},removed_jobs=${tot_removed},running_jobs=${tot_running},held_jobs=${tot_held},suspended_jobs=${tot_suspended}"
done

## User Historical Data
#condor_userprio -usage -allusers > "${tfile}"
#users=($(grep @ ${tfile} | cut -d'@' -f 1 | xargs))

#for u in "${users[@]}"
#do
#	grep "${u}"@ "${tfile}"
#done

## Machine Status
condor_status > "${tfile}"

read -r machines owner claimed unclaimed matched preempting drain <<< "$(tail -n 1 ${tfile} | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')"
echo "condor_agg_stats,type=nodes machines=${machines},owner=${owner},claimed=${claimed},unclaimed=${unclaimed},matched=${matched},preempting=${preempting},drain=${drain}"

## High Level Node Stats
IFS=" " read nodes_total nodes_owner nodes_claimed nodes_unclaimed nodes_matched nodes_preempting nodes_drain <<< "$(condor_status -total | tail -n 1 | awk '{print $2,$3,$4,$5,$6,$7,$8}')"

echo "condor_host_stats nodes_total=${nodes_total},nodes_owner=${nodes_owner},nodes_cliamed=${nodes_claimed},nodes_unclaimed=${nodes_unclaimed},nodes_match=${nodes_matched},nodes_preempting=${nodes_preempting},nodes_drain=${nodes_drain}"


rm -rf "${tfile}"
