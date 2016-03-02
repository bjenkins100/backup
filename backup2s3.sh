#!/bin/bash
DATETIME=`date +"%m-%d-%y-%T"`

set -x

#pip install python-magic

BUCKET=""
LOCKFILE=""
#
#
if [ -f "$LOCKFILE" ]; then
	printf "CRITICAL" > $LOCKFILE
	echo "ERROR: " | mail -s "ERROR: " $EMAIL
	if [ "$(pgrep backup_s3.sh)" ]; then
		exit 2
	else sleep 3700 && rm $LOCKFILE
	fi
	exit 1
elif [ ! -f "$LOCKFILE" ]; then
	touch $LOCKFILE || exit 1
	printf "OK" > $LOCKFILE
fi



DEST=""
if [ ! -d "${DEST}" ]; then
   mkdir --verbose --parent ${DEST} || exit 1

elif [ ! -w "${DEST}" ]; then
   echo "Directory not writable: ${DEST}" >&2
   exit 1
fi

START=$(date +%s)
sleep 6

# SEND TO S3
if [[ -f /opt/s3cmd/s3cmd ]]; then
	for dir in $DIRS; do
		ionice -c3 nice	/opt/s3cmd/s3cmd \
			--access_key="$KEY" \
			--secret_key="$SECRET" \
			--preserve \
			--follow-symlinks \
			--verbose sync ${dir} s3://${BUCKET}
		if [[ "$?" -gt "0" ]]; then
			echo " " | mail -s "$SUBJECT" $EMAIL
			exit 1
		fi
	done
else cd /opt && git clone https://github.com/s3tools/s3cmd.git || exit 1
fi
touch /tmp/backup_dumps_s3

FINISH=$(date +%s)
if [[ ! -d "${DEST}/timemachine/log" ]]; then
        mkdir ${DEST}/timemachine/log || exit 1
else echo "total time: $(( ($FINISH-$START) / 60 )) minutes, $(( ($FINISH-$START) % 60 )) seconds" | tee ${DEST}/timemachine/log/"[S3] $(date '+%Y-%m-%d, %T, %A')"
fi

rm $LOCKFILE

exit 0
