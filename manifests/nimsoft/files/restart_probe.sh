#!/bin/sh

# Restart a nimsoft probe by name. This script only kills
# the specified probe the the controller will restart it

myself=$0
myname=`basename "$0"`

KERNEL=`uname -s`
case $KERNEL in
  SunOS)
    OSFAMILY=Solaris
    ARCH=`uname -m`
    PS=/bin/ps
    PS_ARGS=
    ;;
  Linux)
    if [ -f /etc/redhat-release ]; then
      OSFAMILY=RedHat
    elif [ -f /etc/gentoo-release ]; then
      OSFAMILY=Gentoo
    elif [ -f /etc/SuSE-release ]; then
      OSFAMILY=SLES
    fi
    PS=/bin/ps
    PS_ARGS='--no-headers --ppid'
    ;;
esac


# Step 01: Get controller pid
CONTROLLER_PID=10

# Step 02: Get a list of all probes
case $KERNEL in
  Linux)
    /bin/ps --no-headers -o pid,comm --ppid $CONTROLLER_PID


