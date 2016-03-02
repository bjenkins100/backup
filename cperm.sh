#!/bin/bash
#
#
set -e
set -x
#
DIR=""
#
if [[ $1 =~ ^(\/)(var)(\/)(${DIR})(\/)([\.A-Za-z0-9-]*)(\/)(releases)(\/)([0-9]{14})$ ]]; then
	
	APPDIR="$1"
	APPUSER=""
	USER=""

	if $([[ -d $APPDIR ]] && [[ -d ${APPDIR}/application/logs ]] && [[ -d ${APPDIR}/application/cache ]]); then

		chown -R root:${APPUSER} $APPDIR 
		chown $APPUSER ${APPDIR}
		chown -R $APPUSER ${APPDIR}/application/logs
		chown -R $APPUSER ${APPDIR}/application/cache
		#test -d ${APPDIR}/db && chown -R ${USER}:${USER} ${APPDIR}/db

	else echo "BAD DIR!!!" && exit 1

	fi

else echo "BAD DIR!!!" && exit 1
fi
#
#
echo "Permissions updated"
exit 0
