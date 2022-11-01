# GITHUB_USER containing '@' char must be escaped with '%40'
GITHUB_USER := $(shell echo $(GITHUB_USER) | sed 's/@/%40/g')
GITHUB_TOKEN ?=

#DOCKER_CREDS
DOCKER_USER ?=
DOCKER_PASS ?=
DOCKER_REGISTRY ?= quay.io

# May or may not be in github enterprise
COMMUNITY_GIT_SITE ?= github.com
# May be in RedHat main org or in some ACM specific org
COMMUNITY_OPERATOR_ORG ?= stolostron
# Name of upstream operator project
COMMUNITY_REPO?= community-operators-prod 
# URL for Git clone
COMMUNITY_GIT_URL ?= "https://$(GITHUB_USER):$(GITHUB_TOKEN)@$(COMMUNITY_GIT_SITE)/$(COMMUNITY_OPERATOR_ORG)/$(COMMUNITY_REPO).git"
# Branch to sync
COMMUNITY_OPERATOR_BRANCH ?= main

OPERATOR_DIR ?= $(COMMUNITY_REPO)/operators/$(OPERATOR_TYPE)/$(OPERATOR_VERSION)

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
	$(GIT) fetch upstream
	$(GIT) checkout $(COMMUNITY_OPERATOR_BRANCH)
	$(GIT) rebase upstream/$(COMMUNITY_OPERATOR_BRANCH)
	$(GIT) checkout -b $(OPERATOR_TYPE):$(OPERATOR_VERSION)

.PHONY: community-publish/image-pull
## Pull operator from image repo
community-publish/image-pull: %image-pull %init
	@mkdir -p $(OPERATOR_DIR)
	@$(SELF) docker/login DOCKER_USER=$(DOCKER_USER) DOCKER_PASS=$(DOCKER_PASS)
	@$(SELF) oc/command OC_COMMAND="image extract $(DOCKER_REGISTRY)/$(COMMUNITY_OPERATOR_ORG)/$(OPERATOR_TYPE)-operator-bundle:$(SNAPSHOT) --path /:/$(OPERATOR_DIR)"
	
.PHONY: community-publish/push
## Push new operator to upstream
	@(GIT) push
## Need some command to PR changes back to upstream fork
