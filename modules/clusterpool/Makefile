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


#---ClusterPool-related env vars---#

# Universal
CLUSTERPOOL_NAME ?=
CLUSTERPOOL_SIZE ?= 1

# AWS
CLUSTERPOOL_AWS_BASE_DOMAIN ?=
CLUSTERPOOL_AWS_REGION ?= us-east-1

# Azure
CLUSTERPOOL_AZURE_BASE_DOMAIN ?=
CLUSTERPOOL_AZURE_REGION ?= eastus
CLUSTERPOOL_AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME ?= 

# AWS
CLUSTERPOOL_GCP_BASE_DOMAIN ?=
CLUSTERPOOL_GCP_REGION ?= us-east-1
CLUSTERPOOL_ENCODED_AWS_ACCESS_KEY_ID ?= $(echo -n ${AWS_ACCESS_KEY_ID} | base64 -w 0)
CLUSTERPOOL_ENCODED_AWS_SECRET_ACCESS_KEY ?= $(echo -n ${AWS_SECRET_ACCESS_KEY} | base64 -w 0)

#---Cluster Credentials-related env vars---#
CLUSTERPOOL_AWS_CRED_NAME ?= aws-creds
CLUSTERPOOL_AZURE_CRED_NAME ?= azure-creds
CLUSTERPOOL_GCP_CRED_NAME ?= gcp-creds

.PHONY: clusterpool/_init
## Install the oc cli and log in to the ClusterPool Host cluster
clusterpool/_init: %_init:
	$(call assert-set,CLUSTERPOOL_HOST_USER)
	$(call assert-set,CLUSTERPOOL_HOST_PASS)
	$(call assert-set,CLUSTERPOOL_HOST_API)
	@${SELF} oc/install
	@${SELF} oc/login OC_CLUSTER_USER=${CLUSTERPOOL_HOST_USER} OC_CLUSTER_PASS=${CLUSTERPOOL_HOST_PASS} OC_CLUSTER_URL=${CLUSTERPOOL_HOST_API}

.PHONY: clusterpool/create-image-set
clusterpool/create-image-set: %create-image-set: %_init
	$(call assert-set,CLUSTERPOOL_IMAGESET_NAME)
	$(call assert-set,CLUSTERPOOL_IMAGESET_RELEASE_IMAGE)
	$(call assert-set,CLUSTERPOOL_HIVE_NAMESPACE)
	@sed -e "s;__CLUSTERPOOL_IMAGESET_NAME__;${CLUSTERPOOL_IMAGESET_NAME};g" \
		-e "s;__CLUSTERPOOL_IMAGESET_RELEASE_IMAGE__;${CLUSTERPOOL_IMAGESET_RELEASE_IMAGE};g" \
		${BUILD_HARNESS_EXTENSIONS_PATH}/modules/clusterpool/templates/clusterimageset.yaml.template \
		> .${CLUSTERPOOL_IMAGESET_NAME}.clusterimageset.yaml
	@${SELF} oc/command OC_COMMAND="apply -n ${CLUSTERPOOL_HIVE_NAMESPACE} -f .${CLUSTERPOOL_IMAGESET_NAME}.clusterimageset.yaml"

.PHONY: clusterpool/delete-image-set
clusterpool/delete-image-set: %delete-image-set: %_init
	$(call assert-set,CLUSTERPOOL_IMAGESET_NAME)
	$(call assert-set,CLUSTERPOOL_HIVE_NAMESPACE)
	@${SELF} oc/command OC_COMMAND="delete clusterimageset  -n ${CLUSTERPOOL_HIVE_NAMESPACE} ${CLUSTERPOOL_IMAGESET_NAME}"

