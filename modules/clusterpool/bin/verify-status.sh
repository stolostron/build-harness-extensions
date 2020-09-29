#!/bin/sh
NAMESPACE=`jq -r '.spec.namespace' $1`
CONDITIONS=`jq -r '.status.conditions[]? | select(.type=="Pending").status' $1`
REASON=`jq -r '.status.conditions[]? | select(.type=="Pending").reason' $1`
#echo value: "$NAMESPACE"
#echo conditions: "$CONDITIONS"
if [ ! "$NAMESPACE" = "null" ]; then
        if [ ! "$CONDITIONS" = "True" ]; then
                if [ ! "$CONDITIONS" = "" ]; then
                        echo $REASON; else
                        echo "Failed - "$REASON
                fi ; else
		echo "Failed - "$REASON
        fi ; else
	echo "No namespace - "$REASON
fi
