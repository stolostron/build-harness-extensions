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


#---Hive Deploy Params---#
CLUSTERPOOL_HIVE_REPO ?= git@github.com:openshift/hive.git
CLUSTERPOOL_HIVE_BRANCH ?= master


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

#---Cluster Credentials-related env vars---#
# Overarching
CLUSTERPOOL_AWS_CRED_NAME ?= aws-creds
CLUSTERPOOL_AZURE_CRED_NAME ?= azure-creds
CLUSTERPOOL_GCP_CRED_NAME ?= gcp-creds
CLUSTERPOOL_PULL_SECRET_NAME ?= clusterpool-pull-secret
CLUSTERPOOL_PULL_SECRET_FILE ?= $(BUILD_HARNESS_EXTENSIONS_PATH)/pull-secret.txt

# AWS
CLUSTERPOOL_ENCODED_AWS_ACCESS_KEY_ID ?= $(echo -n $(AWS_ACCESS_KEY_ID) | base64 -w 0)
CLUSTERPOOL_ENCODED_AWS_SECRET_ACCESS_KEY ?= $(echo -n $(AWS_SECRET_ACCESS_KEY) | base64 -w 0)

# Azure
CLUSTERPOOL_AZURE_SUBSCRIPTION_ID ?= $(AZURE_SUBSCRIPTION_ID)
CLUSTERPOOL_AZURE_CLIENT_ID ?= $(AZURE_SERVICE_PRINCIPAL_CLIENT_ID)
CLUSTERPOOL_AZURE_CLIENT_SECRET ?= $(AZURE_SERVICE_PRINCIPAL_CLIENT_SECRET)
CLUSTERPOOL_AZURE_TENNANT_ID ?= $(AZURE_TENANT_ID)

# GCP
CLUSTERPOOL_GCP_ACCOUNT_JSON_FILE ?= $(HOME)/.gcp/osServiceAccount.json


#---Clusterpool List-related env vars---#
CLUSTERPOOL_LIST_ARGUMENTS ?= 

.PHONY: clusterpool/_init
## Install the oc cli and log in to the ClusterPool Host cluster
clusterpool/_init: %_init:
	$(call assert-set,CLUSTERPOOL_HOST_USER)
	$(call assert-set,CLUSTERPOOL_HOST_PASS)
	$(call assert-set,CLUSTERPOOL_HOST_API)
	@$(SELF) -s oc/install
	@$(SELF) -s oc/login OC_CLUSTER_USER=$(CLUSTERPOOL_HOST_USER) OC_CLUSTER_PASS=$(CLUSTERPOOL_HOST_PASS) OC_CLUSTER_URL=$(CLUSTERPOOL_HOST_API) \
		OC_FORCE_LOGIN="true" OC_SILENT_LOGIN="true"

.PHONY: clusterpool/_init_namespace
## Query the namespace and stash it in .namespace in the current working directory
clusterpool/_init_namespace:
	$(call assert-set,CLUSTERPOOL_CLUSTER_CLAIM)
	@$(SELF) -s oc/command OC_COMMAND="get ClusterClaim $(CLUSTERPOOL_CLUSTER_CLAIM) -o json | jq -r '.spec.namespace'" > .namespace
	@if [ -n "$(CLUSTERPOOL_DEBUG)" ]; then echo namespace:; cat .namespace; fi

.PHONY: clusterpool/deploy-hive
## Takes as input a branch for the hive project and deploys hive onto the target cluster
clusterpool/deploy-hive: %deploy-hive: %_init
	$(call assert-set,CLUSTERPOOL_HIVE_REPO)
	$(call assert-set,CLUSTERPOOL_HIVE_BRANCH)
	$(call assert-set,GITHUB_USER)
	$(call assert-set,GITHUB_TOKEN)
	@git clone --single-branch --branch $(CLUSTERPOOL_HIVE_BRANCH) $(CLUSTERPOOL_HIVE_REPO)
	@cd hive && $(SELF) deploy

