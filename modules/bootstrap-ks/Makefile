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

# These will only have a value if the cluster has been deployed.  (Only one per type is allowed)
BOOTSTRAP_KS_AKS_CLUSTER_NAME = $(shell cd ${BOOTSTRAP_KS_DEPLOY_DIR}/aks; cat *.json | jq -r .CLUSTER_NAME)
BOOTSTRAP_KS_GKE_CLUSTER_NAME = $(shell cd ${BOOTSTRAP_KS_DEPLOY_DIR}/gke; cat *.json | jq -r .CLUSTER_NAME)
BOOTSTRAP_KS_EKS_CLUSTER_NAME = $(shell cd ${BOOTSTRAP_KS_DEPLOY_DIR}/eks; cat *.json | jq -r .CLUSTER_NAME)
BOOTSTRAP_KS_IKS_CLUSTER_NAME = $(shell cd ${BOOTSTRAP_KS_DEPLOY_DIR}/iks; cat *.json | jq -r .CLUSTER_NAME)

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

##======= Azure Kubernetes Service ===========================

## Install AKS
.PHONY: bootstrap-ks/aks-install
bootstrap-ks/aks-install: %aks-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; ./install.sh;

.PHONY: bootstrap-ks/aks-create-cluster
## Create AKS cluster
bootstrap-ks/aks-create-cluster: %aks-create-cluster: %aks-install
	$(call assert-set,AZURE_USER)
	$(call assert-set,AZURE_PASS)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; ./provision.sh;

## Get AKS cluster name
.PHONY: bootstrap-ks/aks-save-secret
bootstrap-ks/aks-save-secret: %aks-save-secret: %_init
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_AKS_CLUSTER_NAME) --from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/aks/$(BOOTSTRAP_KS_AKS_CLUSTER_NAME).json --from-file=kubeconfig=$(BOOTSTRAP_KS_DEPLOY_DIR)/aks/$(BOOTSTRAP_KS_AKS_CLUSTER_NAME).kubeconfig"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_AKS_CLUSTER_NAME) bootstrap-ks=true"


## Get AKS cluster name
.PHONY: bootstrap-ks/aks-get-cluster-name
bootstrap-ks/aks-get-cluster-name: %aks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_AKS_CLUSTER_NAME)

## Get AKS cluster kubeconfig
.PHONY: bootstrap-ks/aks-get-cluster-json
bootstrap-ks/aks-get-cluster-json: %aks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_AKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_AKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"


## Get AKS cluster kubeconfig
.PHONY: bootstrap-ks/aks-get-cluster-kubeconfig
bootstrap-ks/aks-get-cluster-kubeconfig: %aks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_AKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_AKS_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig | base64 -d"

## Delete AKS cluster
##  Default is to assume the file is stored locally when cluster was created.
## OPTIONAL:
##   BOOTSTRAP_KS_AKS_JSON_FILE - path to the json file for the AKS instance
.PHONY: bootstrap-ks/aks-delete-cluster
bootstrap-ks/aks-delete-cluster: %aks-delete-cluster: %aks-install
	$(call assert-set,AZURE_USER)
	$(call assert-set,AZURE_PASS)
	@if [ ! -z "$(BOOTSTRAP_KS_AKS_JSON_FILE)" ]; then \
	  cd ${BOOTSTRAP_KS_DEPLOY_DIR}/aks; ./destroy.sh ${BOOTSTRAP_KS_AKS_JSON_FILE}; \
	else \
		cd ${BOOTSTRAP_KS_DEPLOY_DIR}/aks; ./destroy.sh *.json; \
	fi;


##======= Amazon Elastic Kubernetes Service ===========================

## Install EKS
.PHONY: bootstrap-ks/eks-install
bootstrap-ks/eks-install: %eks-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/eks; ./install.sh;

## Create EKS cluster
.PHONY: bootstrap-ks/eks-create-cluster
bootstrap-ks/eks-create-cluster: %eks-create-cluster: %eks-install
	$(call assert-set,AWS_ACCESS_KEY_ID)
	$(call assert-set,AWS_SECRET_ACCESS_KEY)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/eks; ./provision.sh;

## Get EKS cluster name
.PHONY: bootstrap-ks/eks-save-secret
bootstrap-ks/eks-save-secret: %eks-save-secret: %_init
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_EKS_CLUSTER_NAME) --from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/eks/$(BOOTSTRAP_KS_EKS_CLUSTER_NAME).json --from-file=kubeconfig=$(BOOTSTRAP_KS_DEPLOY_DIR)/eks/$(BOOTSTRAP_KS_EKS_CLUSTER_NAME).kubeconfig"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_EKS_CLUSTER_NAME) bootstrap-ks=true"


## Get EKS cluster name
.PHONY: bootstrap-ks/eks-get-cluster-name
bootstrap-ks/eks-get-cluster-name: %eks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_EKS_CLUSTER_NAME)


