#!/bin/bash
# Splunk UF/HF Installer
# version 3.16
# Changelog
# 1.0 Initial rewritten release
# 1.1 Improved pre-flight checks, improved logging, added systemd support
# 1.2 Added SHA1 of important apps, check-only mode
# 1.3 Use known password, detect and enable/disable journalD, check 8089 port
# 1.4 Added audit rules
# 1.5 Some changes to audit rules, enforce to set permissions by script
# 1.6 Added switches to disable connectivity test, do not start Splunk UF and force install despite errors
# 1.7 Refined to be more POSIX compliant (and DASH compatibile)
# 1.8 Improved ACL checking for ext4/ext3. Show error only if explicitely disabled (noacl)
# 2.0 Rewritten to be more function-oriented and allow application to be updated independently and permissions + audit rules to be set without a need to reinstall whole agent.
# 2.1 Run full set of tests except connectivity checking when -a or -s switches are used, do not allow apps update if Splunk version is older than 8.1
# 2.2 Fixed port 8089 detection
# 2.3 Replace realpath with more POSIX-oriented way to get full script path
# 2.4 Option -g to use simple formatting in phase 1; phase 1 errors summary; phase 1 errors logged to install-err.log when forced to continue
# 2.5 Old dev apps cleanup; verify Splunk version using regex instead of bc; better output formatting; added timesyncd and chronyd as alternative to ntpd
# 2.6 Make sure executable flag is set for 000_accenture_is/bin shell scripts
# 2.7 Added alternative to hostname -I where not supporte
# 2.8 Make sure audit rules were updated
# 2.9 Clean up prod IS output app using older naming convention
# 3.0 Added python as recommended dependency
# 3.1 Configure audit rules in older system without rules.d; handle auditd.conf config changes more carefully
# 3.2 Use /var/log/audit as primary source instead of Python script till all issues are resolved
# 3.3 Audit logs collected using scripted input; added DS app configuration
# 3.4 Improved /var/log FS type detection; improved OS detection if os-release is not available
# 3.5 JournalD used by default with no action from installer if found.
# 3.6 Fixed syntax error
# 3.7 Unified UF & HF installer; external config file; acnhf.cfg with meta generated during HF installation
# 3.8 additional meta in acnhf.cfg replaced with better logic in add_meta.sh script
# 3.9 Set clientName prefix in deploymentclient config for Core & V&A HFs
# 3.10 Update of systemd unit on systems without system slices; improved Splunk initialization; removed Python dependency
# 3.11 Added Splunk version & release details; create acnis files to help with automation in future
# 3.12 Minor updates to acnis files to align Win & Linux approach
# 3.13 Changes to HF types definition; improved Site ID input handling
# 3.14 Minor improvements to Splunk init
# 3.15 Another minor improvements to Splunk init
# 3.16 Added INSTALL_METHOD information; remove any orphan init; added option to prepare an image / template installation

# We need to check if any parameters were issued
USEINIT=0
CHECKONLY=0
START=1
FANCYOUTPUT=1
CHECKCONN=1
FORCEINST=0
APPSONLY=0
PERMSONLY=0
IMAGE=0
DOEXIT=0

# Read customizable variables
if [ -f splunk.config ]; then
  . splunk.config
else
  echo "ERROR: Installer config file is missing! Your installation package is probably incomplete."
  exit 1
fi

while [ $# -gt 0 ]
do
  key="$1"

  case $key in
    -a|--apps-only)
    APPSONLY=1
    shift
    ;;
    -c|--check-only)
    CHECKONLY=1
    shift
    ;;
    -d|--donot-start)
    START=0
    shift
    ;;
    -f|--force-continue)
    FORCEINST=1
    shift
    ;;
    -g|--genuine-ouput)
    FANCYOUTPUT=0
    shift
    ;;
    -i|--use-init)
    USEINIT=1
    shift
    ;;
    -m|--image)
    IMAGE=1
    START=0
    shift
    ;;
    -p|--skip-portcheck)
    CHECKCONN=0
    shift
    ;;
    -s|--set-perms)
    PERMSONLY=1
    shift
    ;;
    -t|--site-id)
    SITEID="$2"
    shift
    shift
    ;;
    -h|--help|*)
    echo
    echo "Accenture Splunk installer for Linux help."
    echo
    echo "Valid arguments for phase 1 (environment assessment):"
    echo "  -c, --check-only            Run pre-flight checks only to see system readiness for Splunk installation"
    echo "  -f, --force-continue        Force installer to continue even if mandatory dependencies are missing"
    echo "  -g, --genuine-output        Do not add colors and formatting to output (better for automation)"
    echo "  -h, --help                  Show help"
    echo "  -m, --image                 Do not fully initialize Splunk, so it can be part of an OS image or a VM template (implies -d switch)"
    echo "  -p, --skip-portcheck        Skip checking connectivity to Splunk Cloud over default port TCP/9997"
    echo
    echo "Valid arguments for phase 2 (installation mode):"
    echo "  -d, --donot-start           Do not start UF at the end of standard installation process (can't combine with -a or -s)"
    echo "  -i, --use-init              Force to use init.d to autostart even if systemd is used as system init (can't combine with -a or -s)"
    echo "  -t num, --site-id num       Set SIA Site ID field. Applicable for Heavy Forwarder installation only (non-interactive installation)"
    echo
    echo "Valid arguments for phase 2 (update mode):"
    echo "  -a, --apps-only             Update or install Accenture IS apps only (implies -p)"
    echo "  -s, --set-perms             Update or set necessary permissions and AuditD ruleset only (implies -p)"
    echo
    echo "Hint: Use combination of -a -s arguments for dual-destination installations, so only apps are deployed and permissions are set."
    echo "Notice: Applications update (--apps-only) requires Splunk version 8.1 or higher."
    echo
    exit 0
    ;;
  esac
done

# Some formatting stuff
if [ $FANCYOUTPUT -eq 1 ]; then
  ERRC="\033[1;97m\033[41m"
  WARNC="\033[1;93m"
  OKC="\033[1;97m"
  FAILC="\033[1;31m"
  NORMC="\033[0m"
else
  ERRC=""
  WARNC=""
  OKC=""
  FAILC=""
  NORMC=""
fi

# Let's test if we do not have any conflicting switches first
if [ $APPSONLY -eq 1 ]; then
  CHECKCONN=0
  if [ $USEINIT -eq 1 ]; then
    echo "Switch --use-init can't be used with --apps-only. It will be silently ignored"
  elif [ $START -eq 0 ]; then
    echo "Switch --donot-start can't be used with --apps-only. It will be silently ignored"
  fi
fi

if [ $PERMSONLY -eq 1 ]; then
  CHECKCONN=0
  if [ $USEINIT -eq 1 ]; then
    echo "Switch --use-init can't be used with --set-perms. It will be silently ignored"
  elif [ $START -eq 0 ]; then
    echo "Switch --donot-start can't be used with --set-perms. It will be silently ignored"
  fi
fi

check_splunkhome(){
  # Check if Splunk UF/HF is already installed
  echo -n "Existing Splunk installations: "
  SPLUNKD_RUNNING=`for PID in $(pidof splunkd); do ls -l /proc/$PID/exe; done | grep -m1 "bin/splunkd" | sed 's/^.*-> //'`
  if [ -d "/opt/splunkforwarder/bin" ]; then
      if [ $APPSONLY -eq 0 ] && [ $PERMSONLY -eq 0 ]; then
        echo -e "${ERRC}ERROR$NORMC: Splunk Universal Forwarder installation found. Please check with ICI Tools if events can be found in Splunk Cloud."
        DOEXIT=2
        ERRSSUM="$ERRSSUM\n  *  Splunk instance found"
      else
        echo -e "${OKC}OK: Found Splunk instance in $SPLUNK_HOME$NORMC"
      fi
  elif [ -d "/opt/splunk/bin" ]; then
      if [ $APPSONLY -eq 0 ] && [ $PERMSONLY -eq 0 ]; then
        echo -e "${ERRC}ERROR$NORMC: Splunk Enterprise installation found. Please check with ICI Tools if events can be found in Splunk Cloud."
        DOEXIT=2
        ERRSSUM="$ERRSSUM\n  *  Splunk instance found"
      else
        echo -e "${OKC}OK: Found Splunk instance in $SPLUNK_HOME$NORMC"
      fi
  elif [ -n "$SPLUNKD_RUNNING" ]; then
      SPLUNK_HOME=`echo $SPLUNKD_RUNNING | sed 's/\/bin.*//'`
      if [ $APPSONLY -eq 0 ] && [ $PERMSONLY -eq 0 ]; then
        echo -e "${ERRC}ERROR$NORMC: A Splunk instance found at $SPLUNKD_RUNNING. Please check with ICI Tools team how to proceed further."
        DOEXIT=2
        ERRSSUM="$ERRSSUM\n  *  Splunk instance found"
      else
        echo -e "${OKC}OK: Found Splunk instance in $SPLUNK_HOME$NORMC"
      fi
  else
      if [ $APPSONLY -eq 0 ] && [ $PERMSONLY -eq 0 ]; then
        echo -e "${OKC}OK$NORMC"
      else
        echo -e "${ERRC}ERROR$NORMC: Apps update or permissions update requested, but no Splunk instance was found!"
        DOEXIT=2
        ERRSSUM="$ERRSSUM\n  *  No Splunk instance found"
      fi
  fi

}

