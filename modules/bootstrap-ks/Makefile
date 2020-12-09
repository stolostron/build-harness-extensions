#-- bootstrap-ks Params---#
BOOTSTRAP_KS_REPO ?= https://${GITHUB_TOKEN}@github.com/open-cluster-management/bootstrap-ks.git
BOOTSTRAP_KS_BRANCH ?= master
BOOTSTRAP_KS_DEPLOY_DIR ?= bootstrap-ks

#---Login/Host-cluster related env vars---#
# API URL of the cluster running the target clusterpool, used in oc login, so port :6443 is required
BOOTSTRAP_KS_HOST_API ?=
# Access credentials used to log in to cluster indciated in BOOTSTRAP_KS_HOST_API
BOOTSTRAP_KS_HOST_USER ?=
BOOTSTRAP_KS_HOST_PASS ?=
BOOTSTRAP_KS_HOST_TOKEN ?=
# Namespace where Hive ClusterPool resources reside
BOOTSTRAP_KS_HOST_NAMESPACE ?= clusterpool

OC_CLUSTER_USER = BOOTSTRAP_KS_HOST_USER
OC_CLUSTER_PASS = BOOTSTRAP_KS_HOST_PASS
OC_CLUSTER_API = BOOTSTRAP_KS_HOST_API

CLUSTER_NAME_PREFIX ?= canary

#BOOTSTRAP_KS_AKS_CLUSTER_NAME ?=
BOOTSTRAP_KS_GKE_CLUSTER_NAME = $(shell cd ${BOOTSTRAP_KS_DEPLOY_DIR}/gke; cat *.json | jq -r .CLUSTER_NAME)


#GKE_CLUSTER_NAME = $(shell cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; cat *.json | jq -r .CLUSTER_NAME)
#QUERY_GKE_CLUSTER_NAME = $(eval THE_GKE_CLUSTER_NAME=$(GKE_CLUSTER_NAME))

# Convenience to just call bare jq executable
JQ ?= $(BUILD_HARNESS_PATH)/vendor/jq

.PHONY: bootstrap-ks/_init
# Install jq and oc cli and log in to the ClusterPool Host cluster
bootstrap-ks/_init: %_init:
	$(call assert-set,GITHUB_TOKEN)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
#	$(call assert-set,BOOTSTRAP_KS_HOST_TOKEN)
	@$(SELF) -s jq/install 2>&1 > /dev/null
	@if [ ! -e "$(BOOTSTRAP_KS_DEPLOY_DIR)" ]; then \
		git clone --single-branch --branch $(BOOTSTRAP_KS_BRANCH) $(BOOTSTRAP_KS_REPO); \
		cd $(BOOTSTRAP_KS_DEPLOY_DIR); fi
	@$(SELF) -s oc/login OC_CLUSTER_USER=$(BOOTSTRAP_KS_HOST_USER) OC_CLUSTER_PASS=$(BOOTSTRAP_KS_HOST_PASS) \
		OC_CLUSTER_URL=$(BOOTSTRAP_KS_HOST_API) OC_FORCE_LOGIN="true" OC_SILENT="true"




#	@$(SELF) -s oc/login OC_CLUSTER_USER=$(BOOTSTRAP_KS_HOST_USER) OC_CLUSTER_PASS=$(BOOTSTRAP_KS_HOST_PASS) OC_CLUSTER_TOKEN=$(BOOTSTRAP_KS_HOST_TOKEN) \
#		OC_CLUSTER_URL=$(BOOTSTRAP_KS_HOST_API) OC_FORCE_LOGIN="true" OC_SILENT="true"


##======= Azure Kubernetes Service ===========================

## Install AKS
.PHONY: bootstrap-ks/aks-install
bootstrap-ks/aks-install: %aks-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; ./install.sh; cd ../..;

