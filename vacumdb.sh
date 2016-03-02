#!/bin/bash
#
#
set -e
#
#
[[ "$1" == "vacuumdb" ]] || exit 1
#
#
DATETIME=$(date +%y%m%d%H%M)
LOCKFILE=/tmp/lock_vacuumdb
#
#
if [[ -f $LOCKFILE ]]; then
  exit 1
else touch $LOCKFILE
fi
#
#
for DBNAME in $DBNAMES; do
  vacuumdb --analyze --dbname ${DBNAME} 
done
#
#
touch /tmp/vacumdb.run
rm $LOCKFILE
#
#
exit 0
