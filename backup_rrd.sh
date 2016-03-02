#!/bin/bash
#
#
LOGDIR=/var/log/backup
DATETIME=$(date +%y%m%d%H%M%S)
#
#
ORG=""
OMDHOME="/omd/sites/${ORG}"
RRDBACK="/backup/archive/rrd"

if [[ ! -d "${RRDBACK}" ]]; then
        mkdir --parents "${RRDBACK}"
fi

if [[ ! -f "${OMDHOME}/rrd.tgz" ]]; then
	rm "${OMDHOME}/rrd.tgz"
fi

su - ${ORG} -c \
	"bash /omd/sites/${ORG}/backup_rrdd.sh" \
		>${LOGDIR}/rrd_backup.${DATETIME}.log \
		2>${LOGDIR}/rrd_backup.${DATETIME}.log.err || exit 1

if [[ -f "${OMDHOME}/rrd.tgz" ]]; then
        mv "${OMDHOME}/rrd.tgz" "${RRDBACK}"/rrd.tgz.${DATETIME}
else exit 1
fi
#
#
#
exit 0
