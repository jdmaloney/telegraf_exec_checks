#!/bin/bash

## Script to gather condor user accounting metrics

tfile=$(mktemp /tmp/condor_usage.XXXXXX)

## User Historical Data
condor_userprio -usage -allusers > "${tfile}"

num_users=$(tail -n 1 ${tfile} | awk '{print $4}')
total_weighted_hours=$(tail -n 1 ${tfile} | awk '{print $6}')
echo "condor_agg_stats,type=total_users count=${num_users}"
echo "condor_agg_stats,type=total_weighted_hours count=${total_weighted_hours}"

users=($(grep @ ${tfile} | awk '{print $1}'))

for u in "${users[@]}"
do
	last_used_time=$(grep "${u}" ${tfile} | awk '{print $6" "$7}' | { read ltime ; date -d "$ltime" +%s%N; })
	tot_weighted_hours=$(grep "${u}" ${tfile} | awk '{print $3}')
	echo "condor_user_metrics,username=${u} tot_weighted_hours=${tot_weighted_hours},last_used_time=${last_used_time}"
done

rm -rf ${tfile}
