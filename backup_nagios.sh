#!/bin/bash
DATETIME=$(date +%s)
#
#
ORG=""
#
#
if [[ ! -d /var/log/backup ]]; then mkdir --parent /var/log/backup; fi
[[ ! -d  /var/archive ]] && mkdir --parent /var/archive
#
if [[ ! -d /var/archive ]]; then
        exit 255
else
	if [[ ! -d /var/archive/check_mk ]]; then 
		mkdir --parents /var/archive/check_mk
		chown ${ORG}:${ORG} /var/archive/check_mk
	fi
	# check_mk --restore backup-17.tar.gz
	su - ${ORG} -c "/opt/omd/versions/1.20/bin/check_mk -v --backup /var/archive/check_mk/check_mk_backup_${DATETIME}_nagios.tar.gz"
	#monit unmonitor apache
	#monit unmonitor rrdcached
	#monit unmonitor pnp4nagios
	#/etc/init.d/omd-1.2.0 stop
	       ionice -c3 tar cvfz "/var/archive/nagios_backup_${DATETIME}_nagios.tar.gz" \
			/etc /root /opt /var/www /usr/local \
			--exclude="tmp/run" \
			--exclude="/opt/omd/sites/${ORG}/var/log" \
			--exclude="/opt/omd/sites/${ORG}/var/pnp4nagios/perfdata" \
			--exclude="/opt/omd/sites/${ORG}/var/rrdcached" \
			--exclude="/opt/omd/sites/${ORG}/tmp/apache/fcgid_sock" \
			--exclude="/var/log" \
			| exit 1
	sleep 20
	#/etc/init.d/omd-1.2.0 start
	#monit monitor apache
	#monit monitor rrdcached
	#monit monitor pnp4nagios
fi
#
exit 0
