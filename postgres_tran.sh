#!/bin/bash
#
#
set -e
set -x
#
#
#
#
LOCKFILE="/tmp/transaction_log.lock"
DATETIME=$(date +"%m%d%y")
TRANLOGDIR=""
TRANLOGBACK="${TRANLOGDIR}/backup_tranlogs.${DATETIME}"
TRANSOURCE=""
TRANDEST=""
TRANRSYNCLOG="${TRANLOGDIR}/rsync_transaction_logs.${DATETIME}.log"
RSYNCDEST1="${HOST2}:/var/lib/barman/db0/incoming/"
RSYNCDEST2="${HOST2}:/var/lib/barman/db1/incoming/"
#
#
if [ ! -d "/tmp/backup/tranlog_$DATETIME" ]; then 
	mkdir --parents "/tmp/backup/tranlog_$DATETIME"
fi
cd "/tmp/backup/tranlog_$DATETIME"
#
if [ -f "$LOCKFILE" ]; then
	printf "CRITICAL" > $LOCKFILE
	touch /var/log/backup/transaction_logs/lockfile.error
	echo "check transactionlog lockfile" | mail -s "ERROR: " $EMAIL
	exit 1
elif [ ! -f "$LOCKFILE" ]; then
	touch $LOCKFILE || exit 1
	printf "OK" > $LOCKFILE
fi
#
#
if [ ! -d "$TRANLOGDIR" ]; then
        mkdir --parents $TRANLOGDIR || exit 1
fi
#
#
if [ ! -d "$TRANDEST" ]; then 
	mkdir --parents "$TRANDEST" || exit 1
fi
#
#
#
if $([[ -d "$TRANSOURCE" ]] && [[ -d "$TRANDEST" ]]); then
	cd ${TRANSOURCE}
	touch "$TRANLOGBACK.log"
	touch "$TRANRSYNCLOG"
	find . -maxdepth 1 \
		-regextype posix-extended -regex '^\.\/{1}[a-zA-Z0-9]{24}$' \
		-mmin +1 \
		! -name "*.gz" \
		-type f -ls -print \
		-exec rsync --log-file="${TRANRSYNCLOG}" -a {} ${RSYNCDEST1} \; \
		-exec rsync --log-file="${TRANRSYNCLOG}" -a {} ${RSYNCDEST2} \; \
		-exec mv -v {} ${TRANDEST} \; >>"${TRANLOGBACK}.log" 2>>"${TRANLOGBACK}.err" || exit 1
	find . -maxdepth 1 \
		-regextype posix-extended -regex '^\.\/[a-zA-Z0-9]{24}[.]{1}[0-9]{8}[.]{1}[a-z]{6}$' \
		-mmin +1 \
		! -name "*.gz" \
		-type f -ls -print \
		-exec rsync --log-file="${TRANRSYNCLOG}" -a {} ${RSYNCDEST1} \; \
		-exec rsync --log-file="${TRANRSYNCLOG}" -a {} ${RSYNCDEST2} \; \
		-exec mv -v {} ${TRANDEST} \; >>"${TRANLOGBACK}.log" 2>>"${TRANLOGBACK}.err" || exit 1
	cd ${TRANDEST}
	find . -maxdepth 1 \
		-regextype posix-extended -regex '^\.\/{1}[a-zA-Z0-9]{24}$' \
		! -name "*.gz" \
                -mmin +5 \
                -type f -ls -print \
		-exec nice ionice gzip --rsyncable --best {} \; >>"${TRANLOGBACK}_gzip.log" 2>>"${TRANLOGBACK}_gzip.err" || exit 1
else exit 1
fi
#
#
touch /tmp/transaction_log
rmdir "/tmp/backup/tranlog_$DATETIME"
rm $LOCKFILE
#
#
#
#
exit 0
