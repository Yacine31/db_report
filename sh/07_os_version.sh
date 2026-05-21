#!/bin/bash
source "$(dirname "$0")/utils.sh"

os_type=$(uname -s)

case "$os_type" in
    Linux)
        print_h2 "OS Version (/etc/os-release)"
        run_and_print "cat /etc/os-release"
        ;;
    AIX)
        print_h2 "OS Version (oslevel)"
        run_and_print "oslevel -s"
        ;;
esac
