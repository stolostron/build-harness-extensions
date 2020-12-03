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



CLUSTER_NAME_PREFIX ?= canary

BOOTSTRAP_KS_AKS_CLUSTERNAME ?=
BOOTSTRAP_KS_GKE_CLUSTERNAME ?=


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
	echo "--- Hub Nodes:"
	@$(SELF) -s oc/command OC_COMMAND="get nodes"



#	@$(SELF) -s oc/login OC_CLUSTER_USER=$(BOOTSTRAP_KS_HOST_USER) OC_CLUSTER_PASS=$(BOOTSTRAP_KS_HOST_PASS) OC_CLUSTER_TOKEN=$(BOOTSTRAP_KS_HOST_TOKEN) \
#		OC_CLUSTER_URL=$(BOOTSTRAP_KS_HOST_API) OC_FORCE_LOGIN="true" OC_SILENT="true"


##======= AKS

.PHONY: bootstrap-ks/aks-install
## Install *ks
bootstrap-ks/aks-install: %aks-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; ./install.sh; cd ../..;

.PHONY: bootstrap-ks/aks-create-cluster
## Create AKS cluster
bootstrap-ks/aks-create-cluster: %aks-create-cluster: %aks-install
	$(call assert-set,AZURE_USER)
	$(call assert-set,AZURE_PASS)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; ./provision.sh; cd ../..;

#oc create secret generic cahl-ihx22-eks --from-file=json=cahl-ihx22-eks.json --from-file=kubeconfig=cahl-ihx22-eks.kubeconfig
#export BUILD_HARNESS_ARCH ?= $(shell uname -m | sed 's/x86_64/amd64/g')

.PHONY: bootstrap-ks/aks-get-cluster-name
## Get AKS cluster name
bootstrap-ks/aks-get-cluster-name: %aks-get-cluster-name:
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; cat *.json | jq -r .CLUSTER_NAME; cd ../..;

.PHONY: bootstrap-ks/aks-delete-cluster
## Delete AKS cluster
bootstrap-ks/aks-delete-cluster: %aks-delete-cluster: %aks-install
	$(call assert-set,AZURE_USER)
	$(call assert-set,AZURE_PASS)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; ./destroy.sh *.json; cd ../..;


##======= GKE

.PHONY: bootstrap-ks/gke-install
## Install *ks
bootstrap-ks/gke-install: %gke-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; ./install.sh; cd ../..;

.PHONY: bootstrap-ks/gke-create-cluster
## Create gke cluster
bootstrap-ks/gke-create-cluster: %gke-create-cluster: %gke-install
	$(call assert-set,GCLOUD_CREDS_FILE)
	$(call assert-set,GCLOUD_PROJECT_ID)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; ./provision.sh; cd ../..;

.PHONY: bootstrap-ks/gke-get-cluster-name
## Get gke cluster name
bootstrap-ks/gke-get-cluster-name: %gke-get-cluster-name: %gke-install
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; cat *.json | jq -r .CLUSTER_NAME; cd ../..;

.PHONY: bootstrap-ks/gke-delete-cluster
## Delete gke cluster
bootstrap-ks/gke-delete-cluster: %gke-delete-cluster: %gke-install
	$(call assert-set,GCLOUD_CREDS_FILE)
	$(call assert-set,GCLOUD_PROJECT_ID)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; ./destroy.sh *.json; cd ../..;





#.PHONY: bootstrap-ks/clean
## Clean up all bootstrap-ks resources
#bootstrap-ks/clean: %clean:
#	ifeq ($(shell test -d $(BOOTSTRAP_KS_DIR) && echo -n yes),yes)
#		@rm -rf $(BOOTSTRAP_KS_DIR)
#	endif
