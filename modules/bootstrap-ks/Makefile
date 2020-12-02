#-- bootstrap-ks Params---#
BOOTSTRAP_KS_REPO ?= https://${GITHUB_TOKEN}@github.com/open-cluster-management/bootstrap-ks.git
BOOTSTRAP_KS_BRANCH ?= master
BOOTSTRAP_KS_DEPLOY_DIR ?= bootstrap-ks

CLUSTER_NAME_PREFIX ?= canary

# Convenience to just call bare jq executable
JQ ?= $(BUILD_HARNESS_PATH)/vendor/jq

.PHONY: bootstrap-ks/_init
# Install jq and oc cli and log in to the ClusterPool Host cluster
bootstrap-ks/_init: %_init:
	$(call assert-set,GITHUB_TOKEN)
	@$(SELF) -s jq/install 2>&1 > /dev/null
	@git clone --single-branch --branch $(BOOTSTRAP_KS_BRANCH) $(BOOTSTRAP_KS_REPO)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)


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

#.PHONY: bootstrap-ks/clean
## Clean up all bootstrap-ks resources
#bootstrap-ks/clean: %clean:
#	ifeq ($(shell test -d $(BOOTSTRAP_KS_DIR) && echo -n yes),yes)
#		@rm -rf $(BOOTSTRAP_KS_DIR)
#	endif