.PHONY: clusterpool/aws/create-cluster-pool
clusterpool/aws/create-cluster-pool: %aws/create-cluster-pool: %_init
	$(call assert-set,CLUSTERPOOL_NAME)
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_AWS_BASE_DOMAIN)
	$(call assert-set,CLUSTERPOOL_IMAGESET_NAME)
	$(call assert-set,CLUSTERPOOL_SIZE)
	$(call assert-set,CLUSTERPOOL_AWS_CRED_NAME)
	$(call assert-set,CLUSTERPOOL_AWS_REGION)
	@sed -e "s;__CLUSTERPOOL_NAME__;${CLUSTERPOOL_NAME};g" \
		-e "s;__CLUSTERPOOL_HOST_NAMESPACE__;${CLUSTERPOOL_HOST_NAMESPACE};g" \
		-e "s;__CLUSTERPOOL_BASE_DOMAIN__;${CLUSTERPOOL_AWS_BASE_DOMAIN};g" \
		-e "s;__CLUSTERPOOL_IMAGESET_NAME__;${CLUSTERPOOL_IMAGESET_NAME};g" \
		-e "s;__CLUSTERPOOL_SIZE__;${CLUSTERPOOL_SIZE};g" \
		${BUILD_HARNESS_EXTENSIONS_PATH}/modules/clusterpool/templates/clusterpool.prefix.yaml.template \
		> .${CLUSTERPOOL_NAME}.aws.clusterpool.yaml
	@sed -e "s;__CLUSTERPOOL_AWS_CRED_NAME__;${CLUSTERPOOL_AWS_CRED_NAME};g" \
		-e "s;__CLUSTERPOOL_AWS_REGION__;${CLUSTERPOOL_AWS_REGION};g" \
		${BUILD_HARNESS_EXTENSIONS_PATH}/modules/clusterpool/templates/clusterpool.suffix.aws.yaml.template \
		>> .${CLUSTERPOOL_NAME}.aws.clusterpool.yaml
	@${SELF} oc/command OC_COMMAND="apply -n ${CLUSTERPOOL_HOST_NAMESPACE} -f .${CLUSTERPOOL_NAME}.aws.clusterpool.yaml"

.PHONY: clusterpool/azure/create-cluster-pool
clusterpool/azure/create-cluster-pool: %azure/create-cluster-pool: %_init
	$(call assert-set,CLUSTERPOOL_NAME)
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_AZURE_BASE_DOMAIN)
	$(call assert-set,CLUSTERPOOL_IMAGESET_NAME)
	$(call assert-set,CLUSTERPOOL_SIZE)
	$(call assert-set,CLUSTERPOOL_AZURE_CRED_NAME)
	$(call assert-set,CLUSTERPOOL_AZURE_REGION)
	@sed -e "s;__CLUSTERPOOL_NAME__;${CLUSTERPOOL_NAME};g" \
		-e "s;__CLUSTERPOOL_HOST_NAMESPACE__;${CLUSTERPOOL_HOST_NAMESPACE};g" \
		-e "s;__CLUSTERPOOL_BASE_DOMAIN__;${CLUSTERPOOL_AZURE_BASE_DOMAIN};g" \
		-e "s;__CLUSTERPOOL_IMAGESET_NAME__;${CLUSTERPOOL_IMAGESET_NAME};g" \
		-e "s;__CLUSTERPOOL_SIZE__;${CLUSTERPOOL_SIZE};g" \
		${BUILD_HARNESS_EXTENSIONS_PATH}/modules/clusterpool/templates/clusterpool.prefix.yaml.template \
		> .${CLUSTERPOOL_NAME}.az.clusterpool.yaml
	@sed -e "s;__CLUSTERPOOL_AZURE_CREDS_NAME__;${CLUSTERPOOL_AZURE_CRED_NAME};g" \
		-e "s;__CLUSTERPOOL_AZURE_REGION__;${CLUSTERPOOL_AZURE_REGION};g" \
		-e "s;__CLUSTERPOOL_AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME__;${CLUSTERPOOL_AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME};g" \
		${BUILD_HARNESS_EXTENSIONS_PATH}/modules/clusterpool/templates/clusterpool.suffix.azure.yaml.template \
		>> .${CLUSTERPOOL_NAME}.az.clusterpool.yaml
	@${SELF} oc/command OC_COMMAND="apply -n ${CLUSTERPOOL_HOST_NAMESPACE} -f .${CLUSTERPOOL_NAME}.az.clusterpool.yaml"

