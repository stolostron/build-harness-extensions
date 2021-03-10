# In OpenShift CI, pull related variables are named differently than in Travis.
# They also are not injected until the container starts, so they can't be passed
# in as arguments to make. See:
#
# https://github.com/kubernetes/test-infra/blob/master/prow/jobs.md#job-environment-variables
#
OSCI_COMPONENT_REPO ?= ${REPO_OWNER}/${REPO_NAME}
OSCI_COMPONENT_BRANCH ?= ${PULL_BASE_REF}
OSCI_COMPONENT_SHA256 ?= ${PULL_BASE_SHA}

OSCI_COMPONENT_NAME ?= $(COMPONENT_NAME)
OSCI_COMPONENT_VERSION ?= $(COMPONENT_VERSION)

OSCI_COMPONENT_SUFFIX ?= $(OSCI_COMPONENT_SHA256)
OSCI_COMPONENT_TAG ?= $(OSCI_COMPONENT_VERSION)-$(OSCI_COMPONENT_SUFFIX)

OSCI_RELEASE_VERSION ?= $(subst release-,,$(OSCI_COMPONENT_BRANCH))
OSCI_RELEASE_SHA_VERSION ?= $(OSCI_RELEASE_VERSION)

OSCI_PIPELINE_SITE ?= github.com
OSCI_PIPELINE_ORG ?= open-cluster-management
OSCI_PIPELINE_REPO ?= pipeline
OSCI_PIPELINE_STAGE ?= integration
OSCI_PIPELINE_RETAG_BRANCH ?= quay-retag
OSCI_PIPELINE_PROMOTE_FROM ?= $(OSCI_PIPELINE_STAGE)
OSCI_PIPELINE_PROMOTE_TO ?=
OSCI_PIPELINE_GIT_BRANCH ?= $(OSCI_RELEASE_VERSION)-$(OSCI_PIPELINE_PROMOTE_FROM)
OSCI_PIPELINE_GIT_URL ?= "https://$(GITHUB_USER):$(GITHUB_TOKEN)@$(OSCI_PIPELINE_SITE)/$(OSCI_PIPELINE_ORG)/$(OSCI_PIPELINE_REPO).git"

OSCI_MANIFEST_DIR ?= $(OSCI_PIPELINE_REPO)
OSCI_MANIFEST_BASENAME ?= manifest
OSCI_MANIFEST_FILENAME ?= $(OSCI_MANIFEST_BASENAME).json
OSCI_IMAGE_ALIAS_BASENAME ?= image-alias
OSCI_IMAGE_ALIAS_FILENAME ?= $(OSCI_IMAGE_ALIAS_BASENAME).json
OSCI_MANIFEST_SNAPSHOT_DIR ?= snapshots

# How long to wait, in minutes, for the images job to finish before triggering
# the actual work of the publish job.
OSCI_PUBLISH_DELAY ?= 5

OSCI_IMAGE_REMOTE_REPO ?= quay.io/open-cluster-management
OSCI_IMAGE_REMOTE_REPO_SRC ?= $(OSCI_IMAGE_REMOTE_REPO)
OSCI_IMAGE_REMOTE_REPO_DST ?= $(OSCI_IMAGE_REMOTE_REPO)

OSCI_GIT_USER_NAME ?= "ACM CICD"
OSCI_GIT_USER_EMAIL ?= "acm-cicd@redhat.com"
OSCI_GIT_MESSAGE ?= Added or Updated $(OSCI_COMPONENT_NAME)

OSCI_REPLACED_COMPONENT ?=
OSCI_DELETED_COMPONENT ?=

OSCI_JQ ?= jq
OSCI_MANIFEST_QUERY ?= .[] |select(.["image-name"] == "$(OSCI_COMPONENT_NAME)")
OSCI_ADDITION_QUERY ?= .[. | length] |= . + {"image-name": "$(OSCI_COMPONENT_NAME)", "image-version": "$(OSCI_COMPONENT_VERSION)", "image-tag": "$(OSCI_COMPONENT_TAG)", "git-sha256": "$(OSCI_COMPONENT_SHA256)", "git-repository": "$(OSCI_COMPONENT_REPO)",  "image-remote": "$(OSCI_IMAGE_REMOTE_REPO_DST)", "image-remote-src": "$(OSCI_IMAGE_REMOTE_REPO_SRC)"}
OSCI_DELETION_QUERY ?= .[] | select(.["image-name"] != "$(OSCI_DELETED_COMPONENT)")
OSCI_SORT_QUERY ?= . | sort_by(.["image-name"])

OSCI_DATETIME := $(shell (date +%Y-%m-%d-%H-%M-%S))