.PHONY: clusterpool/create-image-set
## Takes as input an imageset name and release image and creates a ClusterImageSet.  
clusterpool/create-image-set: %create-image-set: %_init
	$(call assert-set,CLUSTERPOOL_IMAGESET_NAME)
	$(call assert-set,CLUSTERPOOL_IMAGESET_RELEASE_IMAGE)
	$(call assert-set,CLUSTERPOOL_HIVE_NAMESPACE)
	@sed -e "s;__CLUSTERPOOL_IMAGESET_NAME__;$(CLUSTERPOOL_IMAGESET_NAME);g" \
		-e "s;__CLUSTERPOOL_IMAGESET_RELEASE_IMAGE__;$(CLUSTERPOOL_IMAGESET_RELEASE_IMAGE);g" \
		$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/clusterpool/templates/clusterimageset.yaml.template \
		> .$(CLUSTERPOOL_IMAGESET_NAME).clusterimageset.yaml
	@$(SELF) oc/command OC_COMMAND="apply -n $(CLUSTERPOOL_HIVE_NAMESPACE) -f .$(CLUSTERPOOL_IMAGESET_NAME).clusterimageset.yaml"

.PHONY: clusterpool/delete-image-set
## Takes as input the name of an imageset and deletes said imageset
clusterpool/delete-image-set: %delete-image-set: %_init
	$(call assert-set,CLUSTERPOOL_IMAGESET_NAME)
	$(call assert-set,CLUSTERPOOL_HIVE_NAMESPACE)
	@$(SELF) oc/command OC_COMMAND="delete clusterimageset  -n $(CLUSTERPOOL_HIVE_NAMESPACE) $(CLUSTERPOOL_IMAGESET_NAME)"

.PHONY: clusterpool/aws/create-clusterpool
## Create a clusterpool on AWS
clusterpool/aws/create-clusterpool: %aws/create-clusterpool: %_init
	$(call assert-set,CLUSTERPOOL_NAME)
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_AWS_BASE_DOMAIN)
	$(call assert-set,CLUSTERPOOL_IMAGESET_NAME)
	$(call assert-set,CLUSTERPOOL_SIZE)
	$(call assert-set,CLUSTERPOOL_AWS_CRED_NAME)
	$(call assert-set,CLUSTERPOOL_AWS_REGION)
	@sed -e "s;__CLUSTERPOOL_NAME__;$(CLUSTERPOOL_NAME);g" \
		-e "s;__CLUSTERPOOL_HOST_NAMESPACE__;$(CLUSTERPOOL_HOST_NAMESPACE);g" \
		-e "s;__CLUSTERPOOL_BASE_DOMAIN__;$(CLUSTERPOOL_AWS_BASE_DOMAIN);g" \
		-e "s;__CLUSTERPOOL_IMAGESET_NAME__;$(CLUSTERPOOL_IMAGESET_NAME);g" \
		-e "s;__CLUSTERPOOL_SIZE__;$(CLUSTERPOOL_SIZE);g" \
		$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/clusterpool/templates/clusterpool.prefix.yaml.template \
		> .$(CLUSTERPOOL_NAME).aws.clusterpool.yaml
	@sed -e "s;__CLUSTERPOOL_AWS_CRED_NAME__;$(CLUSTERPOOL_AWS_CRED_NAME);g" \
		-e "s;__CLUSTERPOOL_AWS_REGION__;$(CLUSTERPOOL_AWS_REGION);g" \
		$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/clusterpool/templates/clusterpool.suffix.aws.yaml.template \
		>> .$(CLUSTERPOOL_NAME).aws.clusterpool.yaml
	@$(SELF) oc/command OC_COMMAND="apply -n $(CLUSTERPOOL_HOST_NAMESPACE) -f .$(CLUSTERPOOL_NAME).aws.clusterpool.yaml"

