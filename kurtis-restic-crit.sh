#!/bin/bash
#----------------------------------------------------------------
# Use restic and rclone to backup critical directories
#
# This script can be called from a command line or by a systemd service.
# This script assumes the directory this script runs out of also
# include an environment file named <SHOT_DIR.cfg where SHORT_DIR is
# the name of the current sub-directory.
# This file is sourced and defines the following parameter variables:
# 
# BASE_DIR  - path to a directory containing directories to backu
# DIRS      - comma separated string of directories in BASE_DIR
# REPO      - repository string from restic init.
#             The full restic init must be executed before
#             this script is called.
# PW_FILE   - path to a password file. It should have permissions 600.
# SYSD_PRE  - prefix for systemctl queries
# 
#
# REF: Configuration and Usage of rclone (or restic) and Box
# URL: https://github.ibm.com/openclient/ocfedora/wiki/Configuration-and-Usage-of-rclone-(or-restic)-and-Box
#
# Configuration:
# 1. sudo dnf -y install restic rclone
# 2. restic init --repo sftp:kurtis@192.168.0.210:/data/restic/chloecat/kurtis
# 
# Commands:
#  sudo cp ./user-restic-crit15.timer /etc/systemd/system/.
#  sudo cp ./user-resti-crit.service /etc/systemd/system/.
#
#  sudo systemctl daemon-reload
#  sudo systemctl start -now  user-resti-crit15.timer
#  sudo systemctl enable  user-resti-crit15.timer
#
#  sudo systemctl restart  user-resti-crit15.timer
#
#  systemctl status user--resticrit15.timer
#  systemctl status user--resticrit.service
#  systemctl list-timers
#  journalctl -u user-resti-crit
#----------------------------------------------------------------

BANR='#---------------------------------------------------------'
THIS_SCRIPT=$(readlink -f "${BASH_SOURCE[0]}" )
THIS_SCRIPT_DIR=$( dirname "${THIS_SCRIPT}" )
THIS_SCRIPT_FILENAME=$( basename "${THIS_SCRIPT%.*}")

CFGF="${THIS_SCRIPT_DIR}/restic.cfg"
LOGD="${THIS_SCRIPT_DIR}/logs"
LOGF="${THIS_SCRIPT_DIR}/${THIS_SCRIPT_FILENAME}-log.txt"
if [[ -d "${LOGD}" ]]; then
   LOGF="${LOGD}/${THIS_SCRIPT_FILENAME}-log.txt"
fi

# echo -e "<CFGF=${CFGF}>"
# echo -e "<THIS_SCRIPT=${THIS_SCRIPT}>\n<THIS_SCRIPT_DIR=${THIS_SCRIPT_DIR}>"
# echo -e "<THIS_SCRIPT_FILENAME=${THIS_SCRIPT_FILENAME}>\n<LOGD=${LOGD}>"
# echo -e "<LOGF=${LOGF}>"

