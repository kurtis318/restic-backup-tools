#!/bin/bash

# Figure out time each restic-all.sh backup took for this boot
BOOT_ID=$1
if [[ -z "${BOOT_ID}" ]]; then
  BOOT_ID=0
fi
echo "<BOOT_ID=${BOOT_ID}>"
journalctl -b "${BOOT_ID}" | \
	grep kurtis-restic-crit| \
        grep -E ">>> STARTING|>>> FINISHED"| \
	awk '/>>> STARTING/{start=$3;}/>>> FINISHED/{fin=$3;printf("%s %s\n",start,fin);}'| \
	xargs -l ./time2sec.py

