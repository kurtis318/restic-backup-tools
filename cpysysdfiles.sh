#!/bin/bash
#----------------------------------------------------------------
# Copy *.timer and *.service files to /etc/systemd/system
# and reload systemd services.

BANR='#---------------------------------------------------------'
THIS_SCRIPT=$(readlink -f "${BASH_SOURCE[0]}" )
THIS_SCRIPT_DIR=$( dirname "${THIS_SCRIPT}" )
# CFGF="${THIS_SCRIPT_DIR}/restic.cfg"

function cpyfiles() {
  local EXT=$1
  echo -e "\n${BANR}"
  echo "# Copy files with extension '${EXT}'"
  echo "${BANR}"

  SRCH="${THIS_SCRIPT_DIR}/${SYSD_PRE}*${EXT}"
  mapfile -t ITEMS < <(eval ls -1 "${SRCH}")
  for ITEM in "${ITEMS[@]}"; do
    cp "${ITEM}" /etc/systemd/system/.; RC=$?
    echo "cp ${ITEM} /etc/systemd/system/. RC=${RC}"
  done
}  # cpyfiles()

function main() {
  local CFGF=$1
  local RC=0
  
  # CFGF in script directory
  if [[ -f "${CFGF}" ]]; then
      echo "Found file='${CFGF}'"
  else
      echo "Could not find file='${CFGF}', aborting this script"ech
      exit 100
  fi

  # shellcheck disable=SC2086
  # shellcheck disable=SC2207
  OUT=($( echo "${CFGF}"|awk -F "-" '{for(i=1;i<=NF; i++){print $i}}' ))
  # shellcheck disable=SC2086
  LEN=${#OUT[@]}
  # shellcheck disable=SC2086
  if [ $LEN -eq 0 ] || [ $LEN -gt 3 ]; then
    echo "Input config file='${CFGF}' does not following naming convention"
    exit 101
  fi

  # OK to source ENVF
  # shellcheck source=/dev/null
  source "${CFGF}"

  # make sure SYSD_PRE var has a value
  if [[ -z "${SYSD_PRE}" ]]; then
    echo "Evironment variable 'SYSD_PRE' is not set. aborting script"
    exit 102
  fi

  cpyfiles ".timer"
  cpyfiles ".service"
   echo -e "\n${BANR}"
  echo "# Running: systemctl daemon-reload"
  echo "${BANR}"
  systemctl daemon-reload; RC=$?
  echo "systemctl daemon-reload; RC=${RC}"
}


# main-line code execution starts here (kind-of)
if (( UID != 0 )); then
  echo "This script must be run as root user"
  exit 1
fi
# Make sure one parameter is passed
if [ "$#" -ne 1 ]; then
  echo "Pass a restic config file as the ONLY parameter"
  exit 2
fi

main "${1}"

exit 0
