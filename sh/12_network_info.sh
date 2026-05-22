#!/bin/bash
source "$(dirname "$0")/utils.sh"

os_type=$(uname -s)

if [ "$os_type" = "Linux" ]; then
    print_h2 "Routing Table (ip r)"
    run_and_print "ip r"

    print_h2 "Hosts File (/etc/hosts)"
    run_and_print "cat /etc/hosts"
fi
