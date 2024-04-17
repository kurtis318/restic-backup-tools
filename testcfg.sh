#!/bin/bash

# Test issue with *prune.cfg in kurtis-restic-prune.sh

BANR='#---------------------------------------------------------'
THIS_SCRIPT=$(readlink -f "${BASH_SOURCE[0]}" )
THIS_SCRIPT_DIR=$( dirname "${THIS_SCRIPT}" )
THIS_SCRIPT_RELATIVE_DIR="${THIS_SCRIPT_DIR##*/}"
THIS_SCRIPT_BASENAME=$(basename "$(readlink -f "$0")")
THIS_SCRIPT_FILENAME=$( basename "${THIS_SCRIPT%.*}")

CFGF="${THIS_SCRIPT_DIR}/${THIS_SCRIPT_RELATIVE_DIR}.cfg"
LOG_D="${THIS_SCRIPT_DIR}/logs"
LOG_F="${THIS_SCRIPT_DIR}/${THIS_SCRIPT_FILENAME}-log.txt"
if [[ -d "${LOG_D}" ]]; then
   LOG_F="${LOG_D}/${THIS_SCRIPT_FILENAME}-log.txt"
fi

echo -e "\n${BANR}"
   echo "# Here are sourced variables."
   echo "${BANR}"

# Print program vars and terminate if errors.
echo -e "<CFGF=${CFGF}> <LOG_D=${LOG_D}"
echo -e "<THIS_SCRIPT=${THIS_SCRIPT}>\n<THIS_SCRIPT_DIR=${THIS_SCRIPT_DIR}>"
echo -e "<THIS_SCRIPT_BASENAME=${THIS_SCRIPT_BASENAME}>\n<LOG_F=${LOG_F}>"
echo -e "<THIS_SCRIPT_FILENAME=${THIS_SCRIPT_FILENAME}>\n<THIS_SCRIPT_RELATIVE_DIR=${THIS_SCRIPT_RELATIVE_DIR}>"