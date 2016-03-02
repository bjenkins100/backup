#!/bin/bash

set -e

ORG=""
RRDDHOME="/omd/sites/${ORG}/var/pnp4nagios"
RRDDBPATH="/omd/sites/${ORG}/var/pnp4nagios/perfdata"
CF_CONF_PATH="/omd/sites/${ORG}/etc/pnp4nagios"
BACKUPDIR="$HOME/backup/tmp/rrdd"

if [[ ! -d "$BACKUPDIR" ]]; then
	mkdir --parents $BACKUPDIR
fi

if $(ls "$BACKUPDIR"/*/*.xml >/dev/null); then
	rm "$BACKUPDIR"/*/*.xml
fi

# Save the rrd databases 
if [ -d "${RRDDBPATH}" ]; then
[[ -d "$RRDDBPATH" ]] && cd $RRDDBPATH
  for server in $(ls); do
    if [[ ! -d "$BACKUPDIR/$server" ]]; then
      mkdir $BACKUPDIR/$server
    fi
    if $( [[ -d "$server" ]] && [[ -d "$BACKUPDIR" ]] ); then
	for rrdfile in "$server"/*.rrd ; do
		xmlfile="${rrdfile%.rrd}.xml"
		nice -n20 rrdtool dump "${rrdfile}" "${BACKUPDIR}"/"${server}"/"${xmlfile}"
	done
    else exit 1
    fi
  done
  ionice -c3 tar -czf ${HOME}/rrd.tgz "${BACKUPDIR}"/ "${CF_CONF_PATH}"
  rm "$BACKUPDIR"/*/*.xml
fi
exit 0
