# GITHUB_USER containing '@' char must be escaped with '%40'
GITHUB_USER := $(shell echo $(GITHUB_USER) | sed 's/@/%40/g')
GITHUB_TOKEN ?=

#DOCKER_CREDS
DOCKER_USER ?=
DOCKER_PASS ?=
DOCKER_REGISTRY ?= quay.io

# May or may not be in github enterprise
COMMUNITY_GIT_SITE ?= github.com
# Name of the repo in local org
COMMUNITY_REPO ?= community-operators-submission-fork
# May be in RedHat main org or in some ACM specific org
COMMUNITY_OPERATOR_ORG ?= stolostron
# Name of upstream community operator project
UPSTREAM_COMMUNITY_REPO?= community-operators-prod 
# Location of the community operators upstream
UPSTREAM_OPERATOR_ORG ?= redhat-openshift-ecosystem 
# URL for Git clone
COMMUNITY_GIT_URL ?= "https://$(GITHUB_USER):$(GITHUB_TOKEN)@$(COMMUNITY_GIT_SITE)/$(COMMUNITY_OPERATOR_ORG)/$(COMMUNITY_REPO).git"
# Branch to sync
COMMUNITY_OPERATOR_BRANCH ?= main
# Community operator release repo location
RELEASE_GIT_URL ?= "https://$(GITHUB_USER):$(GITHUB_TOKEN)@$(COMMUNITY_GIT_SITE)/release.git"


OPERATOR_DIR ?= $(COMMUNITY_REPO)/operators/$(OPERATOR_TYPE)/$(OPERATOR_VERSION)
Y_VERSION ?= $(echo $(OPERATOR_VERSION) | sed -nr "s/([0-9]+\.[0-9]+)\.{0,1}[0-9]*/\1/p")
OPERATOR_NAME ?= $(if [[ "$(OPERATOR_TYPE)" == "stolostron" ]]; then echo "stn-operator-bundle"; else echo "ste-operator-bundle"; fi) 
OPERATOR_BRANCH = ?= $(if [[ "$(OPERATOR_TYPE)" == "stolostron" ]]; then echo "stolostron-$(Y_VERSION)"; else echo "stolostron_engine-$(Y_VERSION)"; fi)

.PHONY: community-publish/init
## Install build dependencies
community-publish/init: %init:
	$(call assert-set,OPERATOR_TYPE)
	$(call assert-set,SNAPSHOT)
	$(call assert-set,OPERATOR_VERSION)
	@$(SELF) oc/install
	@$(SELF) opm/install

.PHONY: community-publish/pull
## Install upstream community changes
community-publish/pull: %pull: %init
	$(GIT) clone -b $(COMMUNITY_OPERATOR_BRANCH) $(COMMUNITY_GIT_URL) $(COMMUNITY_REPO);
	@cd $(COMMUNITY_REPO)
	$(GIT) remote add upstream https://$(COMMUNITY_GIT_SITE)/$(UPSTREAM_OPERATOR_ORG)/$(UPSTREAM_COMMUNITY_REPO)
	$(GIT) fetch upstream
	$(GIT) checkout $(COMMUNITY_OPERATOR_BRANCH)
	$(GIT) rebase upstream/$(COMMUNITY_OPERATOR_BRANCH)
	$(GIT) checkout -b $(OPERATOR_TYPE)-$(OPERATOR_VERSION)
	@cd ..

.PHONY: community-publish/image-pull
## Pull operator from image repo
community-publish/image-pull: %image-pull %init
	@mkdir -p $(OPERATOR_DIR)
	@$(SELF) docker/login DOCKER_USER=$(DOCKER_USER) DOCKER_PASS=$(DOCKER_PASS)
	@$(SELF) oc/command OC_COMMAND="image extract $(DOCKER_REGISTRY)/$(COMMUNITY_OPERATOR_ORG)/$(OPERATOR_NAME):$(SNAPSHOT) --path /:/$(OPERATOR_DIR)"
	
.PHONY: community-publish/push
## Push new operator to upstream
	@cd $(COMMUNITY_REPO)
	$(GIT) commit -am "Publishing $(SNAPSHOT) to $(OPERATOR_TYPE) v$(OPERATOR_VERSION)"
	$(GIT) push --quiet
	@cd ..

.PHONY: community-publish/pull-request
## Create a pull request to the upstream org
	@$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/community-publish/bin/make-pr.sh 

.PHONY: community-publish/version-update
## Updating the version number in local operator
	$(GIT) clone -b $(OPERATOR_BRANCH) $(RELEASE_GIT_URL)
	@NEW_Z_VERSION=`cat release/Z_RELEASE_VERSION | awk -F. '/[0-9]+\./{$NF++;print}' OFS=.`; 
	@echo $NEW_Z_VERSION > release/Z_RELEASE_VERSION; \
	$(GIT) commit -am "[skip ci] Updating version to $(NEW_Z_VERSION)"; 
	$(GIT) push;