OSCI_Z_RELEASE_VERSION ?= $(shell curl -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3.raw" https://raw.githubusercontent.com/open-cluster-management/release/${OSCI_COMPONENT_BRANCH}/Z_RELEASE_VERSION)


.PHONY: osci/_datetime_gen
# Factory method for storing datetime variable
osci/_datetime_gen: %_datetime_gen:
	@if [ -f DATETIME ]; \
	then cat DATETIME; \
	else echo $(OSCI_DATETIME) > DATETIME; \
	fi;

.PHONY: osci/_sort
# Parse the configured pipeline manifest repo
osci/_sort: %_sort:
	@$(OSCI_JQ) '$(OSCI_SORT_QUERY)' $(OSCI_MANIFEST_DIR)/$(OSCI_MANIFEST_FILENAME) > tmp
	@mv tmp $(OSCI_MANIFEST_DIR)/$(OSCI_MANIFEST_FILENAME)

.PHONY: osci/_pull
# Pull the configured pipeline repo
osci/_pull: %_pull:
	@cd $(OSCI_MANIFEST_DIR); $(GIT) pull --quiet

.PHONY: osci/_clone
# Clone the configured pipeline repo
osci/_clone: %_clone:
	@if [ -d $(OSCI_MANIFEST_DIR) ];  \
	then $(SELF) -s osci/_pull; \
	else $(GIT) clone -b $(OSCI_PIPELINE_GIT_BRANCH) $(OSCI_PIPELINE_GIT_URL) $(OSCI_MANIFEST_DIR); \
	fi
	@cd $(OSCI_MANIFEST_DIR); $(GIT) config user.email $(OSCI_GIT_USER_EMAIL)
	@cd $(OSCI_MANIFEST_DIR); $(GIT) config user.name $(OSCI_GIT_USER_NAME)

.PHONY: osci/_snapshot-staging
# Stage snapshot of current repo.
osci/_snapshot-staging: %_snapshot-staging: %_clone
	@$(SELF) osci/_datetime_gen
	@cp $(OSCI_MANIFEST_DIR)/$(OSCI_MANIFEST_FILENAME) $(OSCI_MANIFEST_FILENAME)
	@cp $(OSCI_MANIFEST_DIR)/$(OSCI_IMAGE_ALIAS_FILENAME) $(OSCI_IMAGE_ALIAS_FILENAME)
	@cd $(OSCI_MANIFEST_DIR); git checkout $(OSCI_PIPELINE_RETAG_BRANCH)
	@echo $(OSCI_PIPELINE_GIT_BRANCH) > $(OSCI_MANIFEST_DIR)/ORIGIN_BRANCH
	@echo $(OSCI_RELEASE_VERSION) > $(OSCI_MANIFEST_DIR)/RELEASE_VERSION
	@echo $(OSCI_Z_RELEASE_VERSION) > $(OSCI_MANIFEST_DIR)/Z_RELEASE_VERSION
	@echo $(OSCI_COMPONENT_NAME) > $(OSCI_MANIFEST_DIR)/COMPONENT_NAME
	@cat DATETIME > $(OSCI_MANIFEST_DIR)/TAG
	@cp $(OSCI_MANIFEST_FILENAME) $(OSCI_MANIFEST_DIR)/$(OSCI_MANIFEST_FILENAME)
	@cp $(OSCI_IMAGE_ALIAS_FILENAME) $(OSCI_MANIFEST_DIR)/$(OSCI_IMAGE_ALIAS_FILENAME)
	@cd $(OSCI_MANIFEST_DIR); $(GIT) commit -am "Stage $(OSCI_Z_RELEASE_VERSION) snapshot of $(OSCI_COMPONENT_NAME)-$(OSCI_COMPONENT_SUFFIX)" --quiet
	@cd $(OSCI_MANIFEST_DIR); $(GIT) push --quiet


.PHONY: osci/_push
# Push the configured pipeline manifest repo
osci/_push: %_push: %_clone
	@$(SELF) osci/_sort
	@cd $(OSCI_MANIFEST_DIR); $(GIT) commit -am "$(OSCI_GIT_MESSAGE)" --quiet
	@cd $(OSCI_MANIFEST_DIR); $(GIT) push --quiet
	@$(SELF) osci/_snapshot-staging

.PHONY: osci/_read_alias
# Locate the component name in the alias json
osci/_read_alias: %_read_alias: %_clone
	@$(OSCI_JQ) '$(OSCI_MANIFEST_QUERY)' $(OSCI_MANIFEST_DIR)/$(OSCI_IMAGE_ALIAS_FILENAME)

.PHONY: osci/_read
# Parse the configured pipeline manifest repo
osci/_read: %_read: %_clone
	@$(OSCI_JQ) '$(OSCI_MANIFEST_QUERY)' $(OSCI_MANIFEST_DIR)/$(OSCI_MANIFEST_FILENAME)

.PHONY: osci/add
# Add component named $OSCI_COMPONENT_NAME at version $OSCI_COMPONENT_VERSION to the pipeline manifest in stage $OSCI_PIPELINE_STAGE
osci/add: %add: %_clone %_add
	@$(SELF) osci/_push OSCI_GIT_MESSAGE="Added $(OSCI_COMPONENT_NAME)"

.PHONY: osci/_add
# Add component named $OSCI_COMPONENT_NAME at version $OSCI_COMPONENT_VERSION to the pipeline manifests in stage $OSCI_PIPELINE_STAGE
osci/_add: %_add:
	$(call assert-set,OSCI_COMPONENT_NAME)
	$(call assert-set,OSCI_COMPONENT_VERSION)
	$(call assert-set,OSCI_COMPONENT_REPO)
	$(call assert-set,OSCI_COMPONENT_SHA256)
	@$(OSCI_JQ) '$(OSCI_ADDITION_QUERY)' $(OSCI_MANIFEST_DIR)/$(OSCI_MANIFEST_FILENAME) > tmp
	@mv tmp $(OSCI_MANIFEST_DIR)/$(OSCI_MANIFEST_FILENAME)

.PHONY: osci/replace
## Remove component named $OSCI_REPLACED_COMPONENT and add component named $OSCI_COMPONENT_NAME at version $OSCI_COMPONENT_VERSION in stage $OSCI_PIPELINE_STAGE
osci/replace: %replace: %_clone %_replace
	@$(SELF) osci/_push OSCI_GIT_MESSAGE="Replaced $(OSCI_REPLACED_COMPONENT) with $(OSCI_COMPONENT_NAME)"

.PHONY: osci/_replace
# Remove component named $OSCI_REPLACED_COMPONENT and add component named $OSCI_COMPONENT_NAME at version $OSCI_COMPONENT_VERSION in stage $OSCI_PIPELINE_STAGE
osci/_replace: %_replace:
	$(call assert-set,OSCI_COMPONENT_NAME)
	$(call assert-set,OSCI_COMPONENT_VERSION)
	$(call assert-set,OSCI_REPLACED_COMPONENT)
	@$(SELF) osci/_delete OSCI_DELETED_COMPONENT=$(OSCI_REPLACED_COMPONENT)
	@$(SELF) osci/_add

.PHONY: osci/delete
## Remove component named $OSCI_DELETED_COMPONENT from $OSCI_PIPELINE_STAGE's manifest pipeline
osci/delete: %delete: %_clone %_delete
	@$(SELF) osci/_push OSCI_GIT_MESSAGE="Deleted $(OSCI_DELETED_COMPONENT)"

.PHONY: osci/_delete
# Remove component named $OSCI_DELETED_COMPONENT from $OSCI_PIPELINE_STAGE's manifest pipeline
osci/_delete: %_delete:
	$(call assert-set,OSCI_DELETED_COMPONENT)
	@$(OSCI_JQ) '[$(OSCI_DELETION_QUERY)]' $(OSCI_MANIFEST_DIR)/$(OSCI_MANIFEST_FILENAME) > tmp
	@mv tmp $(OSCI_MANIFEST_DIR)/$(OSCI_MANIFEST_FILENAME)

.PHONY: osci/publish
## Add or update component $OSCI_COMPONENT_NAME to have version $OSCI_COMPONENT_VERSION in the pipeline manifest in stage $OSCI_PIPELINE_STAGE
osci/publish: %publish: %_clone %_publish
	@$(SELF) osci/_push OSCI_GIT_MESSAGE="Updated $(OSCI_COMPONENT_NAME)"
	@echo "Successfully updated ${OSCI_COMPONENT_NAME} to ${OSCI_COMPONENT_NAME}:${OSCI_COMPONENT_VERSION} in https://$(OSCI_PIPELINE_SITE)/$(OSCI_PIPELINE_ORG)/$(OSCI_PIPELINE_REPO)#$(OSCI_RELEASE_VERSION)-$(OSCI_PIPELINE_STAGE)"

.PHONY: osci/_publish
# Add or update component $OSCI_COMPONENT_NAME to have version $OSCI_COMPONENT_VERSION in the pipeline manifest in stage $OSCI_PIPELINE_STAGE
osci/_publish: %_publish:
	$(call assert-set,OSCI_COMPONENT_NAME)
	$(call assert-set,OSCI_COMPONENT_VERSION)
	@if [[ -z `$(SELF) -s osci/_read_alias` ]]; \
	then echo "Component $(OSCI_COMPONENT_NAME) does not have an entry in $(OSCI_MANIFEST_DIR)/$(OSCI_IMAGE_ALIAS_FILENAME)" ; echo "Failing the build." ; exit 1; \
	else echo "Component $(OSCI_COMPONENT_NAME) has an entry in $(OSCI_MANIFEST_DIR)/$(OSCI_IMAGE_ALIAS_FILENAME)"; \
	fi
	@echo `date`: Waiting $(OSCI_PUBLISH_DELAY) minutes for post commit images job to finish
	@sleep $$(( $(OSCI_PUBLISH_DELAY) * 60 ))
	@echo `date`: Done waiting
	@if [ -z "$(SELF) -s osci/_read" ]; \
	then $(SELF) osci/_add; \
	else $(SELF) osci/_replace OSCI_REPLACED_COMPONENT=$(OSCI_COMPONENT_NAME); \
	fi
