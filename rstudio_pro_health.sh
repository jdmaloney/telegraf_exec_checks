#!/bin/bash

health_url=""

tfile=$(mktemp /tmp/rstudio.XXXXXXXX)

wget --quiet -O "${tfile}" "${health_url}"
if [ $? -ne 0 ]; then
	exit 0
fi

fields=$(cat "${tfile}" | grep -v "license-status" | sed 's/://g' | sed 's/\ /=/g' | xargs | sed 's/\ /,/g')

lic_status=$(grep "license-status" "${tfile}" | awk '{print $2}')
if [ "${lic_status}" != "Activated" ]; then
	license_activation_alert=1
else
	license_activation_alert=0
fi

echo "rstudio_pro_stats ${fields},license_activation_alert=${license_activation_alert}"

rm -rf "${tfile}"