.PHONY: bootstrap-ks/aks-create-cluster
## Create AKS cluster
bootstrap-ks/aks-create-cluster: %aks-create-cluster: %aks-install
	$(call assert-set,AZURE_USER)
	$(call assert-set,AZURE_PASS)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; ./provision.sh; \
	  KS_CLUSTER_NAME=`cat *.json | jq -r .CLUSTER_NAME`;

## Get AKS cluster name
.PHONY: bootstrap-ks/aks-get-cluster-name
bootstrap-ks/aks-get-cluster-name: %aks-get-cluster-name:
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; cat *.json | jq -r .CLUSTER_NAME; cd ../..;

## Delete AKS cluster
.PHONY: bootstrap-ks/aks-delete-cluster
bootstrap-ks/aks-delete-cluster: %aks-delete-cluster: %aks-install
	$(call assert-set,AZURE_USER)
	$(call assert-set,AZURE_PASS)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; ./destroy.sh *.json; cd ../..;


##======= Google Kubernetes Engine ===========================

## Install gks
.PHONY: bootstrap-ks/gke-install
bootstrap-ks/gke-install: %gke-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; ./install.sh; cd ../..;

## Create gke cluster
.PHONY: bootstrap-ks/gke-create-cluster
bootstrap-ks/gke-create-cluster: %gke-create-cluster: %gke-install
	$(call assert-set,GCLOUD_CREDS_FILE)
	$(call assert-set,GCLOUD_PROJECT_ID)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; ./provision.sh; cd ../..;

## Get gke cluster name
.PHONY: bootstrap-ks/gke-save-secret
bootstrap-ks/gke-save-secret: %gke-save-secret: %_init
	@$(SELF) -s oc/command OC_COMMAND="get nodes"
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) --from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/gke/$(BOOTSTRAP_KS_GKE_CLUSTER_NAME).json --from-file=kubeconfig=$(BOOTSTRAP_KS_DEPLOY_DIR)/gke/$(BOOTSTRAP_KS_GKE_CLUSTER_NAME).kubeconfig"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) bootstrap-ks=true"


## Get gke cluster name
.PHONY: bootstrap-ks/gke-get-cluster-name
bootstrap-ks/gke-get-cluster-name: %gke-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_GKE_CLUSTER_NAME)


## Get gke cluster kubeconfig
.PHONY: bootstrap-ks/gke-get-cluster-json
bootstrap-ks/gke-get-cluster-json: %gke-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_GKE_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"


## Get gke cluster kubeconfig
.PHONY: bootstrap-ks/gke-get-cluster-kubeconfig
bootstrap-ks/gke-get-cluster-kubeconfig: %gke-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_GKE_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig | base64 -d"

## Delete gke cluster
##  Default is to assume the file is stored locally when cluster was created.
## OPTIONAL:
##   BOOTSTRAP_KS_GKE_JSON_FILE - path to the json file for the GKE instance
.PHONY: bootstrap-ks/gke-delete-cluster
bootstrap-ks/gke-delete-cluster: %gke-delete-cluster: %aks-install
	$(call assert-set,GCLOUD_CREDS_FILE)
	$(call assert-set,GCLOUD_PROJECT_ID)
	@if [ ! -z "$(BOOTSTRAP_KS_GKE_JSON_FILE)" ]; then \
   	cd ${BOOTSTRAP_KS_DEPLOY_DIR}/gke; ./destroy.sh ${BOOTSTRAP_KS_GKE_JSON_FILE}; \
	else \
		cd ${BOOTSTRAP_KS_DEPLOY_DIR}/gke; ./destroy.sh *.json; \
	fi;


#.PHONY: bootstrap-ks/clean
## Clean up all bootstrap-ks resources
#bootstrap-ks/clean: %clean:
#	ifeq ($(shell test -d $(BOOTSTRAP_KS_DIR) && echo -n yes),yes)
#		@rm -rf $(BOOTSTRAP_KS_DIR)
#	endif
