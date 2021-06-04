#-- bootstrap-ks Params---#
BOOTSTRAP_KS_REPO ?= https://${GITHUB_TOKEN}@github.com/open-cluster-management/bootstrap-ks.git
BOOTSTRAP_KS_BRANCH ?= main
BOOTSTRAP_KS_DEPLOY_DIR ?= bootstrap-ks

#---Login/Host-cluster related env vars---#
# API URL of the cluster running the target clusterpool, used in oc login, so port :6443 is required
BOOTSTRAP_KS_HOST_API ?= $(CLUSTERPOOL_HOST_API)
# Access credentials used to log in to cluster indciated in BOOTSTRAP_KS_HOST_API
BOOTSTRAP_KS_HOST_USER ?= $(CLUSTERPOOL_HOST_USER)
BOOTSTRAP_KS_HOST_PASS ?= $(CLUSTERPOOL_HOST_PASS)
BOOTSTRAP_KS_HOST_TOKEN ?= $(CLUSTERPOOL_HOST_TOKEN)
# Namespace where Hive ClusterPool resources reside
BOOTSTRAP_KS_HOST_NAMESPACE ?= clusterpool

BOOTSTRAP_KS_DEBUG ?= $(CLUSTERPOOL_DEBUG)

OC_CLUSTER_USER ?= $(BOOTSTRAP_KS_HOST_USER)
OC_CLUSTER_PASS ?= $(BOOTSTRAP_KS_HOST_PASS)
OC_CLUSTER_TOKEN ?= $(BOOTSTRAP_KS_HOST_TOKEN)
OC_CLUSTER_API ?= $(BOOTSTRAP_KS_HOST_API)

CLUSTER_NAME_PREFIX ?= canary