function check_envars() {
   local RC=0
   
   # echo "USER=${USER}"
   # echo "PWD=$(pwd)"
   # echo "Checking existence of file ${CFGF}."
   
   # CFGF must be in the local directory
   if [[ ! -f "${CFGF}" ]]; then
      echo "Cannot find file='${CFGF}', aborting this script" | tee -a "${LOGF}"
      exit 100
   fi

   # OK to source CFGF
   # shellcheck source=/dev/null
   source "${CFGF}"

   if [[ -z "${BASE_DIR}" ]]; then
      echo "Parameter 'BASE_DIR' is blank" | tee -a "${LOGF}"
      _=$((RC++))
   fi

   if [[ -z "${REPO}" ]]; then
      echo "Parameter 'REPRO' is blank" | tee -a "${LOGF}"
      _=$((RC++))
   fi

   if [[ -z "${PW_FILE}" ]]; then
      echo "Parameter 'PW_FILE' is blank" | tee -a "${LOGF}"
      _=$((RC++))
   fi

   # DIRS
   if [[ -z "${DIRS}" ]]; then
      echo "Parameter 'DIRS' is blank" | tee -a "${LOGF}"
      _=$((++RC))
   fi

   # RMT_HOST
   if [[ -z "${RMT_HOST}" ]]; then
     echo "Parameter 'RMT_HOST' is blank" | tee -a "${LOGF}"
     _=$((++RC))
   fi

   # Print program vars and terminate if errors.
   # echo "<RC=${RC}> <BASE_DIR=${BASE_DIR}> <REPO=${REPO}>"
   # echo "<PW_FILE=${PW_FILE}> <DIRS=${DIRS}> <LEN=${LEN}>"
   # echo "<SYSD_PRE=${SYSD_PRE}> <CFGF=${CFGF}>"

   if (( RC == 0 )); then
      echo "All parameters are non-blank values"
   else
      echo "There were ${RC} blank parameters. Aborting this script." | tee -a "${LOGF}"
      exit 101
   fi
   
   oldIFS=$IFS
   IFS=','
   read -r -a DIR_ARRAY <<< "$DIRS"
   IFS=$oldIFS

   # for ITEM in "${DIR_ARRAY[@]}"; do
   #    echo "$ITEM"
   # done
}  # check_envars()


function __timer()
{
   # Timer should NOT have tracing instrumentation.
   if [[ $# -eq 0 ]]; then
      date '+%s'
   else
      local stime=$1
      local etime dt ds dm dh
      etime=$(date '+%s')

      if [[ -z "$stime" ]]; then stime=$etime; fi

      dt=$((etime - stime))
      ds=$((dt % 60))
      dm=$(((dt / 60) % 60))
      dh=$((dt / 3600))
      printf 'elapsed time: %02d:%02d:%02d' $dh $dm $ds
    fi
}  # __timer()

function check_inet() {
   HN="${1}"
   ping -c1 -W2 -w1 -q "${RMT_HOST}" > /dev/null 2>&1;RC=$?;
   if [[ $RC -eq 0 ]]; then
      echo ">>> FOUND restic backup server: ${RMT_HOST}" | tee -a "${LOGF}"
   else
      echo ">>> Could not find restic backup server: ${RMT_HOST}, aborting script now." | tee -a "${LOGF}"
      exit 1
   fi
}  # check_inet()

function backup_dir() {
   local START_T ETIME
   DIR=$1
   echo -e "\n${BANR}" | tee -a "${LOGF}"
   echo "# RUNNING: restic backup ${DIR} -r ${REPO} -p ${PW_FILE}" -q | tee -a "${LOGF}"
   echo "${BANR}" | tee -a "${LOGF}"
   START_T=$( __timer )
   ETIME=""
   # NOTE: Do not put double-quoutes around ${DIR}.
   #       Want restic to see a list of dirs
   # shellcheck disable=SC2086
   restic backup ${DIR} -r "${REPO}" -p "${PW_FILE}" -q; RC=$?
   ETIME=$( __timer "${START_T}")
   echo "RC=${RC} ${ETIME}" | tee -a "${LOGF}"
   echo ""  | tee -a "${LOGF}"
}  # backup_dir()

echo ">>> STARTING" | tee "${LOGF}"

echo -e "\n${BANR}" | tee -a "${LOGF}"
echo "# THIS_SCRIPT=${THIS_SCRIPT}" | tee -a "${LOGF}"
echo -e "${BANR}" | tee -a "${LOGF}"

check_envars
# Control reaches here if environment variables non-blank
check_inet "${RMT_HOST}"

ALL_PATHS=""
for DIR in "${DIR_ARRAY[@]}"; do
  FULL_PATH="${BASE_DIR}/${DIR}"
  ALL_PATHS="${ALL_PATHS} ${FULL_PATH}"
done
backup_dir "${ALL_PATHS}"
echo ">>> FINISHED" | tee -a "${LOGF}"