.PHONY: clusterpool/gcp/create-cluster-pool
clusterpool/gcp/create-cluster-pool: %gcp/create-cluster-pool: %_init
	$(call assert-set,CLUSTERPOOL_NAME)
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_GCP_BASE_DOMAIN)
	$(call assert-set,CLUSTERPOOL_IMAGESET_NAME)
	$(call assert-set,CLUSTERPOOL_SIZE)
	$(call assert-set,CLUSTERPOOL_GCP_CRED_NAME)
	$(call assert-set,CLUSTERPOOL_GCP_REGION)
	@sed -e "s;__CLUSTERPOOL_NAME__;${CLUSTERPOOL_NAME};g" \
		-e "s;__CLUSTERPOOL_HOST_NAMESPACE__;${CLUSTERPOOL_HOST_NAMESPACE};g" \
		-e "s;__CLUSTERPOOL_BASE_DOMAIN__;${CLUSTERPOOL_GCP_BASE_DOMAIN};g" \
		-e "s;__CLUSTERPOOL_IMAGESET_NAME__;${CLUSTERPOOL_IMAGESET_NAME};g" \
		-e "s;__CLUSTERPOOL_SIZE__;${CLUSTERPOOL_SIZE};g" \
		${BUILD_HARNESS_EXTENSIONS_PATH}/modules/clusterpool/templates/clusterpool.prefix.yaml.template \
		> .${CLUSTERPOOL_NAME}.gcp.clusterpool.yaml
	@sed -e "s;__CLUSTERPOOL_GCP_CREDS_NAME__;${CLUSTERPOOL_GCP_CRED_NAME};g" \
		-e "s;__CLUSTERPOOL_GCP_REGION__;${CLUSTERPOOL_GCP_REGION};g" \
		${BUILD_HARNESS_EXTENSIONS_PATH}/modules/clusterpool/templates/clusterpool.suffix.gcp.yaml.template \
		>> .${CLUSTERPOOL_NAME}.gcp.clusterpool.yaml
	@${SELF} oc/command OC_COMMAND="apply -n ${CLUSTERPOOL_HOST_NAMESPACE} -f .${CLUSTERPOOL_NAME}.gcp.clusterpool.yaml"

.PHONY: clusterpool/delete-cluster-pool
clusterpool/delete-cluster-pool: %delete-cluster-pool: %_init
	$(call assert-set,CLUSTERPOOL_NAME)
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	@${SELF} oc/command OC_COMMAND="delete -n ${CLUSTERPOOL_HOST_NAMESPACE} ${CLUSTERPOOL_NAME}"

.PHONY: clusterpool/list-cluster-pools
clusterpool/list-cluster-pools: %list-cluster-pools: %_init
	@${SELF} oc/command OC_COMMAND="get clusterpools -n ${CLUSTERPOOL_HOST_NAMESPACE}"

.PHONY: clusterpool/aws/create-creds
## Requires various credentials env vars specific to this cloud platform
clusterpool/aws/create-creds: %aws/create-creds: %_init
	@sed -e "s;__CLUSTERPOOL_HOST_NAMESPACE__;${CLUSTERPOOL_HOST_NAMESPACE};g" \
		-e "s;__CLUSTERPOOL_AWS_CRED_NAME__;${CLUSTERPOOL_AWS_CRED_NAME};g" \
		-e "s;__ENCODED_AWS_ACCESS_KEY_ID__;${CLUSTERPOOL_ENCODED_AWS_ACCESS_KEY_ID};g" \
		-e "s;__ENCODED_AWS_SECRET_ACCESS_KEY__;${CLUSTERPOOL_ENCODED_AWS_SECRET_ACCESS_KEY};g" \
		${BUILD_HARNESS_EXTENSIONS_PATH}/modules/clusterpool/templates/creds.aws.yaml.template \
		> .${CLUSTERPOOL_AWS_CRED_NAME}.aws.creds.yaml

.PHONY: clusterpool/azure/create-creds
## Requires various credentials env vars specific to this cloud platform
clusterpool/azure/create-creds: %azure/create-creds %_init
	echo unimplemented
	exit 1

.PHONY: clusterpool/gcp/create-creds
## Requires various credentials env vars specific to this cloud platform
clusterpool/gcp/create-creds: %gcp/create-creds: %_init
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

