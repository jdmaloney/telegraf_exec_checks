#!/bin/bash


tfile=$(mktemp /tmp/openstack.XXXXXXX)

## Hypervisor Metrics
mysql --defaults-extra-file=/etc/telegraf/mysql_creds -D nova -e "select host,vcpus,vcpus_used,memory_mb,memory_mb_used,running_vms from compute_nodes" | tail -n +2 | sed 's/\t/,/g' > "${tfile}"

while IFS= read -r line; do
        IFS="," read -r hypervisor vcpus vcpus_used memory_mb memory_mb_used running_vms <<< "${line}"
        echo "openstack_metrics,hypervisor=${hypervisor} vcpus=${vcpus},vcpus_used=${vcpus_used},memory_mb=${memory_mb},memory_mb_used=${memory_mb_used},running_vms=${running_vms}"
done < "${tfile}"


## Resource Usage Totals and by Project
mysql --defaults-extra-file=/etc/telegraf/mysql_creds -e "select p.name,u.name,sum(v.size),count(v.id) from cinder.volumes v inner join keystone.project p on v.project_id = p.id left outer join keystone.nonlocal_user u on v.user_id = u.user_id where v.status != 'deleted' group by p.name,u.name" | tail -n +2 | sed 's/\t/,/g' > "${tfile}"

while IFS= read -r line; do
        IFS="," read -r project_name user_name volume_usage_gb volume_count <<< "${line}"
        echo "openstack_usage_metrics,project_name=${project_name},user_name=${user_name} volume_usage_gb=${volume_usage_gb},volume_count=${volume_count}"
done < "${tfile}"

mysql --defaults-extra-file=/etc/telegraf/mysql_creds -e "select p.name,u.name,count(i.id),sum(i.vcpus),sum(i.memory_mb),i.power_state from nova.instances i inner join keystone.project p on p.id = i.project_id left outer join keystone.nonlocal_user u on u.user_id = i.user_id where i.deleted_at IS NULL group by p.name,u.name,i.power_state;" | tail -n +2 | sed 's/\t/,/g' > "${tfile}"

while IFS= read -r line; do
        IFS="," read -r project_name user_name instance_count vcpus_used memory_mb_used power_state <<< "${line}"
        echo "openstack_usage_metrics,project_name=${project_name},user_name=${user_name} instance_count=${instance_count},vcpus_used=${vcpus_used},memory_mb_used=${memory_mb_used},power_state=${power_state}"
done < "${tfile}"

mysql --defaults-extra-file=/etc/telegraf/mysql_creds -e "select p.name,count(n.floating_ip_address) from neutron.floatingips n inner join keystone.project p on n.project_id = p.id where n.status = 'ACTIVE' group by p.name" | tail -n +2 | sed 's/\t/,/g' > "${tfile}"

while IFS= read -r line; do
        IFS="," read -r project_name floating_ips <<< "${line}"
        echo "openstack_usage_metrics,project_name=${project_name} floating_ips=${floating_ips}"
done < "${tfile}"

mysql --defaults-extra-file=/etc/telegraf/mysql_creds -e "select p.name,count(s.id) from neutron.securitygroups s inner join keystone.project p on s.project_id = p.id WHERE s.project_id != '' group by p.name;" | tail -n +2 | sed 's/\t/,/g' > "${tfile}"

while IFS= read -r line; do
        IFS="," read -r project_name security_groups <<< "${line}"
        echo "openstack_usage_metrics,project_name=${project_name} security_groups=${security_groups}"
done < "${tfile}"

## Resource Quota Totals and by Project
## Nova
mysql --defaults-extra-file=/etc/telegraf/mysql_creds -e "select p.name,n.resource,n.hard_limit from nova_api.quotas n inner join keystone.project p on n.project_id = p.id where n.resource in ('cores','instances','ram') group by p.name,n.resource" | tail -n +2 | sed 's/\t/,/g' > "${tfile}"

while IFS= read -r line; do
        IFS="," read -r project_name resource hard_limit <<< "${line}"
        echo "openstack_quota_metrics,project_name=${project_name},resource=${resource} hard_limit=${hard_limit}"
done < "${tfile}"

## Neutron
mysql --defaults-extra-file=/etc/telegraf/mysql_creds -e "select p.name,n.resource,n.limit from neutron.quotas n inner join keystone.project p on n.project_id = p.id where n.resource in ('floatingip') group by p.name,n.resource" | tail -n +2 | sed 's/\t/,/g' > "${tfile}"

while IFS= read -r line; do
        IFS="," read -r project_name resource hard_limit <<< "${line}"
        echo "openstack_quota_metrics,project_name=${project_name},resource=${resource} hard_limit=${hard_limit}"
done < "${tfile}"

## Cinder
mysql --defaults-extra-file=/etc/telegraf/mysql_creds -e "select p.name,c.resource,c.hard_limit from cinder.quotas c inner join keystone.project p on c.project_id = p.id where c.resource in ('volumes','gigabytes') group by p.name,c.resource" | tail -n +2 | sed 's/\t/,/g' > "${tfile}"

while IFS= read -r line; do
        IFS="," read -r project_name resource hard_limit <<< "${line}"
        echo "openstack_quota_metrics,project_name=${project_name},resource=${resource} hard_limit=${hard_limit}"
done < "${tfile}"

## Security Groups


## Flavor Data
mysql --defaults-extra-file=/etc/telegraf/mysql_creds -D nova -e "select flavor from instance_extra where deleted_at IS NULL" | cut -d'"' -f 58 | tail -n +2 | sort | uniq -c | sed 's/^ *//g' > "${tfile}"

while IFS= read -r line; do
        IFS=" " read -r instance_count flavor <<< "${line}"
        echo "openstack_metrics,flavor_name=${flavor} instance_count=${instance_count}"
done < "${tfile}"

rm -rf "${tfile}"
