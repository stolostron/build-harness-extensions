#---Login/Host-cluster related env vars---#

# API URL of the cluster running the target clusterpool, used in oc login, so port :6443 is required
CLUSTERPOOL_HOST_API ?=
# Access credentials used to log in to cluster indciated in CLUSTERPOOL_HOST_API
CLUSTERPOOL_HOST_USER ?=
CLUSTERPOOL_HOST_PASS ?=
# Namespace where Hive ClusterPool resources reside
CLUSTERPOOL_HOST_NAMESPACE ?= clusterpool
# Namespace where the Hive pods reside on the cluster indciated in CLUSTERPOOL_HOST_API, usually "hive"
CLUSTERPOOL_HIVE_NAMESPACE ?= hive


#---ClusterImageSet-related env vars---#

# Name of the ClusterImageSet to create
CLUSTERPOOL_IMAGESET_NAME ?=
CLUSTERPOOL_IMAGESET_RELEASE_IMAGE ?=

.PHONY: clusterpool/_init
## Install the oc cli and log in to the ClusterPool Host cluster
clusterpool/_init: %_init:
	${SELF} oc/install
	${SELF} oc/login OC_CLUSTER_USER=${CLUSTERPOOL_HOST_USER} OC_CLUSTER_PASS=${CLUSTERPOOL_HOST_PASS} OC_CLUSTER_URL=${CLUSTERPOOL_HOST_API}

.PHONY: clusterpool/create-image-set
clusterpool/create-image-set: %create-image-set: %_init
	@sed -e "s;__CLUSTERPOOL_IMAGESET_NAME__;${CLUSTERPOOL_IMAGESET_NAME};g" \
		-e "s;__CLUSTERPOOL_IMAGESET_RELEASE_IMAGE__;${CLUSTERPOOL_IMAGESET_RELEASE_IMAGE};g" \
		${BUILD_HARNESS_EXTENSIONS_PATH}/modules/clusterpool/templates/clusterimageset.yaml.template \
		> .${CLUSTERPOOL_IMAGESET_NAME}.clusterimageset.yaml
	@${SELF} oc/command OC_COMMAND="apply -f .${CLUSTERPOOL_IMAGESET_NAME}.clusterimageset.yaml -n ${CLUSTERPOOL_HIVE_NAMESPACE}"

.PHONY: clusterpool/delete-image-set
clusterpool/delete-image-set: %delete-image-set: %_init
	@${SELF} oc/command OC_COMMAND="delete clusterimageset ${CLUSTERPOOL_IMAGESET_NAME} -n ${CLUSTERPOOL_HIVE_NAMESPACE}"

.PHONY: clusterpool/create-cluster-pool
clusterpool/create-cluster-pool: %create-cluster-pool: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/delete-cluster-pool
clusterpool/delete-cluster-pool: %delete-cluster-pool: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/list-cluster-pools
clusterpool/list-cluster-pools: %list-cluster-pools: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/create-aws-creds
## Requires various credentials env vars specific to this cloud platform
clusterpool/create-aws-creds: %create-aws-creds: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/create-azure-creds
## Requires various credentials env vars specific to this cloud platform
clusterpool/create-azure-creds: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/create-gcp-creds
## Requires various credentials env vars specific to this cloud platform
clusterpool/create-gcp-creds: %create-gcp-creds: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/delete-creds
## Takes in a CREDS_SECRET_NAME variable
clusterpool/delete-creds: %delete-creds: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/create-claim
## Takes in a CLUSTERPOOL variable - the name of the clusterpool to create a claim on
clusterpool/create-claim: %create-claim: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/verify-claim
## Takes in a CLUSTER_CLAIM variable - the name of the claim to validate - and validates that the claim was fulfilled
clusterpool/verify-claim: %verify-claim: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/delete-claim
## Takes in a CLUSTER_ClAIM variable - the name of the claim to delete
clusterpool/delete-claim: %delete-claim: %_init
	echo unimplemented
	exit 1

.PHONY: clusetrpool/checkout
## takes in a CLUSTER_ClAIM variable - the name of the claim to create
clusetrpool/checkout: %checkout: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/checkin
## Takes in a CLUSTER_ClAIM variable - the name of the claim to delete
clusterpool/checkin: %checkin: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/get-cluster-kubeconfig
## Takes in a CLUSTER_ClAIM variable - the name of the claim to get creds from
clusterpool/get-cluster-kubeconfig: %get-cluster-kubeconfig: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/get-cluster-credentials
## takes in a CLUSTER_ClAIM variable - the name of the claim to get creds from
clusterpool/get-cluster-credentials: %get-cluster-credentials: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/get-cluster-api
## takes in a CLUSTER_ClAIM variable - the name of the claim to get creds from
clusterpool/get-cluster-api: %get-cluster-api: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/get-cluster-console
## takes in a CLUSTER_ClAIM variable - the name of the claim to get creds from
clusterpool/get-cluster-console: %get-cluster-console: %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/get-cluster-metadata
## takes in a CLUSTER_CLAIM variable and a METADATA_FILE where it will dump the json cluster details - this will consume the previous focused creds
clusterpool/get-cluster-metadata: %get-cluster-metadata: %_init
	echo unimplemented
	exit 1