.PHONY: clusterpool/azure/create-clusterpool
## Create a cluserpool on Azure
clusterpool/azure/create-clusterpool: %azure/create-clusterpool: %_init
	$(call assert-set,CLUSTERPOOL_NAME)
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_AZURE_BASE_DOMAIN)
	$(call assert-set,CLUSTERPOOL_IMAGESET_NAME)
	$(call assert-set,CLUSTERPOOL_SIZE)
	$(call assert-set,CLUSTERPOOL_AZURE_CRED_NAME)
	$(call assert-set,CLUSTERPOOL_AZURE_REGION)
	@sed -e "s;__CLUSTERPOOL_NAME__;$(CLUSTERPOOL_NAME);g" \
		-e "s;__CLUSTERPOOL_HOST_NAMESPACE__;$(CLUSTERPOOL_HOST_NAMESPACE);g" \
		-e "s;__CLUSTERPOOL_BASE_DOMAIN__;$(CLUSTERPOOL_AZURE_BASE_DOMAIN);g" \
		-e "s;__CLUSTERPOOL_IMAGESET_NAME__;$(CLUSTERPOOL_IMAGESET_NAME);g" \
		-e "s;__CLUSTERPOOL_SIZE__;$(CLUSTERPOOL_SIZE);g" \
		$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/clusterpool/templates/clusterpool.prefix.yaml.template \
		> .$(CLUSTERPOOL_NAME).az.clusterpool.yaml
	@sed -e "s;__CLUSTERPOOL_AZURE_CREDS_NAME__;$(CLUSTERPOOL_AZURE_CRED_NAME);g" \
		-e "s;__CLUSTERPOOL_AZURE_REGION__;$(CLUSTERPOOL_AZURE_REGION);g" \
		-e "s;__CLUSTERPOOL_AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME__;$(CLUSTERPOOL_AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME);g" \
		$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/clusterpool/templates/clusterpool.suffix.azure.yaml.template \
		>> .$(CLUSTERPOOL_NAME).az.clusterpool.yaml
	@$(SELF) oc/command OC_COMMAND="apply -n $(CLUSTERPOOL_HOST_NAMESPACE) -f .$(CLUSTERPOOL_NAME).az.clusterpool.yaml"

.PHONY: clusterpool/gcp/create-clusterpool
## Create a clusterpool on GCP
clusterpool/gcp/create-clusterpool: %gcp/create-clusterpool: %_init
	$(call assert-set,CLUSTERPOOL_NAME)
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_GCP_BASE_DOMAIN)
	$(call assert-set,CLUSTERPOOL_IMAGESET_NAME)
	$(call assert-set,CLUSTERPOOL_SIZE)
	$(call assert-set,CLUSTERPOOL_GCP_CRED_NAME)
	$(call assert-set,CLUSTERPOOL_GCP_REGION)
	@sed -e "s;__CLUSTERPOOL_NAME__;$(CLUSTERPOOL_NAME);g" \
		-e "s;__CLUSTERPOOL_HOST_NAMESPACE__;$(CLUSTERPOOL_HOST_NAMESPACE);g" \
		-e "s;__CLUSTERPOOL_BASE_DOMAIN__;$(CLUSTERPOOL_GCP_BASE_DOMAIN);g" \
		-e "s;__CLUSTERPOOL_IMAGESET_NAME__;$(CLUSTERPOOL_IMAGESET_NAME);g" \
		-e "s;__CLUSTERPOOL_SIZE__;$(CLUSTERPOOL_SIZE);g" \
		$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/clusterpool/templates/clusterpool.prefix.yaml.template \
		> .$(CLUSTERPOOL_NAME).gcp.clusterpool.yaml
	@sed -e "s;__CLUSTERPOOL_GCP_CREDS_NAME__;$(CLUSTERPOOL_GCP_CRED_NAME);g" \
		-e "s;__CLUSTERPOOL_GCP_REGION__;$(CLUSTERPOOL_GCP_REGION);g" \
		$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/clusterpool/templates/clusterpool.suffix.gcp.yaml.template \
		>> .$(CLUSTERPOOL_NAME).gcp.clusterpool.yaml
	@$(SELF) oc/command OC_COMMAND="apply -n $(CLUSTERPOOL_HOST_NAMESPACE) -f .$(CLUSTERPOOL_NAME).gcp.clusterpool.yaml"

.PHONY: clusterpool/delete-clusterpool
## Delete a clusterpool pointed to in CLUSTERPOOL_NAME (any platform)
clusterpool/delete-clusterpool: %delete-clusterpool: %_init
	$(call assert-set,CLUSTERPOOL_NAME)
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	@$(SELF) oc/command OC_COMMAND="delete clusterpool -n $(CLUSTERPOOL_HOST_NAMESPACE) $(CLUSTERPOOL_NAME)"

.PHONY: clusterpool/list-clusterpools
## List all clusterpools in the CLUSTERPOOL_HOST_NAMESPACE
clusterpool/list-clusterpools: %list-clusterpools: %_init
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get clusterpools -n $(CLUSTERPOOL_HOST_NAMESPACE) $(CLUSTERPOOL_LIST_ARGUMENTS)"

