#!/bin/bash
# This script can be used to collect basic data about source system when Splunk installation fails.
# It can help Splunk Team to identify what could be the issue.
# Version 1.1

LOG="splunk-debug.log"

echo -n "Collecting logs and environment details..."

date > $LOG

echo "validating /etc/passwd" >> $LOG
grep splunk /etc/passwd  >> $LOG 2>&1
echo "---" >> $LOG

echo "validating /etc/group" >> $LOG
grep splunk /etc/group  >> $LOG 2>&1
echo "---" >> $LOG

echo "checking SELinux" >> $LOG
getenforce >> $LOG 2>&1
echo "---" >> $LOG

echo "checking disks" >> $LOG
df -h  >> $LOG 2>&1
echo "---" >> $LOG

echo "search for read-only filesystems" >> $LOG
grep "[[:space:]]ro[[:space:],]" /proc/mounts >> $LOG 2>&1
echo "---" >> $LOG

echo "checking mem" >> $LOG
free -h  >> $LOG 2>&1
echo "---" >> $LOG

echo "check permissions of /opt" >> $LOG
ll / | grep opt  >> $LOG 2>&1
echo "---" >> $LOG

echo "getting processes" >> $LOG
ps aux  >> $LOG 2>&1
echo "---" >> $LOG

echo "getting list of RPM packages" >> $LOG
rpm -qa >> $LOG 2>&1
echo "---" >> $LOG

echo "getting list of DEB packages" >> $LOG
dpkg -l >> $LOG 2>&1
echo "---" >> $LOG

echo "getting recent events from journald" >> $LOG
ausearch --start today >> $LOG 2>&1
echo "---" >> $LOG

echo "getting kernel dmesg" >> $LOG
dmesg >> $LOG 2>&1
echo "---" >> $LOG

DEBUGARCHIVE="splunk-$HOSTNAME-debug.tar.gz"

tar chfz $DEBUGARCHIVE install-err.log splunk-debug.log /etc/audit /etc/ld.so.* /etc/os-release /etc/security /etc/selinux /etc/sysconfig /opt/splunkforwarder/etc /opt/splunkforwarder/var/log /var/log/audit/* /var/log/messages /var/log/syslog 2>/dev/null 1>/dev/null

echo "done."

echo "Please share $DEBUGARCHIVE with Splunk Team."