check_splunkver(){
  SPLVER=`grep VERSION $SPLUNK_HOME/etc/splunk.version | cut -d = -f2`
  OKSPLUNK=`echo "$SPLVER" | egrep "(^8\.[1-9]|^9\.|^[1-9][0-9]{1,})"`
  if [ -z "$OKSPLUNK" ]; then
    echo -e "${ERRC}ERROR$NORMC: You're running unsupported Splunk version. You need to have version 8.1 or higher, but $SPLVER found."
    DOEXIT=2
    ERRSSUM="$ERRSSUM\n  *  Unsupported Splunk version"
  fi
}

# Warnings when legacy ArcSight-related config was found.
warn_audit2syslog() {
    echo "**********************************************************************************************"
    echo -e "${WARNC}WARNING:$NORMC Audit daemon is configured to send events to local syslog in parallel with audit.log!"
    echo "This is not enabled by default, so it had to be enabled in the past for a purpose."
    echo "If it was enabled because of previous integration with  ArcSight, it's not needed anymore."
    echo "Please consider to disable this configuration to prevent duplicated events in Splunk."
    echo
    echo "Edit file /etc/audisp/plugins.d/syslog.conf"
    echo
    echo "Change 'active = yes' to 'active = no'"
    echo
    echo "Restart auditd service by issuing: service auditd restart"
    echo "**********************************************************************************************"
}

warn_rsyslog2vips() {
  #  readarray -t RSLINES <<<"$ARCON"
    echo "**********************************************************************************************"
    echo -e "${WARNC}WARNING:$NORMC It seems Rsyslog daemon is still configured ot send events to ArcSight!"
    echo "Please consider to disable this configuration to prevent duplicated events in Splunk."
    echo
    echo "This line was found in Rsyslog configuration:"
    echo
  #  for LINE in "${RSLINES[@]}"
  #    do
  #      echo "$LINE"
  #  done
    echo "$ARCON"
    echo
    echo "Please remove or comment out this line in Rsyslog config and restart the service:"
    echo
    echo "service rsyslog restart"
    echo "**********************************************************************************************"
}

