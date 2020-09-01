#!/bin/bash

# Total "minutes" to retry before giving up
CLUSTERPOOL_WAIT_MINUTES=$1
# We retry on 30-second intervals (plus query overhead...)
RETRIES=$(( 2*CLUSTERPOOL_WAIT_MINUTES ))

make clusterpool/_create-claim
make clusterpool/_verify-claim  > .verifyStatus
if [ "`cat .verifyStatus`" = "ClusterClaimed" ]; then cat .verifyStatus; else
	if [ "`cat .verifyStatus`" = "NoClusters" ]; then
		echo Waiting $CLUSTERPOOL_WAIT_MINUTES minutes for cluster availability...
		for (( i=1; i<=$RETRIES; i++ ))
		do
			sleep 30
			make clusterpool/_verify-claim > .verifyStatus
			cat .verifyStatus
			if [ "`cat .verifyStatus`" = "ClusterClaimed" ]; then exit 0; fi
		done
	else
		echo Unknown claim status `cat .verifyStatus` - exiting
		# Unknown claim state - delete it
		make clusterpool/_delete-claim
		exit 1
	fi
	echo Claim provision timed out - exiting
	# We never got our claim satisfied - delete it
	make clusterpool/_delete-claim
	exit 1
fi