.PHONY: clusterpool/aws/create-creds
## Create a hive credentials secret for AWS with input credentials
clusterpool/aws/create-creds: %aws/create-creds: %_init
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_AWS_CRED_NAME)
	$(call assert-set,CLUSTERPOOL_ENCODED_AWS_ACCESS_KEY_ID)
	$(call assert-set,CLUSTERPOOL_ENCODED_AWS_SECRET_ACCESS_KEY)
	@sed -e "s;__CLUSTERPOOL_HOST_NAMESPACE__;$(CLUSTERPOOL_HOST_NAMESPACE);g" \
		-e "s;__CLUSTERPOOL_AWS_CRED_NAME__;$(CLUSTERPOOL_AWS_CRED_NAME);g" \
		-e "s;__ENCODED_AWS_ACCESS_KEY_ID__;$(CLUSTERPOOL_ENCODED_AWS_ACCESS_KEY_ID);g" \
		-e "s;__ENCODED_AWS_SECRET_ACCESS_KEY__;$(CLUSTERPOOL_ENCODED_AWS_SECRET_ACCESS_KEY);g" \
		$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/clusterpool/templates/creds.aws.yaml.template \
		> .$(CLUSTERPOOL_AWS_CRED_NAME).aws.creds.yaml
	@$(SELF) oc/command OC_COMMAND="apply -n $(CLUSTERPOOL_HOST_NAMESPACE) -f .$(CLUSTERPOOL_AWS_CRED_NAME).aws.creds.yaml"

.PHONY: clusterpool/aws/delete-creds
## Deletes the secret CLUSTERPOOL_AWS_CRED_NAME
clusterpool/aws/delete-creds: %aws/delete-creds: %_init
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_AWS_CRED_NAME)
	@$(SELF) oc/command OC_COMMAND="delete secret -n $(CLUSTERPOOL_HOST_NAMESPACE) $(CLUSTERPOOL_AWS_CRED_NAME)"

.PHONY: clusterpool/azure/create-creds
## Create a hive credentials secret for Azue with input credentials
clusterpool/azure/create-creds: %azure/create-creds: %_init
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_AZURE_SUBSCRIPTION_ID)
	$(call assert-set,CLUSTERPOOL_AZURE_CLIENT_ID)
	$(call assert-set,CLUSTERPOOL_AZURE_CLIENT_SECRET)
	$(call assert-set,CLUSTERPOOL_AZURE_TENNANT_ID)
	$(call assert-set,CLUSTERPOOL_AZURE_CRED_NAME)
	@sed -e "s;__AZURE_SUBSCRIPTION_ID__;$(CLUSTERPOOL_AZURE_SUBSCRIPTION_ID);g" \
		-e "s;__AZURE_CLIENT_ID__;$(CLUSTERPOOL_AZURE_CLIENT_ID);g" \
		-e "s;__AZURE_CLIENT_SECRET__;$(CLUSTERPOOL_AZURE_CLIENT_SECRET);g" \
		-e "s;__AZURE_TENANT_ID__;$(CLUSTERPOOL_AZURE_TENNANT_ID);g" \
		$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/clusterpool/templates/creds.azure.osServicePrincipal.json.tempate \
		> osServicePrincipal.json
	@$(SELF) oc/command OC_COMMAND="create secret generic $(CLUSTERPOOL_AZURE_CRED_NAME) --from-file=osServicePrincipal.json -n $(CLUSTERPOOL_HOST_NAMESPACE)"

.PHONY: clusterpool/azure/delete-creds
## Deletes the secret CLUSTERPOOL_AZURE_CRED_NAME
clusterpool/azure/delete-creds: %azure/delete-creds: %_init
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_AZURE_CRED_NAME)
	@$(SELF) oc/command OC_COMMAND="delete secret -n $(CLUSTERPOOL_HOST_NAMESPACE) $(CLUSTERPOOL_AZURE_CRED_NAME)"

