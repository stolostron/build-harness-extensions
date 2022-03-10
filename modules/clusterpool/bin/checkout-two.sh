#!/bin/sh

pull_a_cluster() {
# $1 = type of cluster (hub vs. import)
if [[ "$(wc -l shuffled_available_clusterpools.txt | awk '{ print $1 }')" -gt 0 ]]; then
    clusterpool_to_checkout=$(head -n 1 shuffled_available_clusterpools.txt)
    # Pull the clusterpool out of the list
    tail -n +2 shuffled_available_clusterpools.txt > shuffled_available_clusterpools.txt.tmp
    mv shuffled_available_clusterpools.txt.tmp shuffled_available_clusterpools.txt
    echo $clusterpool_to_checkout
fi
}

RANDOM_IDENTIFIER=$(head /dev/urandom | tr -dc "a-z0-9" | head -c 5 ; echo '')
CLUSTER1=$(pull_a_cluster)
echo checkout-two.sh pulled cluster: $CLUSTER1
CLUSTER2=$(pull_a_cluster)
echo checkout-two.sh pulled cluster: $CLUSTER2

if [[ "$CLUSTER1" = "" || "$CLUSTER2" = "" ]]; then
    echo checkout-two.sh: Not enough clusters available. Stopping.
    exit 1
fi

$(rm HUB_CLUSTER_CLAIM 2> /dev/null)
$(rm IMPORT_CLUSTER_CLAIM 2> /dev/null)

DUMMY1=$(make clusterpool/checkout CLUSTERPOOL_NAME=$CLUSTER1 CLUSTERPOOL_CLUSTER_CLAIM=$CLUSTER1-$RANDOM_IDENTIFIER > .HUB_CHECKOUT_OUTPUT) &
T_HUB_CLUSTER_CLAIM=${!}
DUMMY2=$(make clusterpool/checkout CLUSTERPOOL_NAME=$CLUSTER2 CLUSTERPOOL_CLUSTER_CLAIM=$CLUSTER2-$RANDOM_IDENTIFIER > .IMPORT_CHECKOUT_OUTPUT) &
T_IMPORT_CLUSTER_CLAIM=${!}

echo checkout-two.sh: waiting for hub cluster checkout rendezvous
wait ${T_HUB_CLUSTER_CLAIM}
RC_HUB_CLUSTER_CLAIM=$?
echo checkout-two.sh: waiting for import cluster checkout rendezvous
wait ${T_IMPORT_CLUSTER_CLAIM}
RC_IMPORT_CLUSTER_CLAIM=$?

if [[ "$RC_HUB_CLUSTER_CLAIM" = "0" && "$RC_IMPORT_CLUSTER_CLAIM" = "0" ]]; then
    echo $CLUSTER1-$RANDOM_IDENTIFIER > HUB_CLUSTER_CLAIM
    echo $CLUSTER2-$RANDOM_IDENTIFIER > IMPORT_CLUSTER_CLAIM
    rm .HUB_CHECKOUT_OUTPUT
    rm .IMPORT_CHECKOUT_OUTPUT
    echo checkout-two.sh: exiting 0
    exit 0
else
    echo hub cluster checkout failure - output:
    cat .HUB_CHECKOUT_OUTPUT
    rm .HUB_CHECKOUT_OUTPUT
    echo import cluster checkout failure - output:
    cat .IMPORT_CHECKOUT_OUTPUT
    rm .IMPORT_CHECKOUT_OUTPUT
    echo checkout-two.sh: exiting 1
    exit 1
fi
