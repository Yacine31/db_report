#!/bin/bash
source "$(dirname "$0")/utils.sh"

os_type=$(uname -s)

case "$os_type" in
    Linux)
        print_h2 "OS Version"
        run_and_print "cat /etc/os-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null || cat /etc/debian_version 2>/dev/null || uname -a"
        ;;
    AIX)
        print_h2 "OS Version (oslevel)"
        run_and_print "oslevel -s"
        ;;
esac
