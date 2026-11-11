#!/bin/bash
# Services systeme qui comptent pour Oracle : synchronisation horaire, SELinux, pare-feu, profil tuned
source "$(dirname "$0")/utils.sh"

[ "$(uname -s)" = "Linux" ] || exit 0

if command -v chronyc &>/dev/null; then
    print_h2 "Time Synchronization (chronyc tracking)"
    run_and_print "chronyc tracking"
elif command -v ntpq &>/dev/null; then
    print_h2 "Time Synchronization (ntpq -p)"
    run_and_print "ntpq -p"
elif command -v timedatectl &>/dev/null; then
    print_h2 "Time Synchronization (timedatectl)"
    run_and_print "timedatectl"
fi

if command -v getenforce &>/dev/null; then
    print_h2 "SELinux Mode (getenforce)"
    run_and_print "getenforce"
fi

if command -v systemctl &>/dev/null; then
    print_h2 "Firewall Service (firewalld)"
    # is-active retourne un code non nul quand le service est arrete : ce n'est pas une erreur
    run_and_print "systemctl is-active firewalld || true"
fi

if command -v tuned-adm &>/dev/null; then
    print_h2 "Tuned Profile (tuned-adm active)"
    run_and_print "tuned-adm active"
fi

if command -v rpm &>/dev/null; then
    print_h2 "Last Installed Packages (rpm -qa --last)"
    run_and_print "rpm -qa --last | head -10"
fi
