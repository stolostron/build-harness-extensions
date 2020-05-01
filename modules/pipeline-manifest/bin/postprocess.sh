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

echo Before, $manifest_filename is:
cat $manifest_filename

ep_quaysha=`make -s retag/getquaysha RETAG_QUAY_COMPONENT_TAG=$TAG-dls COMPONENT_NAME=endpoint-operator`
mco_quaysha=`make -s retag/getquaysha RETAG_QUAY_COMPONENT_TAG=$TAG-dls COMPONENT_NAME=multiclusterhub-operator`
echo endpoint-operator quay sha: $ep_quaysha
echo multiclusterhub-operator quay sha: $mco_quaysha
jq --version
jq --arg ep_quaysha $ep_quaysha '(.[] | select (.["image-name"] == "endpoint-operator") | .["image-digest"]) |= $ep_quaysha' $manifest_filename > tmp.json ; mv tmp.json $manifest_filename
jq --arg mco_quaysha $mco_quaysha '(.[] | select (.["image-name"] == "multiclusterhub-operator") | .["image-digest"]) |= $mco_quaysha' $manifest_filename > tmp.json ; mv tmp.json $manifest_filename
echo After, $manifest_filename is:
cat $manifest_filename
