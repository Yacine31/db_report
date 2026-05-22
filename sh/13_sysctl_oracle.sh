#!/bin/bash
source "$(dirname "$0")/utils.sh"

os_type=$(uname -s)

if [ "$os_type" = "Linux" ]; then
    print_h2 "Kernel Parameters (Oracle-related sysctl)"
    run_and_print "sysctl -a 2>/dev/null | grep -E 'kernel\.sem|kernel\.shm|kernel\.msgmax|kernel\.msgmnb|kernel\.msgmni|vm\.nr_hugepages|vm\.hugetlb_shm_group|vm\.swappiness|net\.ipv4\.ip_local_port_range|net\.core\.(rmem|wmem)'"
fi