do_phase1_tests(){
  # Let's do some preflight checks
  echo "***********************************************"
  echo "Starting Accenture's Splunk installer for Linux"
  echo "***********************************************"

  if [ $APPSONLY -eq 1 ] || [ $PERMSONLY -eq 1 ]; then
    echo
    echo -e "${OKC}Notice: Running in update mode only.$NORMC"
  fi

  if [ $CHECKONLY -eq 1 ]; then
    echo
    echo -e "${WARNC}Check-only option specified. Dry run only! Other switches are ignored.$NORMC"
  fi

  echo
  echo "Phase 1: Running pre-flight checks."
  echo
  echo "Inspecting environment..."
  echo

  # Check if this is 64bit architecture
  ARCH=`uname -m`
  # IP address based on default route
  IPADDR=`ip -o route get to 8.8.8.8 2>/dev/null | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`
  # All IP addressed found
  IPADDR_ALL=`hostname -I 2>/dev/null`
  IPADDR_ALL2=`hostname -i 2>/dev/null`
  # Check if system uses JournalD
  JOURNALD=`pidof systemd-journald`
  # Is there AuditD already running?
  AUDITD=`pidof auditd`
  # Find current Splunk UF package version
  #BNDLVER=$(basename $(dirname $(realpath $0)))
  BNDLVER=`basename $(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)`
  # Get vesrion and release details
  ACNVERSION=`ls -1 splunk*.tgz 2>/dev/null | tail -n1 | cut -d \- -f2`
  ACNRELEASE=`cat release | head -n1`
  # Hostname detection
  HOSTNAME_SHORT=`hostname -s`
  HOSTNAME_FQDN=`hostname -f 2>/dev/null`
  # Check if machine is using SystemD or SysV init (or similar)
  INIT=`ps -p 1 | grep 1 | awk {' print $4 '}`
  # Who executed this script
  USERID=`id -u`
  # Where we are at the moment
  RUNPATH="`dirname \"$0\"`"
  # is good to have a timesync daemon
  NTP=`pidof ntpd`
  CHRONY=`pidof chronyd`
  TIMESYNC=`pidof systemd-timesyncd`
  # Inspect /var/log because of ACL support
  LOGMOUNT=`df -P /var/log | tail -n 1 | awk {' print $6 '}`
  LOGDEV=`df /var/log | tail -n 1 | awk {' print $1 '}`
  LOGFS=`mount | grep $LOGDEV | grep " $LOGMOUNT " | awk {' print $5 '}`
  # Syslog events used to be forwarded to regional syslog VIPs in ArcSight ages. This is no longer needed or even required.
  ARCON=`egrep "170.251.160.[1-6](\"|:|$| )|170.251.68.[1-6](\"|:|$| )|170.252.35.19[3-8](\"|:|$| )|170.248.140.[1-6](\"|:|$| )" /etc/rsyslog.conf /etc/rsyslog.d/* 2>/dev/null | grep -v ":#"`
  # Check shell
  MYSHELL=`env | grep SHELL | cut -d = -f2`
  # search for Splunk tarballs
  SPLTGZ=`ls -1 $INSTANCE_TYPE-*.tgz 2>/dev/null`
  # Summary of errors found
  ERRSSUM=""

  # BASH-provided 'which' command doesn't work properly
  which which 2>&1 1>/dev/null
  if [ $? -ne 0 ]; then
    echo "BASH-provided 'which' command found, trying another method."
    NC=`whereis -b nc | awk {' print $2 '} 2>/dev/null`
    NSLOOKUP=`whereis -b nslookup | awk {' print $2 '} 2>/dev/null`
    DIG=`whereis -b dig | awk {' print $2 '} 2>/dev/null`
    HOSTDNS=`whereis -b host | awk {' print $2 '} 2>/dev/null`
    SETFACL=`whereis -b setfacl | awk {' print $2 '} 2>/dev/null`
    GUNZIP=`whereis -b gunzip | awk {' print $2 '} 2>/dev/null`
    TAR=`whereis -b tar | awk {' print $2 '} 2>/dev/null`
    SS=`whereis -b ss | awk {' print $2 '} 2>/dev/null`
    CURL=`whereis -b curl | awk {' print $2 '} 2>/dev/null`
  else
    NC=`which nc 2>/dev/null`
    NSLOOKUP=`which nslookup 2>/dev/null`
    DIG=`which dig 2>/dev/null`
    HOSTDNS=`which host 2>/dev/null`
    SETFACL=`which setfacl 2>/dev/null`
    GUNZIP=`which gunzip 2>/dev/null`
    TAR=`which tar 2>/dev/null`
    SS=`which ss 2>/dev/null`
    CURL=`which curl 2>/dev/null`
  fi

  # Let's detect OS version
  if [ -f /etc/os-release ]; then
    OSVER="$(grep -m1 ^NAME= /etc/os-release | cut -d \" -f2 | sed 's/ /_/g')_$(grep -m1 ^VERSION= /etc/os-release | cut -d \" -f2 | sed 's/ /_/g')"
  elif [ -f /etc/lsb-release ]; then
    OSVER=`grep -m1 ^DISTRIB_DESCRIPTION /etc/lsb-release | cut -d = -f2 | tr -d \"`
  elif [ -f /etc/redhat-release ]; then
    OSVER=`head -n1 /etc/redhat-release | tr -d \"`
  elif [ -f /etc/debian_version ]; then
    OSVER="Debian "`head -n1 /etc/debian_version | tr -d \"tr -d \"`
  elif [ -f /etc/SUSE-brand ]; then
    OSVER="$(head -n1 /etc/SUSE-brand | tr -d '\n')_$(grep -m1 ^VERSION /etc/SUSE-brand | cut -d = -f 2 | tr -d ' ')"
  fi

  # search domains could be useful if FQDN hostname is not defined
  if [ -f /etc/resolv.conf ]; then
    SEARCH_DOMAINS=`cat /etc/resolv.conf | grep ^search | sed 's/search //'`
  fi

  # AuditD used to be configured to log to local syslog too in order to forward these events to syslog VIPs. We do not want this anymore.
  if [ -f /etc/audisp/plugins.d/syslog.conf ]; then
    AU2S=`grep active /etc/audisp/plugins.d/syslog.conf | grep -c yes`
  else
    AU2S=0
  fi
  DOEXIT=0

  # Check architecture to be aarch64
  echo -n "Verifying $SPLUNK_ARCH OS architecture: "
  if [ "$ARCH" != "$SPLUNK_ARCH" ]; then
     echo -e "${ERRC}ERROR$NORMC: $ARCH is not supported by this Splunk package."
     DOEXIT=1
     ERRSSUM="$ERRSSUM\n  *  Unsupported architecture"
  else
     echo -e "${OKC}OK$NORMC"
  fi

  # Find splunk home
  check_splunkhome

  # Check installer bundle version
  echo -n "Splunk installer bundle version: "
  if [ -z "$BNDLVER" ]; then
    echo -e "${WARNC}Warning$NORMC: unknown"
  else
    echo -e "$OKC$BNDLVER$NORMC"
  fi

  # Package details
  if [ -n "$ACNVERSION" ] && [ -n "$ACNRELEASE" ]; then
    echo -e "Splunk package version: $OKC$ACNVERSION$ACNRELEASE$NORMC"
  fi

  # Check Splunk package
  if [ ${#SPLTGZ} -eq 0 ]; then
    echo -e "${FAILC}ERROR$NORMC No Splunk TGZ package found. Please make sure You have respective TGZ in local folder and valid INSTANCE_TYPE is set in splunk.config."
    DOEXIT=1
    ERRSSUM="$ERRSSUM\n  *  Package is missing Splunk binary tarball (*.tgz)"
  elif [ $(echo "$SPLTGZ" | wc -l) -gt 1 ]; then
    echo -e "${FAILC}ERROR$NORMC Multiple Splunk TGZ packages detected. Make sure only one is there:"
    echo "$SPLTGZ"
    DOEXIT=1
    ERRSSUM="$ERRSSUM\n  *  Your package contains multiple Splunk tarballs. It's not clear which should be installed."
  else
    echo "Detected vendor's package: $SPLTGZ"
  fi

  # Check if server runs Auditd
  echo -n "AuditD is running: "
  if [ -z "$AUDITD" ]; then
    echo -e "${ERRC}ERROR$NORMC: Auditd is not running. This is mandatory requirement. Kindly install Auditd from your package repository."
    DOEXIT=1
    ERRSSUM="$ERRSSUM\n  *  AuditD is not running"
  else
    echo -e "${OKC}OK$NORMC"
    NEWAUDIT=`auditctl -v | egrep "version (2\.[6-9]|[3-9]\.|[1-9][0-9]{1,})"`
  fi

  # Check OS version
  echo -n "OS Version: "
  if [ -z "$OSVER" ]; then
    OSVER="unknown"
    echo -e "${WARNC}Warning$NORMC: $OSVER"
  else
      echo -e "$OKC$OSVER$NORMC"
  fi

  # Check if script is executed under root account
  echo -n "Script executed as root: "
  if [ "$USERID" != "0" ]; then
     echo -e "${ERRC}ERROR$NORMC: This script must be run as root!"
     DOEXIT=1
     ERRSSUM="$ERRSSUM\n  *  Script not running as root"
  else
    echo -e "${OKC}OK$NORMC"
    # Check access to /opt
    echo -n "Testing access of non-privileged user to /opt: "
    su -s /bin/bash -c "ls /opt" nobody >/dev/null 2>&1
    if [ "$?" -eq 0 ]; then
      echo -e "${OKC}success.$NORMC"
    else
      echo -e "${WARNC}Warning$NORMC: Splunk user will likely not be able to access files in /opt and thus unable to work. Please check permissions."
    fi
  fi

  # Find out system UUID
  echo -n "Machine ID: "
  if [ -f /etc/machine-id ]; then
    UUID=`cat /etc/machine-id`
    echo -e "$OKC$UUID$NORMC"
  else
    UUID=`head -n20 /dev/urandom | tr -dc 'a-f0-9' | fold -w ${1:-32} | head -n 1`
    echo -e "${WARNC}Warning$NORMC: UUID was not found. Installer generated a new one: $UUID"
  fi

  # Check system init
  if [ ! -z "$INIT" ]; then
     echo -e "System init: $OKC$INIT$NORMC"
  else
    INIT="undefined"
  fi

  # Check JournalD
  if [ ! -z "$JOURNALD" ]; then
     echo -e "System logger: ${OKC}JournalD$NORMC"
     LOGGER="journald"
  else
     echo -e "System logger: ${OKC}syslog$NORMC"
     LOGGER="syslog"
  fi

  # Grab system's primary IP (based on default route)
  echo -n "System primary IP Address: "
  if [ -z "$IPADDR" ]; then
     IPADDR="unknown"
     echo -e "${WARNC}Warning$NORMC: System seems to have no connectivity to Internet."
  else
     echo -e "$OKC$IPADDR$NORMC"
  fi

  # List all available IPs
  echo -n "All IP Addresses: "
  if [ -n "$IPADDR_ALL" ]; then
     echo -e "$OKC$IPADDR_ALL$NORMC"
  elif [ -n "$IPADDR_ALL2" ]; then
     IPADDR_ALL=$IPADDR_ALL2
     echo -e "$OKC$IPADDR_ALL$NORMC"
  else
     echo -e "${WARNC}Warning$NORMC: System seems to have no valid IP addresses assigned or interface(s) are not up."
     IPADDR_ALL="undefined"
  fi

  # Find hostname
  echo -n "System hostname: "
  if [ ! -z "$HOSTNAME_FQDN" ] && [ "$HOSTNAME_FQDN" != "$HOSTNAME_SHORT" ]; then
     echo -e "$OKC$HOSTNAME_FQDN$NORMC"
  elif
     [ ! -z "$HOSTNAME_SHORT" ]; then
     echo -e "$OKC$HOSTNAME_SHORT$NORMC"
     HOSTNAME_FQDN="$HOSTNAME_SHORT"
  else
     HOSTNAME_FQDN="undefined"
     HOSTNAME_SHORT="undefined"
     echo -e "${WARNC}Warning$NORMC: $HOSTNAME_SHORT"
  fi

  # Check local search domains
  if [ ! -z "$SEARCH_DOMAINS" ]; then
     echo -e "Search domains: $OKC$SEARCH_DOMAINS$NORMC"
  else
    SEARCH_DOMAINS="undefined"
  fi

  # Test DNS and connectivity to Splunk Cloud
  echo -n "Testing Splunk Cloud reachability: "
  if [ $CHECKCONN -eq 1 ]; then
    if [ -z "$NC" ]; then
        echo -e "${WARNC}Warning$NORMC: nc is not available, unable to test. Skipping..."
      else
        UP=0
        DOWN=0
        if [ "$HOSTDNS" ]; then
          host -4 inputs1.accenture.splunkcloud.com 2>&1 1>/dev/null
          if [ $? -ne 0 ]; then
            echo -e "${WARNC}Warning$NORMC: DNS resolver failed. Skipping further checks..."
          else
            for IP in `for i in $(seq 1 15); do host -4 inputs$i\.accenture.splunkcloud.com | cut -d " " -f4; done | sort | uniq`; do
              nc -z -w2 $IP 9997 >/dev/null && UP=$((UP+1)) || DOWN=$((DOWN+1))
            done
            if [ $UP -gt 0 ]; then
              echo -e "${OKC}OK$NORMC: Splunk destinations reachable: $UP unreachable: $DOWN"
            else
              echo -e "${WARNC}Warning$NORMC: None of Splunk Cloud endpoints is reachable over port TCP/9997"
            fi
          fi
        elif [ "$NSLOOKUP" ]; then
          nslookup inputs1.accenture.splunkcloud.com 2>&1 1>/dev/null
          if [ $? -ne 0 ]; then
            echo -e "${WARNC}Warning$NORMC: DNS resolver failed. Skipping further checks..."
          else
            for IP in `for i in $(seq 1 15); do nslookup inputs$i\.accenture.splunkcloud.com | grep "Address: [0-9]" | cut -d " " -f2; done | sort | uniq`; do
              nc -z -w2 $IP 9997 >/dev/null && UP=$((UP+1)) || DOWN=$((DOWN+1))
            done
            if [ $UP -gt 0 ]; then
              echo -e "${OKC}OK$NORMC: Splunk destinations reachable: $UP unreachable: $DOWN"
            else
              echo -e "${WARNC}Warning$NORMC: None of Splunk Cloud endpoint is reachable over port TCP/9997"
            fi
          fi
        elif [ "$DIG" ]; then
          dig inputs1.accenture.splunkcloud.com +short 2>&1 1>/dev/null
          if [ $? -ne 0 ]; then
            echo -e "${WARNC}Warning$NORMC: DNS resolver failed. Skipping further checks..."
          else
            for IP in `for i in $(seq 1 15); do dig inputs$i\.accenture.splunkcloud.com +short; done | sort | uniq`; do
              nc -z -w2 $IP 9997 >/dev/null && UP=$((UP+1)) || DOWN=$((DOWN+1))
            done
            if [ $UP -gt 0 ]; then
              echo -e "${OKC}OK$NORMC: Splunk destinations reachable: $UP unreachable: $DOWN"
            else
              echo -e "${WARNC}Warning$NORMC: None of Splunk Cloud endpoint is reachable over port TCP/9997"
            fi
          fi
        else
          echo -e "${WARNC}Warning$NORMC: No tool to check DNS found, skipping..."
        fi
    fi
  else
    echo "Skipped because of --skip-portcheck switch"
  fi


  # Check if script is executed from installer's home directory
  echo -n "Executed from installer's directory: "
  if [ "$RUNPATH" != "." ]; then
    echo -e "${ERRC}ERROR$NORMC: You have to execute installer script from installer's directory!"
    DOEXIT=1
    ERRSSUM="$ERRSSUM\n  *  Script executed from other than script-home directory"
  else
    echo -e "${OKC}OK$NORMC"
  fi

  # Check if server runs NTP
  echo -n "Checking if a timesync daemon is running: "
  if [ -n "$NTP" ]; then
    echo -e "${OKC}OK$NORMC"
    HASNTP="true"
  elif [ -n "$CHRONY" ]; then
    echo -e "${OKC}OK$NORMC"
    HASNTP="true"
  elif [ -n "$TIMESYNC" ]; then
    echo -e "${OKC}OK$NORMC"
    HASNTP="true"
  else
    echo -e "${WARNC}Warning$NORMC: Network time protocol daemon is not running. Consider to install and configure it to keep system time accurate."
    HASNTP="false"
  fi

  # Auditsp configured to mirror events to syslog
  echo -n "Checking if Audisp syslog plugin is disabled: "
  if [ $AU2S -ne 0 ]; then
    echo -e "${WARNC}Warning$NORMC: Audisp is configured to duplicate audit events to local syslog. See notes below."
    AUDITD2SYSLOG="true"
  else
    AUDITD2SYSLOG="false"
    echo -e "${OKC}OK$NORMC"
  fi

  # Rsyslog configured to forward events to legacy syslog VIPS
  echo -n "Checking if Rsyslog is not forwarding to legacy SIEM: "
  if [ ! -z "$ARCON" ]; then
    RSYSLOG2VIPS="true"
    echo -e "${WARNC}Warning$NORMC: Some legacy forwarding to ArcSight VIPs found. See notes below."
  else
    RSYSLOG2VIPS="false"
    echo -e "${OKC}OK$NORMC"
  fi

  echo
  echo "Checking dependencies..."
  echo

  # Check if setfacl is installed
  echo -n "Checking 'setfacl' command: "
  if [ -z "$SETFACL" ]; then
    echo -e "${ERRC}ERROR$NORMC: setfacl utility is missing. Kindly install setfacl from your package repository."
    DOEXIT=1
    ERRSSUM="$ERRSSUM\n  *  setfalc command is missing"
  else
      echo -e "${OKC}OK$NORMC"
  fi

  # Check if tar is installed
  echo -n "Checking 'tar' command: "
  if [ -z "$TAR" ]; then
    echo -e "${ERRC}ERROR$NORMC: tar is missing. Kindly install Tar from your package repository."
    DOEXIT=1
    ERRSSUM="$ERRSSUM\n  *  tar command is missing"
  else
      echo -e "${OKC}OK$NORMC"
  fi

  # Check if GZip is installed
  echo -n "Checking 'gunzip' command: "
  if [ -z "$GUNZIP" ]; then
    echo -e "${ERRC}ERROR$NORMC: gunzip is missing. Kindly install Gunzip from your package repository."
    DOEXIT=1
    ERRSSUM="$ERRSSUM\n  *  gunzip command is missing"
  else
      echo -e "${OKC}OK$NORMC"
  fi

  # Check if curl is installed
  echo -n "Checking 'curl' command: "
  if [ -z "$CURL" ]; then
    echo -e "${ERRC}ERROR$NORMC: curl is missing. Kindly install curl from your package repository."
    DOEXIT=1
    ERRSSUM="$ERRSSUM\n  *  curl command is missing"
  else
      echo -e "${OKC}OK$NORMC"
  fi

  # Check if ss is installed and 8089 port is not in use
  if [ -n "$SS" ]; then
    if [ $APPSONLY -ne 1 ] && [ $PERMSONLY -ne 1 ]; then
      PORTOK=`ss -lnt | grep ":8089"`
      echo -n "Checking port 8089 is not in use: "
      if [ -n "$PORTOK" ]; then
        PROCPORT=`ss -lpnt | grep ":8089" | cut -d \" -f 2`
        echo -e "${ERRC}ERROR$NORMC: Port is in use by $PROCPORT. Please check with IS Tools team how to proceed."
        DOEXIT=1
        ERRSSUM="$ERRSSUM\n  *  Port TCP/8089 already in use"
      else
        echo -e "${OKC}OK$NORMC"
      fi
    fi
  else
      echo -e "Checking 'ss' command: ${WARNC}Warning$NORMC: ss is missing. Please consider to install ss or netstat."
  fi


  # Check if ACL is supported on /var/log filesystem
  echo
  echo "Examining /var/log..."
  echo
  echo -e "Mount point: $OKC$LOGMOUNT$NORMC"
  echo -e "Device: $OKC$LOGDEV$NORMC"
  echo -e "Filesystem: $OKC$LOGFS$NORMC"

  case $LOGFS in
      ext3|ext4)
      # check if not explicitly disabled
      if [ "$(mount | grep " $LOGMOUNT " | grep noacl)" ]; then
        FSACL="${ERRC}ERROR$NORMC: missing"
        DOEXIT=1
        ERRSSUM="$ERRSSUM\n  *  ACL is not supported for /var/log"
      # check if in default or in fstab
      elif [ "$(tune2fs -l $LOGDEV | grep "Default mount" | grep " acl")" ]; then
        FSACL="${OKC}OK$NORMC"
      elif [ "$(mount | grep " $LOGMOUNT " | grep acl)" ]; then
        FSACL="${OKC}OK$NORMC"
      elif [ "$(grep -m1 "^$LOGDEV" /etc/fstab | grep acl)" ]; then
        FSACL="${OKC}OK$NORMC"
      elif [ "$(LOGBLK=`blkid -o export $LOGDEV | grep ^UUID`; grep -m1 "^$LOGBLK" /etc/fstab | grep acl)" ]; then
        FSACL="${OKC}OK$NORMC"
      # might be silently/implicitely enabled even so
      else
        FSACL="${WARNC}Warning$NORMC: unknown. Will try to continue even so."
      fi
      ;;
      btrfs)
      if [ "$(mount | grep " $LOGMOUNT " | grep noacl)" ]; then
        FSACL="${ERRC}ERROR$NORMC: missing"
        DOEXIT=1
        ERRSSUM="$ERRSSUM\n  *  ACL is not supported for /var/log"
      else
        FSACL="${OKC}OK$NORMC"
      fi
      ;;
      xfs)
      FSACL="${OKC}OK$NORMC"
      ;;
      *)
      FSACL="${WARNC}Warning$NORMC: unknown. Will try to continue even so."
      ;;
  esac

  echo -e "Filesystem ACL Support: $FSACL"
}

