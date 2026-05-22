#!/bin/bash
source "$(dirname "$0")/utils.sh"

os_type=$(uname -s)

if [ "$os_type" = "Linux" ] && command -v pvs &>/dev/null; then
    if sudo -n pvs &>/dev/null 2>&1; then
        print_h2 "LVM — Physical Volumes (pvs)"
        run_and_print "sudo pvs"

        print_h2 "LVM — Volume Groups (vgs)"
        run_and_print "sudo vgs"

        print_h2 "LVM — Logical Volumes (lvs)"
        run_and_print "sudo lvs"
    else
        print_h2 "LVM Information"
        echo "<pre>L'utilisateur n'a pas les droits sudo pour exécuter pvs/vgs/lvs.</pre>"
    fi
fi
