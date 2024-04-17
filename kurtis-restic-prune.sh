#!/bin/bash
#----------------------------------------------------------------
# Use restic and rclone to PRUNE the restic objectstore
#
# REF: Configuration and Usage of rclone (or restic) and Box
# URL: https://github.ibm.com/openclient/ocfedora/wiki/Configuration-and-Usage-of-rclone-(or-restic)-and-Box
#
# Configuration:
# 1. sudo dnf -y install restic rclone
# 2. rclone config create kwrp50 box client_id="d0374ba6pgmaguie02ge15sv1mllndho"
# 3. restic -r rclone:kwrp50:kwrp50_restic init
#----------------------------------------------------------------

BANR='#---------------------------------------------------------'
THIS_SCRIPT=$(readlink -f "${BASH_SOURCE[0]}" )
THIS_SCRIPT_DIR=$( dirname "${THIS_SCRIPT}" )
# THIS_SCRIPT_RELATIVE_DIR="${THIS_SCRIPT_DIR##*/}"
# THIS_SCRIPT_BASENAME=$(basename "$(readlink -f "$0")")
THIS_SCRIPT_FILENAME=$( basename "${THIS_SCRIPT%.*}")

CFGF="${THIS_SCRIPT_DIR}/restic.cfg"
LOGD="${THIS_SCRIPT_DIR}/logs"
LOGF="${THIS_SCRIPT_DIR}-log.txt"
if [[ -d "${LOGD}" ]]; then
   LOGF="${LOGD}/${THIS_SCRIPT_FILENAME}-log.txt"
fi

# echo -e "<CFGF=${CFGF}>"
# echo -e "<THIS_SCRIPT=${THIS_SCRIPT}>\n<THIS_SCRIPT_DIR=${THIS_SCRIPT_DIR}>"
# echo -e "<THIS_SCRIPT_FILENAME=${THIS_SCRIPT_FILENAME}>\n<LOGF=${LOGF}>"

function check_envars() {
   local RC=0
   
   # CFGF must be in the local directory
   if [[ ! -f "${CFGF}" ]]; then
      echo "Cannot not find file='${CFGF}', aborting this script" | tee -a "${LOGF}"
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
      echo "Parameter 'PW_FILE' is blank"| tee -a "${LOGF}"
      _=$((RC++))
   fi

   # Print program vars and terminate if errors.
   echo "<RC=${RC}> <BASE_DIR=${BASE_DIR}> <REPO=${REPO}>"
   echo "<PW_FILE=${PW_FILE}> <LOGF=${LOGF}>"
   echo "<SYSD_PRE=${SYSD_PRE}> <CFGF=${CFGF}>"

   if (( RC == 0 )); then
      echo "All parameters are non-blank values"
   else
      echo "There were ${RC} blank parameters. Aborting this script."
      exit 101
   fi
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
   local RC=0
   ping -c1 -W2 -w1 -q "${RMT_HOST}" >/dev/null 2>&1;RC=$?;
   if [[ $RC -eq 0 ]]; then
      echo ">>> FOUND ${RMT_HOST}" | tee -a "${LOGF}"
   else
      echo ">>> Could not find ${RMT_HOST}, aborting script now."| tee -a "${LOGF}"
      exit 1
   fi
}  # check_inet()


function forget_and_prune() {
   local START_T=0
   local ETIME=0
   local RC=0
   echo -e "\n${BANR}" | tee -a "${LOGF}"
   echo "# RUNNING: restic forget -r ${REPO} --password-file ${PW_FILE} \\" | tee -a "${LOGF}"
   echo "#     --keep-within 365d --prune --group-by \"\"" | tee -a "${LOGF}"
   echo "${BANR}" | tee -a "${LOGF}"
   START_T=$( __timer )
   ETIME=""
   restic forget -r "${REPO}" --password-file "${PW_FILE}" \
      --keep-within 365d --prune --group-by "" >> "${LOGF}" 
   RC=$?
   ETIME=$( __timer "${START_T}")
   echo ">>> RC=${RC} ${ETIME}" | tee -a "${LOGF}"
   echo "" | tee -a "${LOGF}"
}  # forget_and_prune()


function check_repo() {
   local START_T=0
   local ETIME=0
   local RC=0
   echo -e "\n${BANR}" | tee -a "${LOGF}"
   echo "# RUNNING: restic check -r ${REPO} --password-file ${PW_FILE}"| tee -a "${LOGF}"
   echo "${BANR}" | tee -a "${LOGF}"

   # Skipping:
   # START_T=$( __timer )
   # restic check -r "${REPO}" --password-file "${PW_FILE}" 2>&1 >> "${LOGF}" 2>&1
   # RC=$?
   # ETIME=$( __timer "${START_T}")
   # echo ">>> RC=${RC} ${ETIME}" | tee -a "${LOGF}"
   # echo   
}

echo ">>> STARTING"

# The following statement deletes LOGF and then outputs banner.
echo -e "\n${BANR}" | tee "${LOGF}"
echo "# THIS_SCRIPT=${THIS_SCRIPT}" | tee -a "${LOGF}"
echo -e "${BANR}" | tee -a "${LOGF}"

check_envars
check_inet

ETIME=0
START_T=$( __timer )

forget_and_prune
# Running check_repo takes over 4 min. Skipping for now
# check_repo

ETIME=$( __timer "${START_T}")
echo ">>> Script ${ETIME} >>> ${THIS_SCRIPT}" | tee -a "${LOGF}"
echo ">>> Command output saved in '${LOGF}'"
echo ">>> FINISHED"