exitornot(){
  if [ $DOEXIT -ne 0 ]; then
    if [ $FORCEINST -ne 1 ]; then
      echo
      echo -e "${WARNC}There were errors found preventing Splunk UF installer to continue.\nPlease fix errors shown above in red and try again.\nWarnings can be ignored, but it's recommended to fix those as well.$NORMC"
      echo
      echo -e "Summary of errors found:\n$ERRSSUM"
      echo
      if [ "$AUDITD2SYSLOG" = "true" ]; then
        warn_audit2syslog
      fi
      if [ "$RSYSLOG2VIPS" = "true" ]; then
        warn_rsyslog2vips
      fi
      exit $DOEXIT
    else
      echo
      echo -e "${WARNC}There were errors found, but installer will continue because of --force-install switch.\nPlease note installation may fail or installed agent may not work as expected.$NORMC"
      echo
      echo -e "Summary of errors found:\n$ERRSSUM"
      echo
    fi
  else
    echo
    echo "No critical error found. Continuing with installation."
    echo
  fi

  if [ $CHECKONLY -eq 1 ]; then
    echo
    echo -e "No critical errors found, but exiting because of --check-only switch."
    echo
    if [ "$AUDITD2SYSLOG" = "true" ]; then
      warn_audit2syslog
    fi
    if [ "$RSYSLOG2VIPS" = "true" ]; then
      warn_rsyslog2vips
    fi
    exit 0
  fi
}

