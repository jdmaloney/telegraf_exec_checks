#!/bin/bash

license_path="/var/local/flexlm/licenses"
flexlm_bin_path="/var/local/flexlm/bin"
tfile=$(mktemp /tmp/lic.XXXXXXX)

licenses=($(ls ${license_path}/ | grep '\.dat$\|\.lic$'))

for l in "${licenses[@]}"
do
        ${flexlm_bin_path}/lmstat -c "${license_path}"/"${l}" > "${tfile}"
        IFS=" " read -r text_state text_master server_version <<< "$(grep ": license server " "${tfile}" | rev | cut -d' ' -f 1-3 | rev | sed 's/(//g' | sed 's/)//g')"
        vendor_version=$(tail -n 2 "${tfile}" | head -n 1 | rev | cut -d' ' -f 1 | rev)
        if [ "${text_state}" == "UP" ]; then
                status_health=1
        else
                status_health=0
        fi
        if [ "${text_master}" == "MASTER" ]; then
                status_master=1
        else
                status_master=0
        fi
        "${flexlm_bin_path}"/lmstat -a -c "${license_path}"/"${l}" | grep '^Users\ of' | grep -v "node-locked" > "${tfile}"
        lic_name=$(echo "${l}" | cut -d'.' -f 1)
        echo "flexlm_health,license_name=${lic_name} health_state=${status_health},master_state=${status_master},server_version=\"${server_version}\",vendor_version=\"${vendor_version}\""
        while IFS= read -r line; do
                IFS=" " read -r lic_feature seats_avail seats_used <<< "$(echo "${line}" | cut -d' ' -f 3,7,13 | sed 's/://g')"
                echo "flexlm_stats,license_name=${lic_name},lic_feature=${lic_feature} seats_avail=${seats_avail},seats_used=${seats_used}"
        done < "${tfile}"
done

rm -rf "${tfile}"