.PHONY: clusterpool/gcp/create-creds
## Create a hive credentials secret for GCP with input credentials
clusterpool/gcp/create-creds: %gcp/create-creds: %_init
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_GCP_CRED_NAME)
	$(call assert-set,CLUSTERPOOL_GCP_ACCOUNT_JSON_FILE)
	@$(SELF) oc/command OC_COMMAND="create secret generic $(CLUSTERPOOL_GCP_CRED_NAME) --from-file=$(CLUSTERPOOL_GCP_ACCOUNT_JSON_FILE) -n $(CLUSTERPOOL_HOST_NAMESPACE)"

.PHONY: clusterpool/gcp/delete-creds
## Deletes the secret CLUSTERPOOL_GCP_CRED_NAME
clusterpool/gcp/delete-creds: %gcp/delete-creds: %_init
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	$(call assert-set,CLUSTERPOOL_GCP_CRED_NAME)
	@$(SELF) oc/command OC_COMMAND="delete secret -n $(CLUSTERPOOL_HOST_NAMESPACE) $(CLUSTERPOOL_GCP_CRED_NAME)"

.PHONY: clusterpool/create-pull-secret
## Create an OCP pull secret for use in clusterpools
clusterpool/create-pull-secret: %create-pull-secret: %_init
	$(call assert-set,CLUSTERPOOL_PULL_SECRET_NAME)
	$(call assert-set,CLUSTERPOOL_PULL_SECRET_FILE)
	$(call assert-set,CLUSTERPOOL_HIVE_NAMESPACE)
	@$(SELF) oc/command OC_COMMAND="create secret generic $(CLUSTERPOOL_PULL_SECRET_NAME) --from-file=.dockerconfigjson=$(CLUSTERPOOL_PULL_SECRET_FILE) --type=kubernetes.io/dockerconfigjson --namespace $(CLUSTERPOOL_HIVE_NAMESPACE)"

.PHONY: clusterpool/delete-pull-secret
## Delete an OCP pull secret
clusterpool/delete-pull-secret: %delete-pull-secret: %_init
	$(call assert-set,CLUSTERPOOL_PULL_SECRET_NAME)
	$(call assert-set,CLUSTERPOOL_HIVE_NAMESPACE)
	@$(SELF) oc/command OC_COMMAND="delete secret $(CLUSTERPOOL_PULL_SECRET_NAME) --namespace $(CLUSTERPOOL_HIVE_NAMESPACE)"

.PHONY: clusterpool/create-claim
## Creates a cluster claim named CLUSTERPOOL_CLUSTER_CLAIM on the CLUSTERPOOL_NAME clusterpool in the CLUSTERPOOL_HOST_NAMESPACE namespace
clusterpool/create-claim: %create-claim: %_init
	$(call assert-set,CLUSTERPOOL_CLUSTER_CLAIM)
	$(call assert-set,CLUSTERPOOL_NAME)
	$(call assert-set,CLUSTERPOOL_HOST_NAMESPACE)
	@sed -e "s;__CLUSTERPOOL_CLUSTER_CLAIM__;$(CLUSTERPOOL_CLUSTER_CLAIM);g" -e "s;__CLUSTERPOOL_HOST_NAMESPACE__;$(CLUSTERPOOL_HOST_NAMESPACE);g" -e "s;__CLUSTERPOOL_NAME__;$(CLUSTERPOOL_NAME);g" $(BUILD_HARNESS_EXTENSIONS_PATH)/modules/clusterpool/templates/clusterclaim.yaml.template > clusterclaim.yaml
	@if [ -n "$(CLUSTERPOOL_DEBUG)" ]; then cat clusterclaim.yaml; fi
	@cat clusterclaim.yaml | kubectl apply -f -

.PHONY: clusterpool/verify-claim
## Takes in a CLUSTERPOOL_CLUSTER_CLAIM variable - the name of the claim to validate - and reports the status of the claim
clusterpool/verify-claim: %verify-claim: %_init
	$(call assert-set,CLUSTERPOOL_CLUSTER_CLAIM)
	@oc get ClusterClaim $(CLUSTERPOOL_CLUSTER_CLAIM) -o json > clusterclaim.namespace.yaml
	@jq -r [.status.conditions[0].type][] clusterclaim.namespace.yaml

.PHONY: clusterpool/delete-claim
## Deletes cluster claim named CLUSTERPOOL_CLUSTER_CLAIM
clusterpool/delete-claim: %delete-claim: %_init
	@$(SELF) -s oc/command OC_COMMAND="delete clusterclaim $(CLUSTERPOOL_CLUSTER_CLAIM)"