# These will only have a value if the cluster has been deployed.  (Only one per type is allowed)
BOOTSTRAP_KS_AKS_CLUSTER_NAME = $(shell cat ${BOOTSTRAP_KS_DEPLOY_DIR}/aks/*.json | $(JQ) -r .CLUSTER_NAME)
BOOTSTRAP_KS_GKE_CLUSTER_NAME = $(shell cat ${BOOTSTRAP_KS_DEPLOY_DIR}/gke/*.json | $(JQ) -r .CLUSTER_NAME)
BOOTSTRAP_KS_EKS_CLUSTER_NAME = $(shell cat ${BOOTSTRAP_KS_DEPLOY_DIR}/eks/*.json | $(JQ) -r .CLUSTER_NAME)
BOOTSTRAP_KS_IKS_CLUSTER_NAME = $(shell cat ${BOOTSTRAP_KS_DEPLOY_DIR}/iks/*-iks.json | $(JQ) -r .CLUSTER_NAME)
BOOTSTRAP_KS_ROKS_CLUSTER_NAME = $(shell cat ${BOOTSTRAP_KS_DEPLOY_DIR}/iks/*-roks.json | $(JQ) -r .CLUSTER_NAME)
BOOTSTRAP_KS_ARO_CLUSTER_NAME ?= ${BOOTSTRAP_KS_CLUSTER_NAME}

# Convenience to just call bare jq executable
JQ ?= $(BUILD_HARNESS_PATH)/vendor/jq


##======= Common  ===========================

.PHONY: bootstrap-ks/_init
# Install jq and oc cli and log in to the ClusterPool Host cluster
bootstrap-ks/_init: %_init:
	$(call assert-set,GITHUB_TOKEN)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	@$(SELF) -s jq/install 2>&1 > /dev/null
	@if [ ! -e "$(BOOTSTRAP_KS_DEPLOY_DIR)" ]; then \
		git clone --single-branch --branch $(BOOTSTRAP_KS_BRANCH) $(BOOTSTRAP_KS_REPO); \
		cd $(BOOTSTRAP_KS_DEPLOY_DIR); fi
	@$(SELF) -s oc/login OC_CLUSTER_USER=$(BOOTSTRAP_KS_HOST_USER) OC_CLUSTER_PASS=$(BOOTSTRAP_KS_HOST_PASS) \
		OC_CLUSTER_TOKEN=$(BOOTSTRAP_KS_HOST_TOKEN) OC_CLUSTER_URL=$(BOOTSTRAP_KS_HOST_API) OC_FORCE_LOGIN="true" OC_SILENT="true"


.PHONY: bootstrap-ks/get-cluster-kubeconfig
## Get cluster KUBECONFIG from secret
bootstrap-ks/get-cluster-kubeconfig: %get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig" > $(BUILD_HARNESS_PATH)/.tmp_kubeconfig
	@if [[ `cat ${BUILD_HARNESS_PATH}/.tmp_kubeconfig` == "null" ]]; then \
		$(SELF) -s bootstrap-ks/get-cluster-username BOOTSTRAP_KS_CLUSTER_NAME=$(BOOTSTRAP_KS_CLUSTER_NAME) BOOTSTRAP_KS_HOST_NAMESPACE=$(BOOTSTRAP_KS_HOST_NAMESPACE) > $(BUILD_HARNESS_PATH)/.kc_un; \
		$(SELF) -s bootstrap-ks/get-cluster-password BOOTSTRAP_KS_CLUSTER_NAME=$(BOOTSTRAP_KS_CLUSTER_NAME) BOOTSTRAP_KS_HOST_NAMESPACE=$(BOOTSTRAP_KS_HOST_NAMESPACE) > $(BUILD_HARNESS_PATH)/.kc_pw; \
		$(SELF) -s bootstrap-ks/get-cluster-api BOOTSTRAP_KS_CLUSTER_NAME=$(BOOTSTRAP_KS_CLUSTER_NAME) BOOTSTRAP_KS_HOST_NAMESPACE=$(BOOTSTRAP_KS_HOST_NAMESPACE) > $(BUILD_HARNESS_PATH)/.kc_api; \
		if [[ "`cat $(BUILD_HARNESS_PATH)/.kc_un`" != "null" && "`cat $(BUILD_HARNESS_PATH)/.kc_pw`" != null && "`cat $(BUILD_HARNESS_PATH)/.kc_api`" != "null" ]]; then \
			rm -f $(BUILD_HARNESS_PATH)/.tmp_kubeconfig; \
			$(SELF) -s oc/install &> /dev/null; \
			KUBECONFIG=$(BUILD_HARNESS_PATH)/.tmp_kubeconfig \
				$(OC) login "`cat $(BUILD_HARNESS_PATH)/.kc_api`" \
				--username="`cat $(BUILD_HARNESS_PATH)/.kc_un`" \
				--password="`cat $(BUILD_HARNESS_PATH)/.kc_pw`" \
				--insecure-skip-tls-verify=true &> /dev/null; \
		else \
			exit 1; \
		fi; \
	else \
		cat $(BUILD_HARNESS_PATH)/.tmp_kubeconfig | base64 -d > $(BUILD_HARNESS_PATH)/.tmp_kc && mv $(BUILD_HARNESS_PATH)/.tmp_kc $(BUILD_HARNESS_PATH)/.tmp_kubeconfig; \
	fi;
	@cat $(BUILD_HARNESS_PATH)/.tmp_kubeconfig
	@rm -f $(BUILD_HARNESS_PATH)/.tmp_kubeconfig $(BUILD_HARNESS_PATH)/.kc_api $(BUILD_HARNESS_PATH)/.kc_pw $(BUILD_HARNESS_PATH)/.kc_un &> /dev/null


.PHONY: bootstrap-ks/get-cluster-username
## Get cluster username from secret
bootstrap-ks/get-cluster-username: %get-cluster-username: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.username | base64 -d"

.PHONY: bootstrap-ks/get-cluster-password
## Get cluster password from secret
bootstrap-ks/get-cluster-password: %get-cluster-password: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.password | base64 -d"

.PHONY: bootstrap-ks/get-cluster-api
## Get cluster api from secret
bootstrap-ks/get-cluster-api: %get-cluster-api: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.api_url | base64 -d"

.PHONY: bootstrap-ks/get-cluster-console
## Get cluster console from secret
bootstrap-ks/get-cluster-console: %get-cluster-console: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.console_url | base64 -d"

.PHONY: bootstrap-ks/get-cluster-basedomain
## Get cluster basedomain from secret
bootstrap-ks/get-cluster-basedomain: %get-cluster-basedomain: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.basedomain | base64 -d"

.PHONY: bootstrap-ks/get-cluster-claim
## Get cluster claim from secret
bootstrap-ks/get-cluster-claim: %get-cluster-claim: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.clusterclaim | base64 -d"

.PHONY: bootstrap-ks/get-cluster-claim-namespace
## Get cluster claim from secret
bootstrap-ks/get-cluster-claim-namespace: %get-cluster-claim-namespace: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.clusterclaim_namespace | base64 -d"

.PHONY: bootstrap-ks/get-cluster-cloud-platform
## Get cluster cloud-platform from secret
bootstrap-ks/get-cluster-cloud-platform: %get-cluster-cloud-platform: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.cloud_platform | base64 -d"

.PHONY: bootstrap-ks/get-cluster-json
## Get cluster cloud-platform from secret
bootstrap-ks/get-cluster-json: %get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"

.PHONY: bootstrap-ks/get-cluster-type
## Get cluster type from secret
bootstrap-ks/get-cluster-type: %get-cluster-type: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r '.metadata.labels[\"bootstrap-ks-type\"]'"

.PHONY: bootstrap-ks/get-secret-type
## Get secret type from secret - this tells us what format the secret will be in, and what metadata will be present
bootstrap-ks/get-secret-type: %get-secret-type: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r '.metadata.labels[\"bootstrap-ks-secret-type\"]'"

.PHONY: bootstrap-ks/get-cluster-metadata
## takes in a BOOTSTRAP_KS_CLUSTER_NAME and host api and extracts credentials for access - outputting into a single JSON and `kubeconfig` file
bootstrap-ks/get-cluster-metadata: %get-cluster-metadata:
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_METADATA_FILE)
	@$(SELF) -s bootstrap-ks/get-cluster-type > .ct
	@$(SELF) -s bootstrap-ks/get-secret-type > .st
	@$(SELF) -s bootstrap-ks/get-cluster-kubeconfig > $(PWD)/$(BOOTSTRAP_KS_CLUSTER_NAME).kubeconfig;
	@if [[ `cat .ct` == "ocp" ]]; then \
		$(SELF) -s bootstrap-ks/get-cluster-username > .un; \
		$(SELF) -s bootstrap-ks/get-cluster-password > .pw;\
		$(SELF) -s bootstrap-ks/get-cluster-api > .api; \
		$(SELF) -s bootstrap-ks/get-cluster-basedomain > .bd; \
		$(SELF) -s bootstrap-ks/get-cluster-cloud-platform > .pf; \
		$(SELF) -s bootstrap-ks/get-cluster-console > .con; fi;
	@if [[ `cat .st` == "clusterclaim" ]]; then \
		$(SELF) -s bootstrap-ks/get-cluster-claim > .cc; \
		$(SELF) -s bootstrap-ks/get-cluster-claim > .ccns; fi;
	@if [[ `cat .st` == "aro" ]]; then \
		$(SELF) -s bootstrap-ks/get-cluster-json > ${BOOTSTRAP_KS_METADATA_FILE}.aro.raw.json; fi;
	@echo "{}" > gc1.json
	@$(JQ) --arg type `cat .ct` '. + {type: $$type}' gc1.json > .tmp; mv .tmp gc1.json
	@$(JQ) --arg secret_type `cat .st` '. + {secret_type: $$secret_type}' gc1.json > .tmp; mv .tmp gc1.json
	@$(JQ) --arg kubeconfig $(PWD)/$(BOOTSTRAP_KS_CLUSTER_NAME).kubeconfig '. + {kubeconfig: $$kubeconfig}' gc1.json > .tmp; mv .tmp gc1.json;
	@if [[ `cat .ct` == "ocp" ]]; then \
		$(JQ) --arg username `cat .un` '. + {username: $$username}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg password `cat .pw` '. + {password: $$password}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg api_url `cat .api` '. + {api_url: $$api_url}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg basedomain `cat .bd` '. + {basedomain: $$basedomain}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg cloudplatform `cat .pf` '. + {cloud_platform: $$cloudplatform}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg console_url `cat .con` '. + {console_url: $$console_url}' gc1.json > .tmp; mv .tmp gc1.json; fi;
	@if [[ `cat .st` == "clusterclaim" ]]; then \
		$(JQ) --arg clusterclaim `cat .cc` '. + {clusterclaim: $$clusterclaim}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg clusterclaim_namespace `cat .ccns` '. + {clusterclaim_namespace: $$clusterclaim_namespace}' gc1.json > .tmp; mv .tmp gc1.json; fi;
	@cat gc1.json > $(BOOTSTRAP_KS_METADATA_FILE)
	@rm -f .ct .st .cc .pf .ccns .un .pw .api .con gc1.json
	@cat $(BOOTSTRAP_KS_METADATA_FILE)

.PHONY: bootstrap-ks/delete-cluster
## Delete a target cluster cluster. 
bootstrap-ks/delete-cluster: %delete-cluster: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s bootstrap-ks/get-secret-type > .st
	@if [[ `cat .st` == "clusterclaim" ]]; then \
		$(SELF) bootstrap-ks/clusterclaim-delete-cluster \
			BOOTSTRAP_KS_CC_NAME=`$(SELF) -s bootstrap-ks/get-cluster-claim` \
			BOOTSTRAP_KS_CC_NAMESPACE=`$(SELF) -s bootstrap-ks/get-cluster-claim-namespace`; \
	elif [[ `cat .st` == "aks" ]]; then \
		$(SELF) bootstrap-ks/aks-delete-cluster; \
	elif [[ `cat .st` == "eks" ]]; then \
		$(SELF) bootstrap-ks/eks-delete-cluster; \
	elif [[ `cat .st` == "iks" ]]; then \
		$(SELF) bootstrap-ks/iks-delete-cluster; \
	elif [[ `cat .st` == "roks" ]]; then \
		$(SELF) bootstrap-ks/roks-delete-cluster; \
	elif [[ `cat .st` == "gke" ]]; then \
		$(SELF) bootstrap-ks/gke-delete-cluster; \
	elif [[ `cat .st` == "aro" ]]; then \
		$(SELF) bootstrap-ks/aro-delete-cluster BOOTSTRAP_KS_CLUSTER_NAME=$(BOOTSTRAP_KS_CLUSTER_NAME); \
	fi;

.PHONY: bootstrap-ks/delete-secret
## Delete *KS secret.  You can filter these secrets using --selector=bootstrap-ks=true
bootstrap-ks/delete-secret: %delete-secret: %_init
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="delete secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME)"


##======= OpenShift ===========================

.PHONY: bootstrap-ks/clusterclaim-save-secret
## Save OCP metadata and KUBECONFIG as a secret.  You can filter these secrets using --selector=bootstrap-ks=false --bootstrap-ks-secret-type=clusterclaim
bootstrap-ks/clusterclaim-save-secret: %clusterclaim-save-secret: %_init
	$(call assert-set,BOOTSTRAP_KS_CC_CONSOLE_URL)
	$(call assert-set,BOOTSTRAP_KS_CC_API_URL)
	$(call assert-set,BOOTSTRAP_KS_CC_USERNAME)
	$(call assert-set,BOOTSTRAP_KS_CC_PASSWORD)
	$(call assert-set,BOOTSTRAP_KS_CC_KUBECONFIG_FILE)
	$(call assert-set,BOOTSTRAP_KS_CC_NAME)
	$(call assert-set,BOOTSTRAP_KS_CC_NAMESPACE)
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_CLOUD_PLATFORM)
	$(call assert-set,BOOTSTRAP_KS_BASEDOMAIN)
	$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) \
		--from-file=kubeconfig=$(BOOTSTRAP_KS_CC_KUBECONFIG_FILE) \
		--from-literal=username=$(BOOTSTRAP_KS_CC_USERNAME) \
		--from-literal=password=$(BOOTSTRAP_KS_CC_PASSWORD) \
		--from-literal=api_url=$(BOOTSTRAP_KS_CC_API_URL)\ 
		--from-literal=console_url=$(BOOTSTRAP_KS_CC_CONSOLE_URL) \
		--from-literal=clusterclaim_namespace=$(BOOTSTRAP_KS_CC_NAMESPACE) \
		--from-literal=cloud_platform=$(BOOTSTRAP_KS_CLOUD_PLATFORM) \
		--from-literal=clusterclaim=$(BOOTSTRAP_KS_CC_NAME)"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks=false"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-type=ocp"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-secret-type=clusterclaim"


.PHONY: bootstrap-ks/clusterclaim-save-secret-from-claim
## Save OCP metadata and KUBECONFIG as a secret.  You can filter these secrets using --selector=bootstrap-ks=false --bootstrap-ks-secret-type=clusterclaim
bootstrap-ks/clusterclaim-save-secret-from-claim: %clusterclaim-save-secret-from-claim: %_init
	$(call assert-set,BOOTSTRAP_KS_CC_NAME)
	$(call assert-set,BOOTSTRAP_KS_CC_NAMESPACE)
	$(call assert-set,BOOTSTRAP_KS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_CLOUD_PLATFORM)
	@$(SELF) -s clusterpool/get-cluster-kubeconfig \
		CLUSTERPOOL_CLUSTER_CLAIM=$(BOOTSTRAP_KS_CC_NAME) \
		CLUSTERPOOL_HOST_NAMESPACE=$(BOOTSTRAP_KS_CC_NAMESPACE) \
		CLUSTERPOOL_HOST_API=$(BOOTSTRAP_KS_HOST_API) \
		CLUSTERPOOL_HOST_USER=$(BOOTSTRAP_KS_HOST_USER) \
		CLUSTERPOOL_HOST_PASS=$(BOOTSTRAP_KS_HOST_PASS) \
		CLUSTERPOOL_HOST_TOKEN=$(BOOTSTRAP_KS_HOST_TOKEN) > $(BUILD_HARNESS_PATH)/.kc
	@$(SELF) -s clusterpool/get-cluster-username \
		CLUSTERPOOL_CLUSTER_CLAIM=$(BOOTSTRAP_KS_CC_NAME) \
		CLUSTERPOOL_HOST_NAMESPACE=$(BOOTSTRAP_KS_CC_NAMESPACE) \
		CLUSTERPOOL_HOST_API=$(BOOTSTRAP_KS_HOST_API) \
		CLUSTERPOOL_HOST_USER=$(BOOTSTRAP_KS_HOST_USER) \
		CLUSTERPOOL_HOST_PASS=$(BOOTSTRAP_KS_HOST_PASS) \
		CLUSTERPOOL_HOST_TOKEN=$(BOOTSTRAP_KS_HOST_TOKEN) > $(BUILD_HARNESS_PATH)/.un
	@$(SELF) -s clusterpool/get-cluster-password \
		CLUSTERPOOL_CLUSTER_CLAIM=$(BOOTSTRAP_KS_CC_NAME) \
		CLUSTERPOOL_HOST_NAMESPACE=$(BOOTSTRAP_KS_CC_NAMESPACE) \
		CLUSTERPOOL_HOST_API=$(BOOTSTRAP_KS_HOST_API) \
		CLUSTERPOOL_HOST_USER=$(BOOTSTRAP_KS_HOST_USER) \
		CLUSTERPOOL_HOST_PASS=$(BOOTSTRAP_KS_HOST_PASS) \
		CLUSTERPOOL_HOST_TOKEN=$(BOOTSTRAP_KS_HOST_TOKEN) > $(BUILD_HARNESS_PATH)/.pw
	@$(SELF) -s clusterpool/get-cluster-api \
		CLUSTERPOOL_CLUSTER_CLAIM=$(BOOTSTRAP_KS_CC_NAME) \
		CLUSTERPOOL_HOST_NAMESPACE=$(BOOTSTRAP_KS_CC_NAMESPACE) \
		CLUSTERPOOL_HOST_API=$(BOOTSTRAP_KS_HOST_API) \
		CLUSTERPOOL_HOST_USER=$(BOOTSTRAP_KS_HOST_USER) \
		CLUSTERPOOL_HOST_PASS=$(BOOTSTRAP_KS_HOST_PASS) \
		CLUSTERPOOL_HOST_TOKEN=$(BOOTSTRAP_KS_HOST_TOKEN) > $(BUILD_HARNESS_PATH)/.ap
	@$(SELF) -s clusterpool/get-cluster-console \
		CLUSTERPOOL_CLUSTER_CLAIM=$(BOOTSTRAP_KS_CC_NAME) \
		CLUSTERPOOL_HOST_NAMESPACE=$(BOOTSTRAP_KS_CC_NAMESPACE) \
		CLUSTERPOOL_HOST_API=$(BOOTSTRAP_KS_HOST_API) \
		CLUSTERPOOL_HOST_USER=$(BOOTSTRAP_KS_HOST_USER) \
		CLUSTERPOOL_HOST_PASS=$(BOOTSTRAP_KS_HOST_PASS) \
		CLUSTERPOOL_HOST_TOKEN=$(BOOTSTRAP_KS_HOST_TOKEN) > $(BUILD_HARNESS_PATH)/.co
	@$(SELF) -s clusterpool/get-cluster-basedomain \
		CLUSTERPOOL_CLUSTER_CLAIM=$(BOOTSTRAP_KS_CC_NAME) \
		CLUSTERPOOL_HOST_NAMESPACE=$(BOOTSTRAP_KS_CC_NAMESPACE) \
		CLUSTERPOOL_HOST_API=$(BOOTSTRAP_KS_HOST_API) \
		CLUSTERPOOL_HOST_USER=$(BOOTSTRAP_KS_HOST_USER) \
		CLUSTERPOOL_HOST_PASS=$(BOOTSTRAP_KS_HOST_PASS) \
		CLUSTERPOOL_HOST_TOKEN=$(BOOTSTRAP_KS_HOST_TOKEN) > $(BUILD_HARNESS_PATH)/.bd
	@if [ -n "$(BOOTSTRAP_KS_DEBUG)" ]; then cat $(BUILD_HARNESS_PATH)/.co; cat $(BUILD_HARNESS_PATH)/.ap; cat $(BUILD_HARNESS_PATH)/.bd; fi
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) \
		--from-file=kubeconfig=$(BUILD_HARNESS_PATH)/.kc \
		--from-literal=username=`cat $(BUILD_HARNESS_PATH)/.un` \
		--from-literal=password=`cat $(BUILD_HARNESS_PATH)/.pw` \
		--from-literal=api_url=`cat $(BUILD_HARNESS_PATH)/.ap` \
		--from-literal=console_url=`cat $(BUILD_HARNESS_PATH)/.co` \
		--from-literal=basedomain=`cat $(BUILD_HARNESS_PATH)/.bd` \
		--from-literal=clusterclaim_namespace=$(BOOTSTRAP_KS_CC_NAMESPACE) \
		--from-literal=cloud_platform=$(BOOTSTRAP_KS_CLOUD_PLATFORM) \
		--from-literal=clusterclaim=$(BOOTSTRAP_KS_CC_NAME)"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks=false"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-type=ocp"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-secret-type=clusterclaim"
	@rm -f $(BUILD_HARNESS_PATH)/.co $(BUILD_HARNESS_PATH)/.ap $(BUILD_HARNESS_PATH)/.pw $(BUILD_HARNESS_PATH)/.un $(BUILD_HARNESS_PATH)/.kc $(BUILD_HARNESS_PATH)/.bd


.PHONY: bootstrap-ks/clusterclaim-delete-cluster
## Delete the clusterclaim - usually one associated with a clusterclaim-type secret as a pre-req for running bootstrap-ks/delete-secret
bootstrap-ks/clusterclaim-delete-cluster: %clusterclaim-delete-cluster: %_init
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	$(call assert-set,BOOTSTRAP_KS_CC_NAME)
	$(call assert-set,BOOTSTRAP_KS_CC_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="delete clusterclaim -n $(BOOTSTRAP_KS_CC_NAMESPACE) $(BOOTSTRAP_KS_CC_NAME)"


##======= Azure Kubernetes Service ===========================

.PHONY: bootstrap-ks/aks-install
## Install Azure Kubernetes Service (AKS) cluster
bootstrap-ks/aks-install: %aks-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; ./install.sh;

.PHONY: bootstrap-ks/aks-create-cluster
## Create Azure Kubernetes Service (AKS) cluster
bootstrap-ks/aks-create-cluster: %aks-create-cluster: %aks-install
	$(call assert-set,AZURE_USER)
	$(call assert-set,AZURE_PASS)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aks; ./provision.sh;

.PHONY: bootstrap-ks/aks-save-secret
## Save AKS JSON and KUBECONFIG as a secret.  You can filter these secrets using --selector=bootstrap-ks=true
bootstrap-ks/aks-save-secret: %aks-save-secret: %_init
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_AKS_CLUSTER_NAME) --from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/aks/$(BOOTSTRAP_KS_AKS_CLUSTER_NAME).json --from-file=kubeconfig=$(BOOTSTRAP_KS_DEPLOY_DIR)/aks/$(BOOTSTRAP_KS_AKS_CLUSTER_NAME).kubeconfig"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_AKS_CLUSTER_NAME) bootstrap-ks=true"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_AKS_CLUSTER_NAME) bootstrap-ks-type=aks"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-secret-type=aks"


.PHONY: bootstrap-ks/aks-get-cluster-name
## Get Azure Kubernetes Service (AKS) cluster name
bootstrap-ks/aks-get-cluster-name: %aks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_AKS_CLUSTER_NAME)

.PHONY: bootstrap-ks/aks-get-cluster-json
## Get Azure Kubernetes Service (AKS) cluster JSON
bootstrap-ks/aks-get-cluster-json: %aks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_AKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_AKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"


.PHONY: bootstrap-ks/aks-get-cluster-kubeconfig
## Get Azure Kubernetes Service (AKS) cluster KUBECONFIG
bootstrap-ks/aks-get-cluster-kubeconfig: %aks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_AKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_AKS_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig | base64 -d"

.PHONY: bootstrap-ks/aks-delete-cluster
## Delete Azure Kubernetes Service (AKS) cluster. OPTIONAL: BOOTSTRAP_KS_AKS_JSON_FILE - path to the json file for the AKS instance
bootstrap-ks/aks-delete-cluster: %aks-delete-cluster: %aks-install
	$(call assert-set,AZURE_USER)
	$(call assert-set,AZURE_PASS)
	@if [ ! -z "$(BOOTSTRAP_KS_AKS_JSON_FILE)" ]; then \
	  cd ${BOOTSTRAP_KS_DEPLOY_DIR}/aks; ./destroy.sh ${BOOTSTRAP_KS_AKS_JSON_FILE}; \
	else \
		cd ${BOOTSTRAP_KS_DEPLOY_DIR}/aks; ./destroy.sh *.json; \
	fi;


##======= Azure Red Hat Openshift ===========================

.PHONY: bootstrap-ks/aro-install
## Install Azure Red Hat OpenShift (ARO) cluster
bootstrap-ks/aro-install: %aro-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aro; ./install.sh;

.PHONY: bootstrap-ks/aro-create-cluster
## Create Azure Red Hat OpenShift (ARO) cluster
bootstrap-ks/aro-create-cluster: %aro-create-cluster: %aro-install
	$(call assert-set,AZURE_USER)
	$(call assert-set,AZURE_PASS)
	$(call assert-set,BOOTSTRAP_KS_ARO_CLUSTER_NAME)
	$(call assert-set,AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME)
	$(call assert-set,AZURE_BASE_DOMAIN)
	$(call assert-set,OCP_PULL_SECRET_FILE)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/aro; \
		CLUSTER_NAME=${BOOTSTRAP_KS_ARO_CLUSTER_NAME} \
		AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME=${AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME} \
		AZURE_BASE_DOMAIN=${AZURE_BASE_DOMAIN} \
		OCP_PULL_SECRET_FILE=${OCP_PULL_SECRET_FILE} \
		./provision.sh;

.PHONY: bootstrap-ks/aro-save-secret
## Save ARO metadata as a secret.  You can filter these secrets using --selector=bootstrap-ks=true --bootstrap-ks-secret-type=aro
bootstrap-ks/aro-save-secret: %aro-save-secret: %_init
	$(call assert-set,BOOTSTRAP_KS_ARO_CLUSTER_NAME)
	@$(SELF) -s oc/command OC_COMMAND="create secret generic $(BOOTSTRAP_KS_ARO_CLUSTER_NAME) \
		-n $(BOOTSTRAP_KS_HOST_NAMESPACE) \
		--from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json \
		--from-literal=resource_group_name=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.RESOURCE_GROUP_NAME'` \
		--from-literal=cluster_name=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.CLUSTER_NAME'` \
		--from-literal=region=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.REGION'` \
		--from-literal=azure_subscription_id=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.SUBSCRIPTION'` \
		--from-literal=cloud_platform=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.PLATFORM'` \
		--from-literal=azure_base_domain_resource_group_name=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME'` \
		--from-literal=basedomain=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.CLUSTER_NAME'`.`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.AZURE_BASE_DOMAIN'` \
		--from-literal=username=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.USERNAME'` \
		--from-literal=password=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.PASSWORD'` \
		--from-literal=console_url=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.CONSOLE_URL'` \
		--from-literal=api_url=`cat $(BOOTSTRAP_KS_DEPLOY_DIR)/aro/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json | ${JQ} -r '.API_URL'`"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_ARO_CLUSTER_NAME) bootstrap-ks=true"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_ARO_CLUSTER_NAME) bootstrap-ks-type=ocp"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_ARO_CLUSTER_NAME) bootstrap-ks-secret-type=aro"

.PHONY: bootstrap-ks/aro-delete-cluster
## Delete Azure Red Hat OpenShift cluster. OPTIONAL: BOOTSTRAP_KS_AKS_JSON_FILE - path to the json file for the ARO instance
bootstrap-ks/aro-delete-cluster: %aro-delete-cluster: %aro-install
	$(call assert-set,AZURE_USER)
	$(call assert-set,AZURE_PASS)
	$(call assert-set,BOOTSTRAP_KS_ARO_CLUSTER_NAME)
	@${OC} get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_ARO_CLUSTER_NAME) -o json | ${JQ} -r '.data.json' | base64 -d > ${BUILD_HARNESS_PATH}/${BOOTSTRAP_KS_ARO_CLUSTER_NAME}.json
	@cd ${BOOTSTRAP_KS_DEPLOY_DIR}/aro; ./destroy.sh ${BUILD_HARNESS_PATH}/$(BOOTSTRAP_KS_ARO_CLUSTER_NAME).json;


##======= Amazon Elastic Kubernetes Service ===========================

.PHONY: bootstrap-ks/eks-install
## Install Amazon Elastic Kubernetes Service (EKS)
bootstrap-ks/eks-install: %eks-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/eks; ./install.sh;

.PHONY: bootstrap-ks/eks-create-cluster
## Create Amazon Elastic Kubernetes Service (EKS) cluster
bootstrap-ks/eks-create-cluster: %eks-create-cluster: %eks-install
	$(call assert-set,AWS_ACCESS_KEY_ID)
	$(call assert-set,AWS_SECRET_ACCESS_KEY)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/eks; ./provision.sh;

.PHONY: bootstrap-ks/eks-save-secret
## Save EKS JSON and KUBECONFIG as a secret.  You can filter these secrets using --selector=bootstrap-ks=true
bootstrap-ks/eks-save-secret: %eks-save-secret: %_init
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_EKS_CLUSTER_NAME) --from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/eks/$(BOOTSTRAP_KS_EKS_CLUSTER_NAME).json --from-file=kubeconfig=$(BOOTSTRAP_KS_DEPLOY_DIR)/eks/$(BOOTSTRAP_KS_EKS_CLUSTER_NAME).kubeconfig"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_EKS_CLUSTER_NAME) bootstrap-ks=true"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_EKS_CLUSTER_NAME) bootstrap-ks-type=eks"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-secret-type=eks"


.PHONY: bootstrap-ks/eks-get-cluster-name
## Get Amazon Elastic Kubernetes Service (EKS) cluster name
bootstrap-ks/eks-get-cluster-name: %eks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_EKS_CLUSTER_NAME)


.PHONY: bootstrap-ks/eks-get-cluster-json
## Get Amazon Elastic Kubernetes Service (EKS) cluster JSON
bootstrap-ks/eks-get-cluster-json: %eks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_EKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_EKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"


.PHONY: bootstrap-ks/eks-get-cluster-kubeconfig
## Get Amazon Elastic Kubernetes Service (EKS) cluster KUBECONFIG
bootstrap-ks/eks-get-cluster-kubeconfig: %eks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_EKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_EKS_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig | base64 -d"

.PHONY: bootstrap-ks/eks-delete-cluster
## Delete Amazon Elastic Kubernetes Service (EKS) cluster. OPTIONAL: BOOTSTRAP_KS_EKS_JSON_FILE - path to the json file for the EKS instance
bootstrap-ks/eks-delete-cluster: %eks-delete-cluster: %aks-install
	$(call assert-set,AWS_ACCESS_KEY_ID)
	$(call assert-set,AWS_SECRET_ACCESS_KEY)
	@if [ ! -z "$(BOOTSTRAP_KS_EKS_JSON_FILE)" ]; then \
   	cd ${BOOTSTRAP_KS_DEPLOY_DIR}/eks; ./destroy.sh ${BOOTSTRAP_KS_EKS_JSON_FILE}; \
	else \
		cd ${BOOTSTRAP_KS_DEPLOY_DIR}/eks; ./destroy.sh *.json; \
	fi;


##======= Google Kubernetes Engine ===========================

.PHONY: bootstrap-ks/gke-install
## Install Google Kubernetes Engine (GKE)
bootstrap-ks/gke-install: %gke-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; ./install.sh;

.PHONY: bootstrap-ks/gke-create-cluster
## Create Google Kubernetes Engine (GKE) cluster
bootstrap-ks/gke-create-cluster: %gke-create-cluster: %gke-install
	$(call assert-set,GCLOUD_CREDS_FILE)
	$(call assert-set,GCLOUD_PROJECT_ID)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/gke; ./provision.sh;

.PHONY: bootstrap-ks/gke-save-secret
## Save GKE JSON and KUBECONFIG as a secret.  You can filter these secrets using --selector=bootstrap-ks=true
bootstrap-ks/gke-save-secret: %gke-save-secret: %_init
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) --from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/gke/$(BOOTSTRAP_KS_GKE_CLUSTER_NAME).json --from-file=kubeconfig=$(BOOTSTRAP_KS_DEPLOY_DIR)/gke/$(BOOTSTRAP_KS_GKE_CLUSTER_NAME).kubeconfig"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) bootstrap-ks=true"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) bootstrap-ks-type=gke"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-secret-type=gke"


.PHONY: bootstrap-ks/gke-get-cluster-name
## Get Google Kubernetes Engine (GKE) cluster name
bootstrap-ks/gke-get-cluster-name: %gke-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_GKE_CLUSTER_NAME)


.PHONY: bootstrap-ks/gke-get-cluster-json
## Get Google Kubernetes Engine (GKE) cluster JSON
bootstrap-ks/gke-get-cluster-json: %gke-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_GKE_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"


.PHONY: bootstrap-ks/gke-get-cluster-kubeconfig
## Get Google Kubernetes Engine (GKE) cluster KUBECONFIG
bootstrap-ks/gke-get-cluster-kubeconfig: %gke-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_GKE_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig | base64 -d"

.PHONY: bootstrap-ks/gke-delete-cluster
## Delete Google Kubernetes Engine (GKE) cluster.  OPTIONAL: BOOTSTRAP_KS_GKE_JSON_FILE - path to the json file for the GKE instance
bootstrap-ks/gke-delete-cluster: %gke-delete-cluster: %aks-install
	$(call assert-set,GCLOUD_CREDS_FILE)
	$(call assert-set,GCLOUD_PROJECT_ID)
	@if [ ! -z "$(BOOTSTRAP_KS_GKE_JSON_FILE)" ]; then \
   	cd ${BOOTSTRAP_KS_DEPLOY_DIR}/gke; ./destroy.sh ${BOOTSTRAP_KS_GKE_JSON_FILE}; \
	else \
		cd ${BOOTSTRAP_KS_DEPLOY_DIR}/gke; ./destroy.sh *.json; \
	fi;


##======= IBM Cloud Kubernetes Service (IKS) ===========================

.PHONY: bootstrap-ks/iks-install
## Install IBM Cloud Kubernetes Service (IKS)
bootstrap-ks/iks-install: %iks-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/iks; ./install.sh;

.PHONY: bootstrap-ks/iks-create-cluster
## Create IBM Cloud Kubernetes Service (IKS) cluster
bootstrap-ks/iks-create-cluster: %iks-create-cluster: %iks-install
	$(call assert-set,IBMCLOUD_APIKEY)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/iks; export ROKS=false; ./provision.sh;

.PHONY: bootstrap-ks/iks-save-secret
## Save IKS JSON and KUBECONFIG as a secret. You can filter these secrets using --selector=bootstrap-ks=true
bootstrap-ks/iks-save-secret: %iks-save-secret: %_init
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_IKS_CLUSTER_NAME) --from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/iks/$(BOOTSTRAP_KS_IKS_CLUSTER_NAME).json --from-file=kubeconfig=$(BOOTSTRAP_KS_DEPLOY_DIR)/iks/$(BOOTSTRAP_KS_IKS_CLUSTER_NAME).kubeconfig"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_IKS_CLUSTER_NAME) bootstrap-ks=true"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_IKS_CLUSTER_NAME) bootstrap-ks-type=iks"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-secret-type=iks"

.PHONY: bootstrap-ks/iks-get-cluster-name
## Get IBM Cloud Kubernetes Service (IKS) cluster name
bootstrap-ks/iks-get-cluster-name: %iks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_IKS_CLUSTER_NAME)

.PHONY: bootstrap-ks/iks-get-cluster-json
## Get IBM Cloud Kubernetes Service (IKS) cluster JSON
bootstrap-ks/iks-get-cluster-json: %iks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_IKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_IKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"

.PHONY: bootstrap-ks/iks-get-cluster-kubeconfig
## Get IBM Cloud Kubernetes Service (IKS) cluster KUBECONFIG
bootstrap-ks/iks-get-cluster-kubeconfig: %iks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_IKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_IKS_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig | base64 -d"

.PHONY: bootstrap-ks/iks-delete-cluster
## Delete IBM Cloud Kubernetes Service (IKS) cluster. OPTIONAL: BOOTSTRAP_KS_IKS_JSON_FILE - path to the json file for the IKS instance
bootstrap-ks/iks-delete-cluster: %iks-delete-cluster: %iks-install
	$(call assert-set,IBMCLOUD_APIKEY)
	@if [ ! -z "$(BOOTSTRAP_KS_IKS_JSON_FILE)" ]; then \
		cd ${BOOTSTRAP_KS_DEPLOY_DIR}/iks; ./destroy.sh ${BOOTSTRAP_KS_IKS_JSON_FILE}; \
	else \
	  cd ${BOOTSTRAP_KS_DEPLOY_DIR}/iks; ./destroy.sh *-iks.json; \
	fi;


##======= IBM Red Hat OpenShift Kubernetes Service (ROKS) ===========================

.PHONY: bootstrap-ks/roks-install
## Install IBM Red Hat OpenShift Kubernetes Service (ROKS)
bootstrap-ks/roks-install: %roks-install: %_init
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/iks; ./install.sh;

.PHONY: bootstrap-ks/roks-create-cluster
## Create IBM Red Hat OpenShift Kubernetes Service (ROKS) cluster
bootstrap-ks/roks-create-cluster: %roks-create-cluster: %roks-install
	$(call assert-set,IBMCLOUD_APIKEY)
	@cd $(BOOTSTRAP_KS_DEPLOY_DIR)/iks; export ROKS=true; ./provision.sh;

.PHONY: bootstrap-ks/roks-save-secret
## Save ROKS JSON and KUBECONFIG as a secret. You can filter these secrets using --selector=bootstrap-ks=true
bootstrap-ks/roks-save-secret: %roks-save-secret: %_init
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_ROKS_CLUSTER_NAME) --from-file=json=$(BOOTSTRAP_KS_DEPLOY_DIR)/iks/$(BOOTSTRAP_KS_ROKS_CLUSTER_NAME).json --from-file=kubeconfig=$(BOOTSTRAP_KS_DEPLOY_DIR)/iks/$(BOOTSTRAP_KS_ROKS_CLUSTER_NAME).kubeconfig"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_ROKS_CLUSTER_NAME) bootstrap-ks=true"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_ROKS_CLUSTER_NAME) bootstrap-ks-type=ocp"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-secret-type=roks"

.PHONY: bootstrap-ks/roks-get-cluster-name
## Get IBM Red Hat OpenShift Kubernetes Service (ROKS) cluster name
bootstrap-ks/roks-get-cluster-name: %roks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_ROKS_CLUSTER_NAME)

.PHONY: bootstrap-ks/roks-get-cluster-json
## Get IBM Red Hat OpenShift Kubernetes Service (ROKS) cluster JSON
bootstrap-ks/roks-get-cluster-json: %roks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_ROKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_ROKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"

.PHONY: bootstrap-ks/roks-get-cluster-kubeconfig
## Get IBM Red Hat OpenShift Kubernetes Service (ROKS) cluster KUBECONFIG
bootstrap-ks/roks-get-cluster-kubeconfig: %roks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_ROKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_ROKS_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig | base64 -d"

.PHONY: bootstrap-ks/roks-delete-cluster
## Delete IBM Red Hat OpenShift Kubernetes Service (ROKS) cluster. OPTIONAL: BOOTSTRAP_KS_ROKS_JSON_FILE - path to the json file for the ROKS instance
bootstrap-ks/roks-delete-cluster: %roks-delete-cluster: %roks-install
	$(call assert-set,IBMCLOUD_APIKEY)
	@if [ ! -z "$(BOOTSTRAP_KS_ROKS_JSON_FILE)" ]; then \
		cd ${BOOTSTRAP_KS_DEPLOY_DIR}/iks; ./destroy.sh ${BOOTSTRAP_KS_ROKS_JSON_FILE}; \
	else \
	  cd ${BOOTSTRAP_KS_DEPLOY_DIR}/iks; ./destroy.sh *-roks.json; \
	fi;
