# Telegraf Exec Checks
Custom Exec Checks for Telegraf to Monitor Slurm, Openstack, Kubernetes, and more

## Slurm
These can run on any node that can query the scheduler; add the telegraf user to the slurm admin group so it can query all queues or run slurm commands via sudo

Monitors stats about the health of the slurm scheduler, overall queue and node utilization, detailed node statistics including for shared-node configureations.  Captures resource utilization on a per user, per queue basis over time.  

## FlexLM
Monitors the state of licenses in FlexLM, eg how many of what license are in use over time.  Helps inform on license utilization for alerting and also for capacity planning

## Openstack
Best if run on the controller itself, however can work anywhere so long as the backing MariaDB instance can be reached via the connection/authentication information in: /etc/telegraf/mysql_creds

Monitors resource allocations across the openstack cluster, broken down by hypervisor.  Tracks vCPU, Memory, Volumes, Floating IPs, Instances, and Security Groups in use across the system.  Also tracks the number of instances on a per flavor basis, as well as project quota information.   