## Get EKS cluster kubeconfig
.PHONY: bootstrap-ks/eks-get-cluster-json
bootstrap-ks/eks-get-cluster-json: %eks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_EKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_EKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"


## Get EKS cluster kubeconfig
.PHONY: bootstrap-ks/eks-get-cluster-kubeconfig
bootstrap-ks/eks-get-cluster-kubeconfig: %eks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_EKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_EKS_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig | base64 -d"

## Delete EKS cluster
##  Default is to assume the file is stored locally when cluster was created.
## OPTIONAL:
##   BOOTSTRAP_KS_EKS_JSON_FILE - path to the json file for the EKS instance
.PHONY: bootstrap-ks/eks-delete-cluster
bootstrap-ks/eks-delete-cluster: %eks-delete-cluster: %aks-install
	$(call assert-set,AWS_ACCESS_KEY_ID)
	$(call assert-set,AWS_SECRET_ACCESS_KEY)
	@if [ ! -z "$(BOOTSTRAP_KS_EKS_JSON_FILE)" ]; then \
   	cd ${BOOTSTRAP_KS_DEPLOY_DIR}/eks; ./destroy.sh ${BOOTSTRAP_KS_EKS_JSON_FILE}; \
	else \
		cd ${BOOTSTRAP_KS_DEPLOY_DIR}/eks; ./destroy.sh *.json; \
	fi;


##======= Google Kubernetes Engine ===========================

## Install GKE
.PHONY: bootstrap-ks/gke-install
bootstrap-ks/gke-install: %gke-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; ./install.sh;

## Create gke cluster
.PHONY: bootstrap-ks/gke-create-cluster
bootstrap-ks/gke-create-cluster: %gke-create-cluster: %gke-install
	$(call assert-set,GCLOUD_CREDS_FILE)
	$(call assert-set,GCLOUD_PROJECT_ID)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; ./provision.sh;

## Get gke cluster name
.PHONY: bootstrap-ks/gke-save-secret
bootstrap-ks/gke-save-secret: %gke-save-secret: %_init
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) --from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/gke/$(BOOTSTRAP_KS_GKE_CLUSTER_NAME).json --from-file=kubeconfig=$(BOOTSTRAP_KS_DEPLOY_DIR)/gke/$(BOOTSTRAP_KS_GKE_CLUSTER_NAME).kubeconfig"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) bootstrap-ks=true"


## Get GKE cluster name
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


##======= IBM Cloud Kubernetes Service (IKS) and IBM Red Hat OpenShift Kubernetes Service (ROKS) ===========================

## Install IKS
.PHONY: bootstrap-ks/iks-install
bootstrap-ks/iks-install: %iks-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/iks; ./install.sh;

## Create IKS cluster
.PHONY: bootstrap-ks/iks-create-cluster
bootstrap-ks/iks-create-cluster: %iks-create-cluster: %iks-install
	$(call assert-set,IBMCLOUD_APIKEY)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/iks; ./provision.sh;

## Get IKS cluster name
.PHONY: bootstrap-ks/iks-save-secret
bootstrap-ks/iks-save-secret: %iks-save-secret: %_init
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_IKS_CLUSTER_NAME) --from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/iks/$(BOOTSTRAP_KS_IKS_CLUSTER_NAME).json --from-file=kubeconfig=$(BOOTSTRAP_KS_DEPLOY_DIR)/iks/$(BOOTSTRAP_KS_IKS_CLUSTER_NAME).kubeconfig"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_IKS_CLUSTER_NAME) bootstrap-ks=true"

## Get IKS cluster name
.PHONY: bootstrap-ks/iks-get-cluster-name
bootstrap-ks/iks-get-cluster-name: %iks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_IKS_CLUSTER_NAME)


## Get IKS cluster kubeconfig
.PHONY: bootstrap-ks/iks-get-cluster-json
bootstrap-ks/iks-get-cluster-json: %iks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_IKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_IKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"


## Get IKS cluster kubeconfig
.PHONY: bootstrap-ks/iks-get-cluster-kubeconfig
bootstrap-ks/iks-get-cluster-kubeconfig: %iks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_IKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_IKS_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig | base64 -d"

## Delete IKS cluster
##  Default is to assume the file is stored locally when cluster was created.
## OPTIONAL:
##   BOOTSTRAP_KS_IKS_JSON_FILE - path to the json file for the IKS instance
.PHONY: bootstrap-ks/iks-delete-cluster
bootstrap-ks/iks-delete-cluster: %iks-delete-cluster: %aks-install
	$(call assert-set,IBMCLOUD_APIKEY)
	@if [ ! -z "$(BOOTSTRAP_KS_IKS_JSON_FILE)" ]; then \
   	cd ${BOOTSTRAP_KS_DEPLOY_DIR}/iks; ./destroy.sh ${BOOTSTRAP_KS_IKS_JSON_FILE}; \
	else \
		cd ${BOOTSTRAP_KS_DEPLOY_DIR}/iks; ./destroy.sh *.json; \
	fi;
