#!/bin/bash
#set -x
set -e
#touch /tmp/host.list
#nmap -sP $SUBNET | grep 'Host' | awk '{ print $2 }' > /tmp/host.list
LOCK=/tmp/host_check_script.lock
#
#
if [ -f $LOCK ]; then
	printf "CRITICAL" > $LOCK
	if pgrep host_check_script; then
		exit 2
	else rm $LOCK
	fi
	exit 1
else
	[ ! -f $LOCK ] && touch $LOCK || exit 1
	printf "OK" > $LOCK
fi
if [ -f $LOCK ]; then
	touch /tmp/host_check
COUNTER=""
docheck() {
	while read host; do
		COUNTER=1
		if [ $COUNTER == 1 ]; then
			if [ "$host" != "" ]; then
				if [ "$host" == "192.168.3.46" ]; then
                                        let COUNTER=$((COUNTER-1))
				else while read MONITOREDhost; do
					aHOST=$(dig $MONITOREDhost +short | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
					if [ "$aHOST" == "$host" ]; then
							let COUNTER=$((COUNTER-1))
					fi
				done < <(/omd/sites/publicstuff/bin/cmk --list-hosts | awk '{ print $1 }')
				fi
			fi
			if [ $COUNTER != 0 ]; then
				hostname=$(dig -x $host +short)
				echo "CRITICAL ip - $host Unmonitored host found CRITICAL: $hostname" | mail -s "CRITICAL host Alert $host | dns =  $hostname" "$EMAIL"
                                exit 2
			fi
		fi
	done < <(/usr/bin/nmap -n -sP $SUBNET | grep 'Host' | awk '{ print $2 }')
	echo 0
}

exitstat() {
	if [ "$1" ==  0 ]; then
		echo "CHECK_MK OK: check passed " 
		exit 0
	else 
		echo "CHECK_MK CRITICAL: HOST ARE NOT BEING MONITORED" 
		exit 2
	fi
}

currentstatus=$(docheck)
rm /tmp/host_check_script.lock
exitstat $currentstatus
fi
