#!/bin/sh

# Author: Stefan Schulte

# Restarts a nimsoft probe by name. This script assumes that
# we just have to kill the specified probe and the controller
# will automaticall restart it

myself=$0
myname=`basename "$0"`

PID_FILE=/opt/nimsoft/pids/nimbus-0.pids

print_usage() {
  cat << USAGE
Usage: ${myself} [PROBENAME]

Restart the specified probe. This script will kill the specified probe
and wait for its termination. It will also wait until the controller
restarts the probe.
USAGE
}

get_probe_pid() {
  _probe_name=$1
  _probe_pid=0
  _probe_status=3

  if [ -r "$PID_FILE" ]; then
    exec 5<&0 <"$PID_FILE"
    _line_no=0
    while read _line; do
      _line_no=`expr $_line_no + 1`
      case "$_line" in
        '</'*'>')
          if [ -z "$_name" ] || [ -z "$_pid" ]; then
            echo "${myname}: Unexpected end of section in line ${_line_no}. Name or command is missing" 1>&2
          else
            if [ "$_name" = "$_probe_name" ]; then
              _probe_pid=$_pid
              if [ -d /proc/${_pid} ]; then
                _probe_status=0
              else
                # Probe is dead
                _probe_status=1
              fi
            fi
          fi
          ;;
        '<'*'>')
          _name=
          _command=
          _pid=
          ;;
        *'='*)
          _key=`echo $_line | /bin/sed -n 's/^[ 	]*\([^ 	]*\)[ 	]*=[ 	]*\([^ 	]*\)[ 	]*$/\1/p'`
          _value=`echo $_line | /bin/sed -n 's/^[ 	]*\([^ 	]*\)[ 	]*=[ 	]*\([^ 	]*\)[ 	]*$/\2/p'`
          case "$_key" in
            name)
              _name=$_value
              ;;
            command)
              _command=$_value
              ;;
            pid)
              _pid=$_value
              ;;
          esac
          ;;
        *)
          echo "${myname}: Unexpected string in line ${_line_no}: ${_line}" 1>&2
          ;;
      esac
    done
    exec <&5 5<&-
  else
    _probe_status=4
  fi

  echo $_probe_pid
  return $_probe_status
}


if [ $# -ne 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  print_usage
  exit 0
fi

PROBE_NAME="$1"

# Step 01: Check the current state of the probe and make sure it is running
old_pid=`get_probe_pid "$PROBE_NAME"`
rc=$?
case "$rc" in
  0)
    echo "${myname}: Probe ${PROBE_NAME} is currently running (pid ${old_pid})"
    ;;
  1)
    echo "${myname}: Probe ${PROBE_NAME} is dead (pid ${old_pid} is not running)"
    exit 1
    ;;
  3)
    echo "${myname}: Probe ${PROBE_NAME} is not running"
    exit 3
    ;;
  4)
    echo "${myname}: Unable to read ${PID_FILE}"
    exit 4
    ;;
esac

# Step 02: Kill the probe
kill -TERM "$old_pid"

# Step 03: Wait for the probe to terminate
count=0
new_pid=`get_probe_pid "$PROBE_NAME"`
while [ "$new_pid" = "$old_pid" ] && [ $count -lt 10 ]; do
  sleep 3
  count=`expr $count + 1`
  new_pid=`get_probe_pid "$PROBE_NAME"`
done

if [ "$new_pid" = "$old_pid" ]; then
  echo "${myname}: Probe ${PROBE_NAME} is still running (pid ${old_pid}). Abort now"
  exit 12
else
  echo "${myname}: Probe ${PROBE_NAME} has been stopped"
fi

# Step 04: Wait until we have a new pid
count=0
while [ $new_pid -eq 0 ] && [ $count -lt 10 ]; do
  sleep 3
  count=`expr $count + 1`
  new_pid=`get_probe_pid "$PROBE_NAME"`
done

if [ $new_pid -eq 0 ]; then
  echo "${myname}: Probe ${PROBE_NAME} is still down and has not been restarted. Abort now"
  exit 12
else
  echo "${myname}: Probe ${PROBE_NAME} is running again (pid ${new_pid})"
fi

exit 0
