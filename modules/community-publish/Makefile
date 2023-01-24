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
UPSTREAM_COMMUNITY_REPO ?= community-operators-prod
# Location of the community operators upstream
UPSTREAM_OPERATOR_ORG ?= redhat-openshift-ecosystem
# URL for Git clone
COMMUNITY_GIT_URL ?= "https://$(GITHUB_USER):$(GITHUB_TOKEN)@$(COMMUNITY_GIT_SITE)/$(COMMUNITY_OPERATOR_ORG)/$(COMMUNITY_REPO).git"
# Branch to sync
COMMUNITY_OPERATOR_BRANCH ?= main
# Community operator release repo location
RELEASE_GIT_URL ?= "https://$(GITHUB_USER):$(GITHUB_TOKEN)@$(COMMUNITY_GIT_SITE)/$(COMMUNITY_OPERATOR_ORG)/release.git"

OPERATOR_IMAGE_REPO ?= $(COMMUNITY_OPERATOR_ORG)
OPERATOR_DIR ?= $(COMMUNITY_REPO)/operators/$(OPERATOR_TYPE)/$(OPERATOR_VERSION)
Y_VERSION ?= $(echo $(OPERATOR_VERSION) | sed -nr "s/([0-9]+\.[0-9]+)\.{0,1}[0-9]*/\1/p")
OPERATOR_NAME ?= $(shell if [[ "$(OPERATOR_TYPE)" == "stolostron" ]] ; then echo "stn-operator-bundle"; else echo "ste-operator-bundle"; fi)
OPERATOR_BRANCH ?= $(shell if [[ "$(OPERATOR_TYPE)" == "stolostron" ]] ; then echo "stolostron-$(Y_VERSION)"; else echo "stolostron_engine-$(Y_VERSION)"; fi)

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
	@$(GIT) clone -b $(COMMUNITY_OPERATOR_BRANCH) $(COMMUNITY_GIT_URL) $(COMMUNITY_REPO); \
	cd $(COMMUNITY_REPO); \
	echo "Adding upstream community reference"; \
	$(GIT) remote add upstream https://$(COMMUNITY_GIT_SITE)/$(UPSTREAM_OPERATOR_ORG)/$(UPSTREAM_COMMUNITY_REPO); \
	echo "Fetching upstream changes"; \
	$(GIT) fetch upstream; \
	echo "Rebase on upstream repo"; \
	$(GIT) rebase upstream/$(COMMUNITY_OPERATOR_BRANCH); \
	echo "Make new branch for changes"; \
	$(GIT) checkout -b $(OPERATOR_TYPE)-$(OPERATOR_VERSION); \
	cd ..

.PHONY: community-publish/image-pull
## Pull operator from image repo
community-publish/image-pull: %image-pull: %init
	@mkdir -p $(OPERATOR_DIR)
	@$(SELF) docker/login
	@$(SELF) oc/command OC_LOGGED_IN=$(OPERATOR_DIR) OC_COMMAND="image extract $(DOCKER_REGISTRY)/$(OPERATOR_IMAGE_REPO)/$(OPERATOR_NAME):$(SNAPSHOT) --path /:$(OPERATOR_DIR)"
	
.PHONY: community-publish/push
## Push new operator to upstream
community-publish/push: %push: %init
	@cd $(COMMUNITY_REPO); \
	$(GIT) add --all; \
	$(GIT) commit --signoff -m "Publishing $(SNAPSHOT) to $(OPERATOR_TYPE) v$(OPERATOR_VERSION)"; \
	$(GIT) push --quiet --set-upstream origin $(OPERATOR_TYPE)-$(OPERATOR_VERSION); \
	cd ..

.PHONY: community-publish/pull-request
## Create a pull request to the upstream org
community-publish/pull-request: %pull-request: %init
	@$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/community-publish/bin/make-pr.sh \
	$(OPERATOR_TYPE) $(OPERATOR_VERSION) $(UPSTREAM_OPERATOR_ORG) $(UPSTREAM_COMMUNITY_REPO) \
	$(COMMUNITY_OPERATOR_ORG) $(COMMUNITY_OPERATOR_BRANCH)

.PHONY: community-publish/version-update
## Updating the version number in local operator
community-publish/version-update: %version-update:
	@$(GIT) clone -b $(OPERATOR_BRANCH) $(RELEASE_GIT_URL); \
	cd release
	NEW_Z_VERSION=`cat Z_RELEASE_VERSION | awk -F. '/[0-9]+\./{$NF++;print}' OFS=.`; \
	echo $NEW_Z_VERSION > Z_RELEASE_VERSION; \
	$(GIT) commit -am "[skip ci] Updating version to $(NEW_Z_VERSION)"; \
	$(GIT) push; \
	cd ..
