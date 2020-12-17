#!/bin/sh

TEMPFILE=$1
TEMPFILE2=$1''2

timestamp=$(curl --silent --location -H "Authorization: Bearer $REDHAT_REGISTRY_TOKEN" https://registry.redhat.io/v2/rhacm2/acm-operator-bundle/manifests/$2 | jq '[.history[]]|map(.v1Compatibility|fromjson|.created)|sort|reverse|.[0]')
jq '. + [ {"version": "'$2'", "timestamp": '$timestamp'}]' $TEMPFILE > $TEMPFILE2; mv $TEMPFILE2 $TEMPFILE
