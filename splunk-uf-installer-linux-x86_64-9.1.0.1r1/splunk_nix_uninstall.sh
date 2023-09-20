#!/bin/bash

# Splunk UF/HF Uninstaller
# version 1.7
#
# Version history
# 1.2 Better deals with any process left
# 1.3 Option -p to specify path if differs from default one
# 1.4 Restore of audit.rules file on older systems
# 1.5 Make it universal for UF & HF; read variables from config file
# 1.6 Do not ask about uninstallation if -y switch is present
# 1.7 Make sure SPLUNK_HOME path is defined; improved disable boot-start

# Error codes
# 1 - Splunk is not installed
# 10 - not executed as root
# 11 - no SPLUNK_HOME path

# We need to check if any parameters were issued
CLEANUP=0
YES=0

# Read customizable variables
if [ -f splunk.config ]; then
  . splunk.config
else
  echo "ERROR: Installer config file is missing"
  echo "Trying to detect Splunk..."
  SPLUNKD_RUNNING=`for PID in $(pidof splunkd); do ls -l /proc/$PID/exe; done | grep -m1 "bin/splunkd" | sed 's/^.*-> //'`
  if [ -d /opt/splunkforwarder/bin ]; then
    SPLUNK_HOME="/opt/splunkforwarder"
  elif [ -d /opt/splunk/bin ]; then
    SPLUNK_HOME="/opt/splunk"
  elif [ -n "$SPLUNKD_RUNNING" ]; then
      SPLUNK_HOME=`echo $SPLUNKD_RUNNING | sed 's/\/bin.*//'`
  else
    echo "Unable to find Splunk installation! Exiting..."
    exit 1
  fi
fi

while [ $# -gt 0 ]
do
  key="$1"

  case $key in
    -c|--cleanup)
    CLEANUP=1
    shift
    ;;
    -y|--yes)
    YES=1
    shift
    ;;
    -p|--path)
    SPLUNK_HOME="$2"
    shift
    shift
    ;;
    -h|--help|*)
    echo "Valid arguments:"
    echo "  -c, --cleanup               Force cleanup of any partially installed/uninstalled Splunk instance, assume yes on confirmation"
    echo "  -p, --path PATH             Specify path to Splunk home dir, e.g. /opt/splunkforwarder"
    echo "  -y, --yes                   Do not ask use if he really wants to uninstall Splunk, assume yes."
    echo "  -h, --help                  Show help"
    echo
    exit 0
    ;;
  esac
done


# Check if script is executed under root account
if [ "$(id -u)" != "0" ]; then
   echo "ERROR This script must be run as root" 1>&2
   exit 10
fi

# Check is Splunk home is defined
if [ -z "$SPLUNK_HOME" ]; then
   echo "ERROR: no SPLUNK_HOME path defined" 1>&2
   exit 11
fi

# Check if Splunk UF is installed
#
if [ -d "$SPLUNK_HOME/bin" ]; then
  echo "Splunk installation found in $SPLUNK_HOME"
  if [ $YES -ne 1 ]; then
    while true; do
      read -p "Do you want to proceed with uninstallation? (Y/N)" yn
      case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer 'y'/'Y' to continue or 'n'/'N' to exit";;
      esac
    done
  fi
elif [ $CLEANUP -eq 1 ]; then
  echo "Will proceed with cleanup, errors might be shown."
else
  echo "Splunk is not installed on this host, exiting"
  exit 1
fi

INIT=`ps -p 1 | grep 1 | awk {' print $4 '}`

# Stopping Splunk
#
if [ "$INIT" = "systemd" ] && [ "$(systemctl list-units --all | grep SplunkForwarder)" ] ; then
  systemctl stop SplunkForwarder.service
  if [ $? -eq 0 ]; then
    echo "Splunk stopped, removing install directory"
  else
    echo "Splunk was not stopped gracefully, it will be forced to stop."
  fi
elif [ "$INIT" = "systemd" ] && [ "$(systemctl list-units --all | grep Splunkd)" ] ; then
  systemctl stop Splunkd.service
  if [ $? -eq 0 ]; then
    echo "Splunk stopped, removing install directory"
  else
    echo "Splunk was not stopped gracefully, it will be forced to stop."
  fi
else
  su -c "$SPLUNK_HOME/bin/splunk stop" splunk
  if [ $? -eq 0 ]; then
    echo "Splunk stopped, removing install directory"
  else
    echo "Splunk was not stopped gracefully, it will be forced to stop."
  fi
fi
# Disabling bootstart
#
$SPLUNK_HOME/bin/splunk disable boot-start -systemd-managed 0
$SPLUNK_HOME/bin/splunk disable boot-start -systemd-managed 1

# Revert back ACL / permission changes if any
HAVEACL=`getfacl /var/log | grep splunk`
if [ -n "$HAVEACL" ]; then
  echo "Removing ACL in /var/log"
  setfacl -R -x g:splunk /var/log
fi

if [ -f /etc/audit/auditd.conf-presplunk ]; then
  echo "Restoring auditd settings"
  mv -f /etc/audit/auditd.conf /etc/audit/auditd.conf-splunk
  mv -f /etc/audit/auditd.conf-presplunk /etc/audit/auditd.conf
  rm -f /etc/audit/rules.d/accenture-is.rules
  if [ -f /etc/audit/audit.rules-presplunk ]; then
    mv -f /etc/audit/audit.rules /etc/audit/audit.rules-splunk
    mv -f /etc/audit/audit.rules-presplunk /etc/audit/audit.rules
  fi
  service auditd restart
fi

# Force Splunk to stop if it was not stopped gracefully before
if pidof "splunkd"; then
  kill -9 `pidof splunkd`
fi
pkill -u splunk

# Removing install directory
#
if [ -d "$SPLUNK_HOME" ]; then
  rm -rf $SPLUNK_HOME
fi
userdel splunk
if [ "$(grep ^splunk /etc/group)" ]; then
  groupdel splunk
fi
echo "Removed install directory $SPLUNK_HOME, exiting"

exit
