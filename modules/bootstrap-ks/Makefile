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
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) -o json | $(JQ) -r .data.kubeconfig | base64 -d"

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
	@$(SELF) -s bootstrap-ks/get-cluster-kubeconfig > $(PWD)/$(BOOTSTRAP_KS_CLUSTER_NAME).kubeconfig
	@if [[ `cat .st` == "clusterclaim" ]]; then \
		$(SELF) -s bootstrap-ks/get-cluster-username > .un; \
		$(SELF) -s bootstrap-ks/get-cluster-password > .pw;\
		$(SELF) -s bootstrap-ks/get-cluster-api > .api; \
		$(SELF) -s bootstrap-ks/get-cluster-claim > .cc; \
		$(SELF) -s bootstrap-ks/get-cluster-cloud-platform > .pf; \
		$(SELF) -s bootstrap-ks/get-cluster-claim > .ccns; \
		$(SELF) -s bootstrap-ks/get-cluster-console > .con; fi;
	@echo "{}" > gc1.json
	@$(JQ) --arg type `cat .ct` '. + {type: $$type}' gc1.json > .tmp; mv .tmp gc1.json
	@$(JQ) --arg secret_type `cat .st` '. + {secret_type: $$secret_type}' gc1.json > .tmp; mv .tmp gc1.json
	@$(JQ) --arg kubeconfig $(PWD)/$(BOOTSTRAP_KS_CLUSTER_NAME).kubeconfig '. + {kubeconfig: $$kubeconfig}' gc1.json > .tmp; mv .tmp gc1.json
	@if [[ `cat .st` == "clusterclaim" ]]; then \
		$(JQ) --arg username `cat .un` '. + {username: $$username}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg password `cat .pw` '. + {password: $$password}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg api_url `cat .api` '. + {api_url: $$api_url}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg clusterclaim `cat .cc` '. + {clusterclaim: $$clusterclaim}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg cloudplatform `cat .pf` '. + {cloud_platform: $$cloudplatform}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg clusterclaim_namespace `cat .ccns` '. + {clusterclaim_namespace: $$clusterclaim_namespace}' gc1.json > .tmp; mv .tmp gc1.json; \
		$(JQ) --arg console_url `cat .con` '. + {console_url: $$console_url}' gc1.json > .tmp; mv .tmp gc1.json; fi;
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
			BOOTSTRAP_KS_CC_NAME=`$(SELF) bootstrap-ks/get-cluster-claim` \
			BOOTSTRAP_KS_CC_NAMESPACE=`$(SELF) bootstrap-ks/get-cluster-claim-namespace`; \
	elif [[ `cat .st` == "aks" ]]; then \
		$(SELF) boostrap-ks/aks-delete-cluster; \
	elif [[ `cat .st` == "eks" ]]; then \
		$(SELF) boostrap-ks/eks-delete-cluster; \
	elif [[ `cat .st` == "iks" ]]; then \
		$(SELF) boostrap-ks/iks-delete-cluster; \
	elif [[ `cat .st` == "roks" ]]; then \
		$(SELF) boostrap-ks/roks-delete-cluster; \
	elif [[ `cat .st` == "gke" ]]; then \
		$(SELF) boostrap-ks/gke-delete-cluster; \
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
	@$(SELF) -s oc/command OC_COMMAND="create secret generic -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) \
		--from-file=kubeconfig=$(BOOTSTRAP_KS_CC_KUBECONFIG_FILE) \
		--from-literal=username=$(BOOTSTRAP_KS_CC_USERNAME) \
		--from-literal=password=$(BOOTSTRAP_KS_CC_PASSWORD) \
		--from-literal=api_url=$(BOOTSTRAP_KS_CC_API_URL) \
		--from-literal=console_url=$(BOOTSTRAP_KS_CC_CONSOLE_URL) \
		--from-literal=clusterclaim_namespace=$(BOOTSTRAP_KS_CC_NAMESPACE) \
		--from-literal=cloud_platform=$(BOOTSTRAP_KS_CLOUD_PLATFORM) \
		--from-literal=clusterclaim=$(BOOTSTRAP_KS_CC_NAME)"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks=false"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-type=ocp"
	@$(SELF) -s oc/command OC_COMMAND="label secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_CLUSTER_NAME) bootstrap-ks-secret-type=clusterclaim"


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
