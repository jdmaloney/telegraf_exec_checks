# Telegraf Exec Checks
Custom Exec Checks for Telegraf to Monitor Slurm, Openstack, Kubernetes, HTCondor, and more

## Slurm
These can run on any node that can query the scheduler; add the telegraf user to the slurm admin group so it can query all queues or run slurm commands via sudo

Monitors stats about the health of the slurm scheduler, overall queue and node utilization, detailed node statistics including for shared-node configureations.  Captures resource utilization on a per user, per queue basis over time.  

## FlexLM
Monitors the state of licenses in FlexLM, eg how many of what license are in use over time.  Helps inform on license utilization for alerting and also for capacity planning

## Openstack
Best if run on the controller itself, however can work anywhere so long as the backing MariaDB instance can be reached via the connection/authentication information in: /etc/telegraf/mysql_creds

Monitors resource allocations across the openstack cluster, broken down by hypervisor.  Tracks vCPU, Memory, Volumes, Floating IPs, Instances, and Security Groups in use across the system.  Also tracks the number of instances on a per flavor basis, as well as project quota information.  

## Rstudio Pro
Configure with Rstudio Pro Health URL.  

This check pulls down and ingests data from the Rstudio Pro health endpoint for storing in InfluxDB; this is useful for tracking Rstudio license activation and other health status information. 

## K8s Health
Have this check run on all K8s hosts in a cluster; it needs:
- The name of the CNI used in the cluster (eg. flannel, weave, etc)
- The path to a kubectl command that has permissions to view all namespaces on the cluster

This check monitors the health of core K8s services that support the health of K8s itself.  This includes the CNI in use, kube-apiserver, kube-proxy, kube-scheduler, kube-controller-manager, and coredns.  Additional services can be added if desired however one needs to remain aware of cardinality.  Monitoring the health of services *managed by/run "on top of" K8s* are best monitored via other means.  This check is meant to provide insight into the health of the core functions of a bare metal K8s deployment. 

## HTCondor Stats
These checks run on the condor scheduler and grabs information about host utilization, job counts, job counts by user, core and memory utilization, and overall usage metrics. 

## Tape Drive Stats
This check ingests read/write stats for tape drives from /sys/class/fc_host/hostXX/statistics and injects them into InfluxDB
