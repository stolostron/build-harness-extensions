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
BOOTSTRAP_KS_AKS_CLUSTER_NAME = $(shell cat ${BOOTSTRAP_KS_DEPLOY_DIR}/aks/*.json | $(JQ) -r .CLUSTER_NAME)
BOOTSTRAP_KS_GKE_CLUSTER_NAME = $(shell cat ${BOOTSTRAP_KS_DEPLOY_DIR}/gke/*.json | $(JQ) -r .CLUSTER_NAME)
BOOTSTRAP_KS_EKS_CLUSTER_NAME = $(shell cat ${BOOTSTRAP_KS_DEPLOY_DIR}/eks/*.json | $(JQ) -r .CLUSTER_NAME)
BOOTSTRAP_KS_IKS_CLUSTER_NAME = $(shell cat ${BOOTSTRAP_KS_DEPLOY_DIR}/iks/*-iks.json | $(JQ) -r .CLUSTER_NAME)
BOOTSTRAP_KS_ROKS_CLUSTER_NAME = $(shell cat ${BOOTSTRAP_KS_DEPLOY_DIR}/iks/*-roks.json | $(JQ) -r .CLUSTER_NAME)

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


.PHONY: bootstrap-ks/aks-get-cluster-name
## Get Azure Kubernetes Service (AKS) cluster name
bootstrap-ks/aks-get-cluster-name: %aks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_AKS_CLUSTER_NAME)

.PHONY: bootstrap-ks/aks-get-cluster-json
## Get Azure Kubernetes Service (AKS) cluster JSON
bootstrap-ks/aks-get-cluster-json: %aks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_AKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_AKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"


.PHONY: bootstrap-ks/aks-get-cluster-kubeconfig
## Get Azure Kubernetes Service (AKS) cluster KUBECONFIG
bootstrap-ks/aks-get-cluster-kubeconfig: %aks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_AKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
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


.PHONY: bootstrap-ks/eks-get-cluster-name
## Get Amazon Elastic Kubernetes Service (EKS) cluster name
bootstrap-ks/eks-get-cluster-name: %eks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_EKS_CLUSTER_NAME)


.PHONY: bootstrap-ks/eks-get-cluster-json
## Get Amazon Elastic Kubernetes Service (EKS) cluster JSON
bootstrap-ks/eks-get-cluster-json: %eks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_EKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_EKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"


.PHONY: bootstrap-ks/eks-get-cluster-kubeconfig
## Get Amazon Elastic Kubernetes Service (EKS) cluster KUBECONFIG
bootstrap-ks/eks-get-cluster-kubeconfig: %eks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_EKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
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


.PHONY: bootstrap-ks/gke-get-cluster-name
## Get Google Kubernetes Engine (GKE) cluster name
bootstrap-ks/gke-get-cluster-name: %gke-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_GKE_CLUSTER_NAME)


.PHONY: bootstrap-ks/gke-get-cluster-json
## Get Google Kubernetes Engine (GKE) cluster JSON
bootstrap-ks/gke-get-cluster-json: %gke-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_GKE_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_GKE_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"


.PHONY: bootstrap-ks/gke-get-cluster-kubeconfig
## Get Google Kubernetes Engine (GKE) cluster KUBECONFIG
bootstrap-ks/gke-get-cluster-kubeconfig: %gke-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_GKE_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
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

.PHONY: bootstrap-ks/iks-get-cluster-name
## Get IBM Cloud Kubernetes Service (IKS) cluster name
bootstrap-ks/iks-get-cluster-name: %iks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_IKS_CLUSTER_NAME)

.PHONY: bootstrap-ks/iks-get-cluster-json
## Get IBM Cloud Kubernetes Service (IKS) cluster JSON
bootstrap-ks/iks-get-cluster-json: %iks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_IKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_IKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"

.PHONY: bootstrap-ks/iks-get-cluster-kubeconfig
## Get IBM Cloud Kubernetes Service (IKS) cluster KUBECONFIG
bootstrap-ks/iks-get-cluster-kubeconfig: %iks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_IKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
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

.PHONY: bootstrap-ks/roks-get-cluster-name
## Get IBM Red Hat OpenShift Kubernetes Service (ROKS) cluster name
bootstrap-ks/roks-get-cluster-name: %roks-get-cluster-name: %_init
	@echo $(BOOTSTRAP_KS_ROKS_CLUSTER_NAME)

.PHONY: bootstrap-ks/roks-get-cluster-json
## Get IBM Red Hat OpenShift Kubernetes Service (ROKS) cluster JSON
bootstrap-ks/roks-get-cluster-json: %roks-get-cluster-json: %_init
	$(call assert-set,BOOTSTRAP_KS_ROKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
	$(call assert-set,BOOTSTRAP_KS_HOST_NAMESPACE)
	@$(SELF) -s oc/command OC_COMMAND="get secret -n $(BOOTSTRAP_KS_HOST_NAMESPACE) $(BOOTSTRAP_KS_ROKS_CLUSTER_NAME) -o json | $(JQ) -r .data.json | base64 -d"

.PHONY: bootstrap-ks/roks-get-cluster-kubeconfig
## Get IBM Red Hat OpenShift Kubernetes Service (ROKS) cluster KUBECONFIG
bootstrap-ks/roks-get-cluster-kubeconfig: %roks-get-cluster-kubeconfig: %_init
	$(call assert-set,BOOTSTRAP_KS_ROKS_CLUSTER_NAME)
	$(call assert-set,BOOTSTRAP_KS_HOST_API)
	$(call assert-set,BOOTSTRAP_KS_HOST_USER)
	$(call assert-set,BOOTSTRAP_KS_HOST_PASS)
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