start_phase2_install(){
  echo "Phase 2: Starting installation."
  echo

  # Define and initialize error log file
  ERRLOGGER="install-err.log"
  echo "$(date --rfc-3339=seconds) ERRORLOG" > $ERRLOGGER
  # log all errors from phase 1 when forced to continue
  if [ -n "$ERRSSUM" ]; then
    echo -e "Phase 1 errors found:$ERRSSUM" >> $ERRLOGGER
  fi
}

start_phase2_update(){
  echo "Phase 2: Starting update."
  echo
  # Define and initialize error log file
  ERRLOGGER="update-err.log"
  echo "$(date --rfc-3339=seconds) ERRORLOG" > $ERRLOGGER
  # log all errors from phase 1 when forced to continue
  if [ -n "$ERRSSUM" ]; then
    echo -e "Phase 1 errors found:$ERRSSUM" >> $ERRLOGGER
  fi

  DATE=`date "+%Y%m%d"`
  LOG_PATH="$SPLUNK_HOME/var/log/installer"
  log_filename="${DATE}-uf-appupdate.log"
  LOG_FILE="${LOG_PATH}/${log_filename}"

# Check if the installer log path exists
# If not, make path
  if [ ! -d $LOG_PATH ]
  then
        mkdir -p $LOG_PATH
  fi
  touch $LOG_FILE
  chown splunk:splunk $LOG_PATH -R
}

add_user() {
# Add Splunk User
  echo -n "Creating user account for Splunk..."
  useradd -d $SPLUNK_HOME -m -s /bin/bash -p '*' -c "Splunk system account" --system --user-group splunk 2>>$ERRLOGGER
  if [ $? -eq 0 ]; then
    echo -e "${OKC}success.$NORMC"
  else
    echo -e "${FAILC}failed.$NORMC"
  fi
}

# Install Splunk
install_splunk() {
  echo -n "Installing Splunk..."
  tar -xf $SPLTGZ -C /opt 2>>$ERRLOGGER
  if [ $? -eq 0 ]; then
    echo -e "${OKC}success.$NORMC"
  else
    echo -e "${FAILC}failed.$NORMC"
    echo
    echo "Unable to continue with installation. Please check $ERRLOGGER log for details about the error."
    exit 1
  fi
}

# Initialize logfile name
init_logfile(){
  DATE=`date "+%Y%m%d"`
  LOG_PATH="$SPLUNK_HOME/var/log/installer"
  log_filename="${DATE}-uf-install.log"
  LOG_FILE="${LOG_PATH}/${log_filename}"

# Check if the installer log path exists
# If not, make path
  if [ ! -d $LOG_PATH ]
  then
        mkdir -p $LOG_PATH
  fi
  touch $LOG_FILE
  chown splunk:splunk $LOG_PATH -R
}

# Do some cleanup of old apps
# Some Splunk apps names changed, so this is to remove old ones
clean_apps(){
if [ -f 000_accenture_outputs_dev.tar ] && [ -d "$SPLUNK_HOME/etc/apps/000_accenture_dev_outputs" ]; then
  rm -rf $SPLUNK_HOME/etc/apps/000_accenture_dev_outputs 2>/dev/null
fi
if [ -f 000_accenture_linux_is_dev.tar ] && [ -d "$SPLUNK_HOME/etc/apps/000_accenture_dev_linux_is" ]; then
  rm -rf $SPLUNK_HOME/etc/apps/000_accenture_dev_linux_is 2>/dev/null
fi
if [ -f 000_installer_monitor_dev.tar ] && [ -d "$SPLUNK_HOME/etc/apps/000_installer_monitor" ]; then
  rm -rf $SPLUNK_HOME/etc/apps/000_installer_monitor 2>/dev/null
fi
if [ -f 000_accenture_outputs_prod.tar ] && [ -d "$SPLUNK_HOME/etc/apps/000_accenture_prod_outputs" ]; then
  rm -rf $SPLUNK_HOME/etc/apps/000_accenture_prod_outputs 2>/dev/null
fi
}

