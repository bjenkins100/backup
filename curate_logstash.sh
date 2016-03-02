#!/bin/bash
#when = SATURDAY at 15
#
DATEBACK=`date +%Y%m%d%H%M`
DATE=`date +%Y%m%d`
HOST=$ELASTIC_SEARCH_SERVER
PORT="9200"
#PREFIX="logstash"
LOGAGE=7
#
DEST="/var/log/curator"
indexDEST="/backup/logstash"
curator="/usr/local/bin/curator"
elasticdump="/usr/sbin/elasticdump"
#
#
set -e
#
#
if [[ ! -d "${DEST}" ]]; then
        mkdir --parents "${DEST}" || exit 1
fi
#
if [[ ! -n $HOST ]]; then
    exit 1
fi
#
sleep 5
#
#
#
if [[ -d "${DEST}" ]]; then
#
#
for PREFIX in packetbeat filebeat logstash topbeat; do
  for index in $(curator \
                    --host "${HOST}" \
                    --port "${PORT}" \
                    --master-only \
                    --loglevel error \
                    show indices \
                    --prefix "${PREFIX}" \
                    --time-unit days \
                    --older-than "${LOGAGE}" \
                    --timestring '%Y.%m.%d' | grep -v INFO || exit 1); do
                    #
                    #
    backupauditlog="${DEST}/${PREFIX}_index_delete.${DATEBACK}.audit.log"
    backupfile="${indexDEST}/${PREFIX}_index_${index}_${DATEBACK}.json.gz"
    backupindexpath="http://${HOST}:${PORT}/${index}"
    #
	echo "$index"
        #
        if [[ `printf ${index} |cut -d "-" -f1` = "${PREFIX}" ]]; then
		printf "\n deleting ${index} on ${DATEBACK} \n" \ >> "${backupauditlog}"
                #
		    	if [[ ! -f "${backupfile}" ]]; then
				nice -n 19 ionice -c2 -n7 \
                    elasticdump \
                    --all=true \
                    --input="${backupindexpath}" \
                    --output=$ | gzip -9 > "$backupfile" || exit 1
                else exit 1
                fi
                #
		sleep 1
		#
	  else exit 1
	  fi
  done
  #
  #
  prefixdeletelog="${DEST}/${PREFIX}_index_delete.${DATE}.log"
  prefixdeletelogerror="${DEST}/${PREFIX}_index_delete.${DATE}.err"
  #
  if [[ ! -f "${prefixdeletelog}" ]]; then
    nice -n 19 ionice -c2 -n7 curator \
    --host "${HOST}" \
    --port "${PORT}" \
    --master-only \
    --logformat default \
    --loglevel debug \
    --logfile "${prefixdeletelog}" \
    delete indices \
	--prefix "${PREFIX}" \
	--time-unit days \
    --older-than "${LOGAGE}" \
	--timestring '%Y.%m.%d' 2> "${prefixdeletelogerror}" || exit 1
  else exit 1
  fi
  #
  #
  #
done
else exit 1
fi
#
#
touch /tmp/logstash_curator
#
#
exit 0
