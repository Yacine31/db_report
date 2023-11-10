prompt <h2>Running Databases</h2>
prompt <pre>
host ps -ef | grep pmon | grep -v grep 
prompt </pre>

prompt <h2>Running listeners</h2>
prompt <pre>
host ps -ef | grep tnslsnr| grep -v grep 
prompt </pre>

prompt <h2>Disk Size df -h</h2>
set echo off head off
prompt <pre>
host df -h
prompt </pre>

prompt <h2>lsblk -f </h2>
prompt <pre>
host lsblk -f
prompt </pre>

prompt <h2>cat /etc/fstab </h2>
prompt <pre>
host cat /etc/fstab
prompt </pre>

prompt <h2>Memory Size (Mo) : free -m </h2>
prompt <pre>
host free -m
prompt </pre>

prompt <h2>lscpu </h2>
prompt <pre>
host lscpu
prompt </pre>
exit