#!/bin/bash

# Total "minutes" to retry before giving up
CLUSTERPOOL_CHECKOUT_TIMEOUT_MINUTES=$1

if [ "$CLUSTERPOOL_CHECKOUT_TIMEOUT_MINUTES" = "" ]; then CLUSTERPOOL_CHECKOUT_TIMEOUT_MINUTES=10
fi

# We retry on 30-second intervals (plus query overhead...)
RETRIES=$(( 2*$CLUSTERPOOL_CHECKOUT_TIMEOUT_MINUTES ))
CLUSTERPOOL_TEMP_DIR=$(mktemp -d -p .)

make clusterpool/_create-claim CLUSTERPOOL_TEMP_DIR=$CLUSTERPOOL_TEMP_DIR
make clusterpool/_gather-status CLUSTERPOOL_TEMP_DIR=$CLUSTERPOOL_TEMP_DIR

if [ "`cat $CLUSTERPOOL_TEMP_DIR/.verifyStatus`" = "ClusterReady" ]; then cat $CLUSTERPOOL_TEMP_DIR/.verifyStatus; else
	if [ ! "`cat $CLUSTERPOOL_TEMP_DIR/.verifyStatus`" = "ClusterReady" ]; then
		echo Waiting $CLUSTERPOOL_CHECKOUT_TIMEOUT_MINUTES minutes for cluster availability...
		cat $CLUSTERPOOL_TEMP_DIR/.verifyStatus
		for (( i=1; i<=$RETRIES; i++ ))
		do
			sleep 30
			make clusterpool/_gather-status CLUSTERPOOL_TEMP_DIR=$CLUSTERPOOL_TEMP_DIR
			cat $CLUSTERPOOL_TEMP_DIR/.verifyStatus
			if [ "`cat $CLUSTERPOOL_TEMP_DIR/.verifyStatus`" = "ClusterReady" ]; then exit 0; fi
		done
	else
		echo Unknown claim status `cat $CLUSTERPOOL_TEMP_DIR/.verifyStatus` - exiting
		# Unknown claim state - delete it
		make clusterpool/_delete-claim CLUSTERPOOL_TEMP_DIR=$CLUSTERPOOL_TEMP_DIR
		exit 1
	fi
	echo Claim provision timed out - exiting
	# We never got our claim satisfied - delete it
	make clusterpool/_delete-claim CLUSTERPOOL_TEMP_DIR=$CLUSTERPOOL_TEMP_DIR
	exit 1
fi