# Install apps and write to log file
# Note: all *.tar files are confidered to be an app
install_apps(){
  APPOK=""
  APPFAIL=""
  for APP in `ls *.tar`; do
    echo -n "Installing application $APP..."
    tar -xf $APP -C $SPLUNK_HOME/etc/apps 2>>$ERRLOGGER
    if [ $? -eq 0 ]; then
      echo -e "${OKC}success.$NORMC"
      APPOK="$APPOK$APP#"
    else
      echo -e "${FAILC}failed.$NORMC"
      APPFAIL="$APPFAIL$APP#"
    fi
  done
  if [ -z "$APPOK" ]; then
    APPOK="none"
  fi

  if [ -z "$APPFAILED" ]; then
    APPFAILED="none"
  fi

# Set Splunk user permissions
  chown -R splunk:splunk $SPLUNK_HOME/etc/apps 2>>$ERRLOGGER
  # make sure IS scripts are executable
  if [ -d "$SPLUNK_HOME/etc/apps/accenture_linux_is/bin" ]; then
    chmod 755 $SPLUNK_HOME/etc/apps/accenture_linux_is/bin/*.sh 2>>$ERRLOGGER
  elif [ -d "$SPLUNK_HOME/etc/apps/accenture_linux_is_dev/bin" ]; then
    chmod 755 $SPLUNK_HOME/etc/apps/accenture_linux_is_dev/bin/*.sh 2>>$ERRLOGGER
  fi
}

configure_uf(){
# Set Splunk user permissions
  chown -R splunk:splunk $SPLUNK_HOME 2>>$ERRLOGGER
}

# grant filesystem permissions & configure auditd
set_permissions() {
  unalias mv 2>/dev/null
  unalias cp 2>/dev/null
  unalias rm 2>/dev/null
  DATETIME=`date "+%Y%m%d%H%M%S"`
  echo "Adding splunk user to adm group"
  usermod -a -G adm splunk 2>/dev/null

  if [ ! -z "$JOURNALD" ]; then
    echo "Adding splunk user to systemd-journal group"
    usermod -a -G systemd-journal splunk 2>/dev/null
  fi

  echo "Granting splunk user access to log files in /var/log"
  setfacl -R -m g:splunk:rX /var/log/ 2>>$ERRLOGGER
  echo "Granting splunk user access to audit.log file"
  if [ -f /etc/audit/auditd.conf-presplunk ]; then
    mv -f /etc/audit/auditd.conf-presplunk /etc/audit/auditd.conf-presplunk-$DATETIME
  fi

  # better to copy file, so we keep original auditd.conf in case anything goes wrong
  cp -f /etc/audit/auditd.conf /etc/audit/auditd.conf-presplunk

  # test and proceed only if auditd.conf-presplunk exists and is not empty
  if [ -f /etc/audit/auditd.conf-presplunk ] && [ -s /etc/audit/auditd.conf-presplunk ]; then
    if [ -n "$NEWAUDIT" ]; then
      cat /etc/audit/auditd.conf-presplunk | sed 's/log_group = root/log_group = splunk/' | sed 's/log_format = RAW/log_format = ENRICHED/' > /etc/audit/auditd.conf
    else
      cat /etc/audit/auditd.conf-presplunk | sed 's/log_group = root/log_group = splunk/' > /etc/audit/auditd.conf
    fi
  fi

  ## install Accenture rules
  # generate rules for privileged commands
  find /bin -type f -perm -04000 2>/dev/null | awk '{ printf "-a always,exit -F path=%s -F perm=x -F auid>=1000 -F auid!=unset -F key=acnis-privileged-command\n", $1 }' > audit-02.rules
  find /sbin -type f -perm -04000 2>/dev/null | awk '{ printf "-a always,exit -F path=%s -F perm=x -F auid>=1000 -F auid!=unset -F key=acnis-privileged-command\n", $1 }' >> audit-02.rules
  find /usr/bin -type f -perm -04000 2>/dev/null | awk '{ printf "-a always,exit -F path=%s -F perm=x -F auid>=1000 -F auid!=unset -F key=acnis-privileged-command\n", $1 }' >> audit-02.rules
  find /usr/sbin -type f -perm -04000 2>/dev/null | awk '{ printf "-a always,exit -F path=%s -F perm=x -F auid>=1000 -F auid!=unset -F key=acnis-privileged-command\n", $1 }' >> audit-02.rules
  filecap /bin 2>/dev/null | sed '1d' | awk '{ printf "-a always,exit -F path=%s -F perm=x -F auid>=1000 -F auid!=unset -F key=acnis-privileged-command\n", $2 }' >> audit-02.rules
  filecap /sbin 2>/dev/null | sed '1d' | awk '{ printf "-a always,exit -F path=%s -F perm=x -F auid>=1000 -F auid!=unset -F key=acnis-privileged-command\n", $2 }' >> audit-02.rules
  filecap /usr/bin 2>/dev/null | sed '1d' | awk '{ printf "-a always,exit -F path=%s -F perm=x -F auid>=1000 -F auid!=unset -F key=acnis-privileged-command\n", $2 }' >> audit-02.rules
  filecap /usr/sbin 2>/dev/null | sed '1d' | awk '{ printf "-a always,exit -F path=%s -F perm=x -F auid>=1000 -F auid!=unset -F key=acnis-privileged-command\n", $2 }' >> audit-02.rules

  # some servers may have different UID_MIN set. rules expect 1000 by default
  MINUID=`cat /etc/login.defs | grep ^UID_MIN | awk {' print $2 '}`
  if [ -n "$MINUID" ] && [ $MINUID -ne 1000 ]; then
#    cat audit-01.rules audit-02.rules audit-03.rules | sed "s/1000/$MINUID/g" > /etc/audit/rules.d/accenture-is.rules
    cat audit-01.rules audit-02.rules audit-03.rules | sed "s/1000/$MINUID/g" > accenture-is.rules
  else
#    cat audit-01.rules audit-02.rules audit-03.rules > /etc/audit/rules.d/accenture-is.rules
    cat audit-01.rules audit-02.rules audit-03.rules > accenture-is.rules
  fi

  # most of the systems have /etc/audit/rules.d to store *.rules files
  # and generate /etc/audit/audit.rules on the fly, but some old systems
  # do not have rules.d and use static /etc/audit/audit.rules
  if [ -d /etc/audit/rules.d ]; then

    # let's check '-D' parameter is set in audit
    ADELSET=`grep -c "^\-D" /etc/audit/rules.d/audit.rules`
    if [ $ADELSET -eq 0 ]; then
      echo "-D" > /etc/audit/rules.d/accenture-is.rules
      cat accenture-is.rules >> /etc/audit/rules.d/accenture-is.rules
    else
      cat accenture-is.rules > /etc/audit/rules.d/accenture-is.rules
    fi

     # make audit config editable by splunk
     chmod 660 /etc/audit/rules.d/accenture-is.rules
     chown root:splunk /etc/audit
     chown root:splunk /etc/audit/rules.d
     chown root:splunk /etc/audit/rules.d/accenture-is.rules

  else
    #seems this system does not have rules.d
    # let's take backup first
    if [ -f /etc/audit/audit.rules-presplunk ]; then
      mv -f /etc/audit/audit.rules /etc/audit/audit.rules-presplunk-$DATETIME
    fi
    cp -a /etc/audit/audit.rules /etc/audit/audit.rules-presplunk

    # let's check '-D' parameter is set in audit
    ADELSET=`grep -c "^\-D" /etc/audit/audit.rules`
    if [ $ADELSET -eq 0 ]; then
      # we have to append in this case
      echo "-D" >> /etc/audit/audit.rules
      cat accenture-is.rules >> /etc/audit/audit.rules
    else
      cat accenture-is.rules >> /etc/audit/audit.rules
    fi
  fi

  echo "Restarting AuditD to apply changes..."
  service auditd restart 2>>$ERRLOGGER
  if [ $? -eq 0 ]; then
    PERMSET="success"
    # make sure audit rules were updated
    ACNISLOADED=`auditctl -l | grep -c acnis`
    AUSTATUS=`auditctl -s | grep enabled | awk {' print $2 '}`
    if [ "$AUSTATUS" -eq 2 ]; then
      echo "AuditD rules are locked. Server reboot is needed in order to apply new rules."
    elif [ "$AUSTATUS" -eq 0 ]; then
      echo "AuditD rules are disabled, activating them..."
      auditctl -e 1 2>&1 1>/dev/null
    fi
    if [ "$ACNISLOADED" -eq 0 ] && [ "$AUSTATUS" -ne 2 ]; then
      echo "No Accenture IS rules found in runnig AuditD config. Trying to re-apply them."
      if [ `command -v augenrules` ]; then
        augenrules --load  2>&1 1>/dev/null
      else
        auditctl -R /etc/audit/audit.rules 2>&1 1>/dev/null
      fi
    fi
    ACNISRELOADED=`auditctl -l | grep -c acnis`
    if [ "$ACNISRELOADED" -gt 0 ]; then
      echo "Accenture IS AuditD rules successfully applied."
    else
      echo "Script was unable to apply AuditD rules."
    fi
  else
    PERMSET="failed"
  fi

}

restart_splunk(){
  SPLSYSTEMD=`ps aux | grep "splunkd pid" | grep -v grep | grep systemd`
  SPLRUNNING=`pidof splunkd`
  if [ -n "$SPLSYSTEMD" ]; then
    echo "Restarting Splunk service..."
    if [ "$INSTANCE_TYPE" == "splunkforwarder" ]; then
      systemctl restart SplunkForwarder.service
      sleep 10s
      systemctl status SplunkForwarder.service >/dev/null
      if [ $? -eq 0 ]; then
        SPLUNKSTART="success"
      else
        SPLUNKSTART="failed"
      fi
    elif [ "$INSTANCE_TYPE" == "splunk" ]; then
      systemctl restart Splunkd.service
      sleep 10s
      systemctl status Splunkd.service >/dev/null
      if [ $? -eq 0 ]; then
        SPLUNKSTART="success"
      else
        SPLUNKSTART="failed"
      fi
    else
      echo "failed - Unknown instance type. Please check it's properly defined in splunk.config file."
    fi
  elif  [ -n "$SPLRUNNING" ]; then
    echo "Restarting Splunk service..."
    service splunk restart
    if [ $? -eq 0 ]; then
      SPLUNKSTART="success"
    else
      SPLUNKSTART="failed"
    fi
  else
    echo "Splunk is likely not running. Skipping service restart..."
    SPLUNKSTART="skipped"
  fi
}

# Initialize Splunk
init_splunk(){
  echo "Initializing Splunk..."

  # Generate pass
  PWD=$(echo $RANDOM | md5sum 2>/dev/null | head -c 20)
  if [ -z $PWD ]; then
    PWD=$(head -n20 /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-20} | head -n 1)
  fi
  GENPWD=""
  if [ -z $PWD ]; then
    GENPWD="--gen-and-print-passwd"
  else
    # Set password
    mkdir -p $SPLUNK_HOME/etc/system/local
    echo -e "[user_info]\nUSERNAME = admin\nPASSWORD = $PWD\n" > $SPLUNK_HOME/etc/system/local/user-seed.conf
    chown splunk:splunk $SPLUNK_HOME/etc/system/local -R
  fi

  # init splunk
  su splunk -c "$SPLUNK_HOME/bin/splunk status --accept-license --no-prompt --answer-yes $GENPWD 2>&1" 2>>$ERRLOGGER
  if [ $? -eq 3 ]; then
    SPLUNKINIT="success"
  else
    SPLUNKINIT="failed"
  fi
  echo "Splunk init result: $SPLUNKINIT"
}

# Accenture IS app name
config_acnis_app(){
  ISAPP=`su -c "$SPLUNK_HOME/bin/splunk btool inputs list monitor:///var/log --debug | grep -m1 'linux_is' | cut -d ' ' -f1 | sed 's/.*000_/000_/' | cut -d '/' -f 1" splunk`
  if [ -n "$ISAPP" ]; then
    if [ ! -d $SPLUNK_HOME/etc/apps/$ISAPP/local ]; then
      mkdir $SPLUNK_HOME/etc/apps/$ISAPP/local
    fi

    if [ -f $SPLUNK_HOME/etc/apps/$ISAPP/local/inputs.conf ]; then
      mv -f $SPLUNK_HOME/etc/apps/$ISAPP/local/inputs.conf $SPLUNK_HOME/etc/apps/$ISAPP/local/inputs.conf.$DATE
    fi

    # Select event source and disable journalD if it is not in use
    if [ -z "$JOURNALD" ]; then
       echo -e "[monitor:///var/log]\ndisabled = 0\n" >> $SPLUNK_HOME/etc/apps/$ISAPP/local/inputs.conf
       echo -e "[journald://systemevents]\ndisabled = 1\n" >> $SPLUNK_HOME/etc/apps/$ISAPP/local/inputs.conf
    fi

    # Check if sslPassword is in system/local/server.conf - it's not typically, so it will be skipped likely
    if grep -m1 "^sslPassword" $SPLUNK_HOME/etc/system/local/server.conf >/dev/null; then
      echo -n "Configuring DS: "
      # archive any previous backup if exists
      if [ -f "$SPLUNK_HOME/etc/system/local/server.conf.acnisbackup" ]; then
        mv $SPLUNK_HOME/etc/system/local/server.conf.acnisbackup $SPLUNK_HOME/etc/system/local/server.conf.acnisbackup-$DATETIME
      fi
      # backup & update current server.conf
      sed -i.acnisbackup 's/^sslPassword/#sslPassword/' $SPLUNK_HOME/etc/system/local/server.conf 2>>$ERRLOGGER
      if [ $? -ne 0 ]; then
        echo "Failed: server.conf was not updated."
        DSCONFIG="failed"
      else
        echo "OK"
        DSCONFIG="success"
      fi
    fi

    chown splunk:splunk $SPLUNK_HOME/etc/apps/$ISAPP/local -R

  fi
}


config_bootstart(){
  # remove any orphan Splunk init first
  echo -n "Disabling any previous boot-start config for Sys-V init..."
  $SPLUNK_HOME/bin/splunk disable boot-start -systemd-managed 0 2>/dev/null
  echo -n "Disabling any previous boot-start config for SystemD..."
  $SPLUNK_HOME/bin/splunk disable boot-start -systemd-managed 1 2>/dev/null

  # Enable bootstart - use systemd by default, but fallback to init if required or requested
  # And finally start Splunk
  echo "Configuring Splunk to start at boot."
  if [ "$INIT" = "systemd" ] && [ $USEINIT -eq 0 ] ; then
    $SPLUNK_HOME/bin/splunk enable boot-start -user splunk -systemd-managed 1 2>>$ERRLOGGER
    if [ $? -eq 0 ]; then
      SPLUNKBOOT="success"
    else
      SPLUNKBOOT="failed"
    fi
    USESSYSD="true"

    # Some cgroups2 systems come without system.slice, hence we need to fix that
    if [ ! -d /sys/fs/cgroup/memory/system.slice ] && [ -f /etc/systemd/system/SplunkForwarder.service ]; then
       echo -n "Found cgroups v2 without slices. Updating SplunkForwarder.service..."
       sed -i 's/^User/#User/' /etc/systemd/system/SplunkForwarder.service 2>>$ERRLOGGER
       sed -i 's/^ExecStartPost/#ExecStartPost/' /etc/systemd/system/SplunkForwarder.service 2>>$ERRLOGGER
       systemctl daemon-reload 2>>$ERRLOGGER
       if [ $? -eq 0 ]; then
         echo "success"
       else
         echo "failed"
      fi
    fi

    if [ $START -eq 1 ]; then
      echo "Starting Splunk..."
      if [ "$INSTANCE_TYPE" == "splunkforwarder" ]; then
        systemctl start SplunkForwarder.service 2>>$ERRLOGGER
        sleep 10s
        systemctl status SplunkForwarder.service >/dev/null
        if [ $? -eq 0 ]; then
          SPLUNKSTART="success"
        else
          SPLUNKSTART="failed"
        fi
      elif [ "$INSTANCE_TYPE" == "splunk" ]; then
        systemctl start Splunkd.service 2>>$ERRLOGGER
        sleep 10s
        systemctl status Splunkd.service >/dev/null
        if [ $? -eq 0 ]; then
          SPLUNKSTART="success"
        else
          SPLUNKSTART="failed"
        fi
      fi
    else
      echo "Skipping Splunk start because of 'donot-start' option."
      SPLUNKSTART="disabled"
    fi
  else
    $SPLUNK_HOME/bin/splunk enable boot-start -user splunk 2>>$ERRLOGGER
    if [ $? -eq 0 ]; then
      SPLUNKBOOT="success"
    else
      SPLUNKBOOT="failed"
    fi
    USESSYSD="false"
    if [ $START -eq 1 ]; then
      echo "Starting Splunk..."
      su splunk -c "$SPLUNK_HOME/bin/splunk start" 2>>$ERRLOGGER
      if [ $? -eq 0 ]; then
        SPLUNKSTART="success"
      else
        SPLUNKSTART="failed"
      fi
    else
      echo "Skipping Splunk start because of --donot-start switch"
      SPLUNKSTART="disabled"
    fi
  fi
}

get_guid(){
  # Make machine-id persistent if it does not exist
  if [ ! -f /etc/machine-id ]; then
    echo "$UUID" > $SPLUNK_HOME/machine-id
    ln -s $SPLUNK_HOME/machine-id /etc/machine-id
  fi

  # Get GUID from Splunk instance. Give up after 2 minutes
  if [ "$SPLUNKSTART" = "success" ]; then
    cnt=1
    while [ $cnt -lt 120 ]; do
      GUID=`grep guid $SPLUNK_HOME/etc/instance.cfg 2>/dev/null | awk {' print $3 '}`
      if [ -z "$GUID" ]; then
        cnt=$(( $cnt + 1 ))
        sleep 1s
      else
        cnt=120
      fi
    done
  fi
  if [ -z "$GUID" ]; then
    GUID="not_available"
  fi
}

generate_sha(){
  # SHA hashes
  for APP in `find $SPLUNK_HOME/etc/apps/ -type d -name '[0-9]*_accenture_*' -exec basename {} \;`; do
    SHA=`find $SPLUNK_HOME/etc/apps/$APP/ -type f -regextype posix-egrep -regex ".*(local|default)/.*conf" -exec md5sum {} \; | sha1sum | cut -d " " -f1`
    SHALOG="$SHALOG SHA_$APP=$SHA"
  done
}

gen_log() {
  LOGOUTPUT="$(date --rfc-3339=seconds) $HOSTNAME finished=$ENDSTATUS"
  if [ -n "$HOSTNAME_SHORT" ]; then
    LOGOUTPUT="$LOGOUTPUT hostname_short=$HOSTNAME_SHORT"
  fi
  if [ -n "$HOSTNAME_FQDN" ]; then
    LOGOUTPUT="$LOGOUTPUT hostname_fqdn=$HOSTNAME_FQDN"
  fi
  if [ -n "$SEARCH_DOMAINS" ]; then
    LOGOUTPUT="$LOGOUTPUT domains=$SEARCH_DOMAINS"
  fi
  if [ -n "$IPADDR" ]; then
    LOGOUTPUT="$LOGOUTPUT primary_ip=$IPADDR"
  fi
  if [ -n "$IPADDR_ALL" ]; then
    LOGOUTPUT="$LOGOUTPUT all_ip=$IPADDR_ALL"
  fi
  if [ -n "$OSVER" ]; then
    LOGOUTPUT="$LOGOUTPUT os_version=$OSVER"
  fi
  if [ -n "$UUID" ]; then
    LOGOUTPUT="$LOGOUTPUT UUID=$UUID"
  fi
  if [ -n "$GUID" ]; then
    LOGOUTPUT="$LOGOUTPUT GUID=$GUID"
  fi
  if [ -n "$BNDLVER" ]; then
    LOGOUTPUT="$LOGOUTPUT package_bundle=$BNDLVER"
  fi
  if [ -n "$ACNVERSION" ] && [ -n "$ACNRELEASE" ]; then
    LOGOUTPUT="$LOGOUTPUT package_version=$ACNVERSION$ACNRELEASE"
  fi
  if [ -n "$APPOK" ]; then
    LOGOUTPUT="$LOGOUTPUT apps_installed=$APPOK"
  fi
  if [ -n "$APPFAILED" ]; then
    LOGOUTPUT="$LOGOUTPUT apps_failed=$APPFAILED"
  fi
  if [ -n "$SPLUNKBOOT" ]; then
    LOGOUTPUT="$LOGOUTPUT splunk_at_boot=$SPLUNKBOOT"
  fi
  if [ -n "$SPLUNKSTART" ]; then
    LOGOUTPUT="$LOGOUTPUT splunk_started=$SPLUNKSTART"
  fi
  if [ -n "$HASNTP" ]; then
    LOGOUTPUT="$LOGOUTPUT ntp_running=$HASNTP"
  fi
  if [ -n "$PERMSET" ]; then
    LOGOUTPUT="$LOGOUTPUT permissions_set=$PERMSET"
  fi
  if [ -n "$AUDITD2SYSLOG" ]; then
    LOGOUTPUT="$LOGOUTPUT auditd_syslog=$AUDITD2SYSLOG"
  fi
  if [ -n "$RSYSLOG2VIPS" ]; then
    LOGOUTPUT="$LOGOUTPUT rsyslog_legacy=$RSYSLOG2VIPS"
  fi
  if [ -n "$INIT" ]; then
    LOGOUTPUT="$LOGOUTPUT system_init=$INIT"
  fi
  if [ -n "$USESSYSD" ]; then
    LOGOUTPUT="$LOGOUTPUT systemd_managed=$USESSYSD"
  fi
  if [ -n "$MYSHELL" ]; then
    LOGOUTPUT="$LOGOUTPUT installer_shell=$MYSHELL"
  fi
  if [ -n "$DSCONFIG" ]; then
    LOGOUTPUT="$LOGOUTPUT ds_config=$DSCONFIG"
  fi
  if [ -n "$SHALOG" ]; then
    LOGOUTPUT="$LOGOUTPUT $SHALOG"
  fi

  echo "$LOGOUTPUT" >> $LOG_FILE
}

finalize(){
# Done with installation

  FIN=`grep -v ERRORLOG $ERRLOGGER`
  if [ ! -z "$FIN" ]; then
    echo -e "${WARNC}Finished with errors.$NORMC Please share install-err.log with ICI Tools teams. Hostname: $HOSTNAME_SHORT GUID: $GUID"
    ENDSTATUS="with-errors"
    gen_log
    echo "ERRORLOG: $FIN" >> $LOG_FILE
  else
    echo -e "${OKC}Finished successfully.$NORMC Hostname: $HOSTNAME_SHORT GUID: $GUID"
    ENDSTATUS="success"
    gen_log
  fi

  if [ "$AUDITD2SYSLOG" = "true" ]; then
    warn_audit2syslog
  fi
  if [ "$RSYSLOG2VIPS" = "true" ]; then
    warn_rsyslog2vips
  fi

  if [ -n "$ACNVERSION" ] && [ -n "$ACNRELEASE" ]; then
    echo "$ACNVERSION" > $SPLUNK_HOME/etc/acnis
    touch $SPLUNK_HOME/etc/acnis.$ACNVERSION
    touch $SPLUNK_HOME/etc/acnis.$ACNVERSION$ACNRELEASE
  else
    touch $SPLUNK_HOME/etc/acnis
  fi
  echo "$INSTALL_METHOD" > $SPLUNK_HOME/etc/acnis.installer

  chown splunk:splunk $SPLUNK_HOME/etc/acnis* 2>>$ERRLOGGER

}

## Stuff specific to HF ##
get_siteid(){
  if [ -z "$SITEID" ]; then
    # Request Site ID before we start with installation
    set_siteid() {
      echo -n "Enter SOC site ID: "
      read -a SITEIDINPUT
      SITEID=${SITEIDINPUT[0]}
    }

    set_siteid

    while true; do
      echo "Site ID set to $SITEID"
      read -p "Do you want to continue? (Y/N/Q)" yn
      case $yn in
          [Yy]* ) break;;
          [Nn]* ) set_siteid;;
          [Qq]* ) exit 0;;
          * ) echo "Please answer 'y'/'Y' for yes, 'n'/'N' for no or 'q'/'Q' to exit installer.";;
      esac
    done
  fi
  echo "Using $SITEID as Site ID."
}

configure_hf(){
  # add license
  echo "Adding license"
  mkdir -p $SPLUNK_HOME/etc/licenses/enterprise
  zcat Splunk_Cloud_Enterprise_Subscription.lic.gz > $SPLUNK_HOME/etc/licenses/enterprise/Splunk_Cloud_Enterprise_Subscription.lic

  # Disable web UI
  echo "[settings]" > $SPLUNK_HOME/etc/system/local/web.conf
  echo "startwebserver = 0" >> $SPLUNK_HOME/etc/system/local/web.conf
  echo "enableSplunkWebSSL = true" >>  $SPLUNK_HOME/etc/system/local/web.conf

  # Add HF prefix to deploymentclient name
  if [ -f "$SPLUNK_HOME/etc/apps/000_accenture_ds/local/server.conf" ]; then
    if [ -n "$HOSTNAME_SHORT" ]; then
      CLIENTNAME=$HOSTNAME_SHORT
    elif [ -n "$HOSTNAME" ]; then
      CLIENTNAME=$HOSTNAME
    elif [ -n "$HOSTNAME_FQDN" ]; then
      CLIENTNAME=$HOSTNAME_FQDN
    else
      CLIENTNAME=$UUID
    fi

#    if [ -d "$SPLUNK_HOME/etc/apps/accenture_read_syslog_from_files" ]; then
#      echo -e "[deployment-client]\nclientName = HFSL-$CLIENTNAME\n" > $SPLUNK_HOME/etc/apps/000_accenture_ds/local/deploymentclient.conf
#    elif [ -d "$SPLUNK_HOME/etc/apps/accenture_read_syslog_from_files_va" ]; then
#      echo -e "[deployment-client]\nclientName = HFVA-$CLIENTNAME\n" > $SPLUNK_HOME/etc/apps/000_accenture_ds/local/deploymentclient.conf
#    fi
    if [ "$HFTYPE" == "TYPED" ]; then
      echo -e "[deployment-client]\nclientName = HFSL-$CLIENTNAME\n" > $SPLUNK_HOME/etc/apps/000_accenture_ds/local/deploymentclient.conf
    elif [ "$HFTYPE" == "VA" ]; then
      echo -e "[deployment-client]\nclientName = HFVA-$CLIENTNAME\n" > $SPLUNK_HOME/etc/apps/000_accenture_ds/local/deploymentclient.conf
    elif [ "$HFTYPE" == "AIP" ]; then
      echo -e "[deployment-client]\nclientName = HFAIP-$CLIENTNAME\n" > $SPLUNK_HOME/etc/apps/000_accenture_ds/local/deploymentclient.conf
    fi
  fi

# Set Splunk user permissions
  chown -R splunk:splunk $SPLUNK_HOME 2>>$ERRLOGGER
}

add_meta(){
# Adding meta fields
#  echo -e "heavy_forwarder=\"$HOSTNAME\"\nsite_id=\"$SITEID\"" >> $SPLUNK_HOME/etc/acnhf.cfg
  echo "_meta = heavy_forwarder::$HOSTNAME site_id::$SITEID" >> $SPLUNK_HOME/etc/system/local/inputs.conf
}

prepare_image(){
  echo -n "Splunk cleanup to work as image/template..."
  su splunk -c "$SPLUNK_HOME/bin/splunk clone-prep-clear-config 2>&1" 2>>$ERRLOGGER
  if [ $? -eq 0 ]; then
    echo "Cleanup OK"
  else
    echo "Cleanup failed"
  fi
}

# Run installation

if [ $APPSONLY -ne 1 ] && [ $PERMSONLY -ne 1 ]; then
# standard installation
  do_phase1_tests
  exitornot
  start_phase2_install
  if [ "$INSTANCE_TYPE" == "splunk" ]; then
    get_siteid
  fi
  add_user
  install_splunk
  init_logfile
  install_apps
  if [ "$INSTANCE_TYPE" == "splunk" ]; then
    configure_hf
  else
    configure_uf
  fi
  set_permissions
  init_splunk
  config_acnis_app
  if [ "$INSTANCE_TYPE" == "splunk" ]; then
    add_meta
  fi
  config_bootstart
  get_guid
  generate_sha
  if [ $IMAGE -eq 1 ]; then
    prepare_image
  fi
  finalize
elif [ $APPSONLY -eq 1 ] && [ $PERMSONLY -eq 1 ]; then
# only re-deploy apps and set permissions
  do_phase1_tests
  check_splunkver
  exitornot
  start_phase2_update
  clean_apps
  install_apps
  set_permissions
  config_acnis_app
  restart_splunk
  finalize
elif [ $APPSONLY -eq 1 ] && [ $PERMSONLY -eq 0 ]; then
# re-deploy apps
  do_phase1_tests
  check_splunkver
  exitornot
  start_phase2_update
  clean_apps
  install_apps
  config_acnis_app
  restart_splunk
  finalize
elif [ $APPSONLY -eq 0 ] && [ $PERMSONLY -eq 1 ]; then
# set permissions only
  do_phase1_tests
  exitornot
  start_phase2_update
  set_permissions
  restart_splunk
  finalize
fi