.PHONY: clusetrpool/checkout
## takes in a CLUSTERPOOL_CLUSTER_CLAIM variable - the name of the claim to create
clusetrpool/checkout: %checkout: %_init
	@echo unimplemented
	@exit 1

.PHONY: clusterpool/checkin
## Takes in a CLUSTERPOOL_CLUSTER_CLAIM variable - the name of the claim to delete
clusterpool/checkin: %checkin: %_init
	@echo unimplemented
	@exit 1

.PHONY: clusterpool/get-cluster-kubeconfig
## Takes in a CLUSTERPOOL_CLUSTER_CLAIM variable - the name of the claim to get creds from
clusterpool/get-cluster-kubeconfig: %get-cluster-kubeconfig: %_init %_init_namespace
	@$(SELF) -s oc/command OC_COMMAND="get ClusterDeployment -n `cat .namespace` -o json | jq -r '.items[].spec.clusterMetadata.adminKubeconfigSecretRef.name' > .adminKubeconfigSecretRef"
	@if [ -n "$(CLUSTERPOOL_DEBUG)" ]; then echo adminKubeconfigSecretRef:; cat .adminKubeconfigSecretRef; echo kubeconfig yaml:; fi
	@$(SELF) -s oc/command OC_COMMAND="get secret `cat .adminKubeconfigSecretRef` -n `cat .namespace` -o yaml"

.PHONY: clusterpool/get-cluster-username
## takes in a CLUSTERPOOL_CLUSTER_CLAIM variable - the name of the claim to get creds from
clusterpool/get-cluster-username: %get-cluster-username: %_init %_init_namespace
	@$(SELF) -s oc/command OC_COMMAND="get ClusterDeployment -n `cat .namespace` -o json | jq -r '.items[].spec.clusterMetadata.adminPasswordSecretRef.name' > .adminPasswordSecretRef"
	@if [ -n "$(CLUSTERPOOL_DEBUG)" ]; then echo adminPasswordSecretRef:; cat .adminPasswordSecretRef; echo username:; fi
	@$(SELF) -s oc/command OC_COMMAND="get secret `cat .adminPasswordSecretRef` -n `cat .namespace` -o json | jq -r '.data.username'"

.PHONY: clusterpool/get-cluster-password
## takes in a CLUSTERPOOL_CLUSTER_CLAIM variable - the name of the claim to get creds from
clusterpool/get-cluster-password: %get-cluster-password: %_init %_init_namespace
	@$(SELF) -s oc/command OC_COMMAND="get ClusterDeployment -n `cat .namespace` -o json | jq -r '.items[].spec.clusterMetadata.adminPasswordSecretRef.name' > .adminPasswordSecretRef"
	@if [ -n "$(CLUSTERPOOL_DEBUG)" ]; then echo adminPasswordSecretRef:; cat .adminPasswordSecretRef; echo password:; fi
	@$(SELF) -s oc/command OC_COMMAND="get secret `cat .adminPasswordSecretRef` -n `cat .namespace` -o json | jq -r '.data.password'"

.PHONY: clusterpool/get-cluster-api
## takes in a CLUSTERPOOL_CLUSTER_CLAIM variable - the name of the claim to get creds from
clusterpool/get-cluster-api: %get-cluster-api: %_init %_init_namespace
	@$(SELF) -s oc/command OC_COMMAND="get ClusterDeployment -n `cat .namespace` -o json | jq -r '.items[].status.apiURL'"

.PHONY: clusterpool/get-cluster-console
## takes in a CLUSTERPOOL_CLUSTER_CLAIM variable - the name of the claim to get creds from
clusterpool/get-cluster-console: %get-cluster-console: %_init %_init_namespace
	@$(SELF) -s oc/command OC_COMMAND="get ClusterDeployment -n `cat .namespace` -o json | jq -r '.items[].status.webConsoleURL'"

.PHONY: clusterpool/get-cluster-metadata
## takes in a CLUSTERPOOL_CLUSTER_CLAIM variable and a METADATA_FILE where it will dump the json cluster details - this will consume the previous focused creds
clusterpool/get-cluster-metadata: %get-cluster-metadata: %_init
	@echo unimplemented
	@exit 1
