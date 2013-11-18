#!/bin/sh

KERNEL=`uname -s`
case $KERNEL in
  Linux)
    INSTALLER=
    ;;
  SunOS)
    INSTALLER=
    ;;
esac

INSTALL_SOURCE="/stage/nimsoft/server_installation"

myself=$0
myname=`basename ${myself}`

LOGFILE=`dirname ${myself}`/logs/`echo ${myself}|sed 's:\.sh$:.log'`

log() {
  _severity=$1
  _message=$2

  if [ -t 1 ]; then
    _color_info=
    _color_warning=
    _color_fatal=
    _color_reset=
  else
    _color_info=
    _color_warning=
    _color_fatal=
    _color_reset=
  fi

  case $_severity in
    info)
      echo "${myname}: ${_color_info}${_message}${_color_reset}"
      ;;
    warning)
      echo "${myname}: ${_color_warning}${_message}${_color_reset}" 1>&2
      ;;
    fatal)
      echo "${myname}: ${_color_fatal}${_message}${_color_reset}" 1>&2
      ;;
  esac

  if [ ! -z "$LOGFILE" ]; then
    _date=`date`
    echo "${_date} ${_message}" >> ${LOGFILE}
  fi

  if [ $_severity = fatal ]; then
    exit 3
  fi
}

TMPDIR=/tmp/nimsoft_server_installation_$$
trap 'rm -f "$TMPDIR" 2>/dev/null' 0

if mkdir -m 0700 "$TMPDIR" 2>"${LOGFILE}"; then
  log info "${TMPDIR} created"
else
  log fatal "Unable to create ${TMPDIR}"
fi

if [ -f "${INSTALL_SOURCE}/${INSTALLER}" ];then
  log info "${INSTALL_SOURCE}/${INSTALLER} found"
else
  log fatal "Installer not found: ${INSTALL_SOURCE}/${INSTALLER}. Abort now"
fi

if cp "${INSTALL_SOURCE}/${INSTALLER}" "${TMPDIR}/${INSTALLER}"; then
  log info "Installation file copied into temporary directory"
else
  log fatal "Unable to copy ${INSTALL_SOURCE}/${INSTALLER} to ${TMPDIR}. Abort now"
fi

cat > "${TMPDIR}/properties" << EOF

EOF
if [ $? -eq 0 ]; then
  log info "Answerfile created"
else
  log fatal "Unable to create answerfile: ${TMPDIR}/properties. Abort now"
fi

if cd "${TMPDIR}"; then
  log info "Changed working directory to ${TMPDIR}"
else
  log fatal "Unable to change working directory to ${TMPDIR}. Abort now"
fi

if "${TMPDIR}/${INSTALLER}" >> $LOGFILE 2>&1; then
  rc=0
  log info "Installation completed"
else
  rc=$?
  log fatal "Installation failed (rc=${rc})"
fi

exit $rc
