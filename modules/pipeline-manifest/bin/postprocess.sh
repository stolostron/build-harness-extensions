#!/bin/bash

# Incoming variables:
#   $1 - name of the manifest json file (should exist)
#   $2 - snapshot tag (the whole thing; i.e. 1.0.0-SNAPSHOT-2020-05-01-02-47-45)
#
# Required environment variables:
#   $QUAY_TOKEN - you know, the token... to quay (needs to be able to read open-cluster-management stuffs
#

if [[ -z "$QUAY_TOKEN" ]]
then
  echo "Please export QUAY_TOKEN"
  exit 1
fi

manifest_filename=$1
TAG=$2

echo Incoming manfiest filename: $manifest_filename
echo Incoming tag: $TAG
ep_quaysha=`make retag/getquaysha RETAG_QUAY_COMPONENT_TAG=$TAG COMPONENT_NAME=endpoint-operator`
echo endpoint-operator quay sha: $ep_quaysha
