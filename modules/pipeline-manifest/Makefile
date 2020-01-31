# GITHUB_USER containing '@' char must be escaped with '%40'
GITHUB_USER := $(shell echo $(GITHUB_USER) | sed 's/@/%40/g')
GITHUB_TOKEN ?=

# May or may not be in github enterprise
PIPELINE_MANIFEST_SITE ?= github.ibm.com
# May be in RedHat main org or in some ACM specific org
PIPELINE_MANIFEST_ORG ?= IBMPrivateCloud
# Repo name not yet confirmed
PIPELINE_MANIFEST_REPO?= mvp-pipeline
# The URL for the pipeline repo
PIPELINE_MANIFEST_GIT_URL ?= "https://$(GITHUB_USER):$(GITHUB_TOKEN)@$(PIPELINE_MANIFEST_SITE)/$(PIPELINE_MANIFEST_ORG)/$(PIPELINE_MANIFEST_REPO).git"
# Branch of manifest to pull
PIPELINE_MANIFEST_BRANCH ?= master
# Directory to put manifest in
PIPELINE_MANIFEST_DIR ?= $(PIPELINE_MANIFEST_REPO)
# The name of the component to modify
PIPELINE_MANIFEST_COMPONENT ?= $(COMPONENT_NAME)
# The payload to change of the component specified by PIPELINE_MANIFEST_COMPONENT
PIPELINE_MANIFEST_VERSION ?= $(COMPONENT_VERSION)

PIPELINE_MANIFEST_REMOTE_REPO ?= quay.io/mvpcicdpipeline

PIPELINE_STAGE ?= integration
PM_MANIFEST_QUERY ?= .[] |select(.name == "$(PIPELINE_MANIFEST_COMPONENT)")
PM_ADDITION_QUERY ?= .[. | length] |= . + {"name": "$(PIPELINE_MANIFEST_COMPONENT)", "tag": "$(PIPELINE_MANIFEST_VERSION)-$(PIPELINE_MANIFEST_COMPONENT_SHA256)", "sha256": "$(PIPELINE_MANIFEST_COMPONENT_SHA256)", "repository": "$(PIPELINE_MANIFEST_COMPONENT_REPO)",  "remote": "$(PIPELINE_MANIFEST_REMOTE_REPO)"}
PM_DELETION_QUERY ?= .[] | select(.name != "$(DELETED_COMPONENT)")
PM_SORT_QUERY ?= . | sort_by(.name)

REPLACED_COMPONENT ?=
DELETED_COMPONENT ?=


.PHONY: pipeline-manifest/_sort
# Parse the configured pipeline manifest repo
pipeline-manifest/_sort: %_sort:
	@$(JQ) '$(PM_SORT_QUERY)' $(PIPELINE_MANIFEST_DIR)/$(PIPELINE_STAGE).json > tmp; mv tmp $(PIPELINE_MANIFEST_DIR)/$(PIPELINE_STAGE).json

.PHONY: pipeline-manifest/_clone
# Clone the configured pipeline manifest repo
pipeline-manifest/_clone: %_clone:
	@$(shell $(SELF) jq/install 1&>2 /dev/null)
	@if [ -d $(PIPELINE_MANIFEST_DIR) ];  \
	then $(SELF) -s pipeline-manifest/_pull; \
	else $(GIT) clone -b $(PIPELINE_MANIFEST_BRANCH) $(PIPELINE_MANIFEST_GIT_URL) $(PIPELINE_MANIFEST_DIR); \
	fi

.PHONY: pipeline-manifest/_pull
# Pull the configured pipeline manifest repo
pipeline-manifest/_pull: %_pull:
	@cd $(PIPELINE_MANIFEST_DIR); $(GIT) pull --quiet

.PHONY: pipeline-manifest/_push
# Push the configured pipeline manifest repo
pipeline-manifest/_push: %_push:
	@$(SELF) pipeline-manifest/_sort
	@cd $(PIPELINE_MANIFEST_DIR); $(GIT) commit -am "$(PIPELINE_GIT_MESSAGE)" --quiet
	@cd $(PIPELINE_MANIFEST_DIR); $(GIT) push --quiet

.PHONY: pipeline-manifest/_read
# Parse the configured pipeline manifest repo
pipeline-manifest/_read: %_read: %_clone
	@$(JQ) '$(PM_MANIFEST_QUERY)' $(PIPELINE_MANIFEST_DIR)/$(PIPELINE_STAGE).json

.PHONY: pipeline-manifest/add
# Add component named $COMPONENT_NAME at version $COMPONENT_VERSION to the pipeline manifest in stage $PIPELINE_STAGE 
pipeline-manifest/add: %add: %_clone %_add
	@$(SELF) pipeline-manifest/_push PIPELINE_GIT_MESSAGE="Added $(PIPELINE_MANIFEST_COMPONENT)"

.PHONY: pipeline-manifest/_add
# Add component named $COMPONENT_NAME at version $COMPONENT_VERSION to the pipeline manifest in stage $PIPELINE_STAGE 
pipeline-manifest/_add: %_add:
	$(call assert-set,COMPONENT_NAME)
	$(call assert-set,COMPONENT_VERSION)
	$(call assert-set,PIPELINE_MANIFEST_COMPONENT_REPO)
	$(call assert-set,PIPELINE_MANIFEST_COMPONENT_SHA256)
	@$(JQ) '$(PM_ADDITION_QUERY)' $(PIPELINE_MANIFEST_DIR)/$(PIPELINE_STAGE).json > tmp; mv tmp $(PIPELINE_MANIFEST_DIR)/$(PIPELINE_STAGE).json

.PHONY: pipeline-manifest/update
## Add or update component $COMPONENT_NAME to have version $COMPONENT_VERSION in the pipeline manifest in stage $PIPELINE_STAGE
pipeline-manifest/update: %update: %_clone %_update
	@$(SELF) pipeline-manifest/_push PIPELINE_GIT_MESSAGE="Updated $(PIPELINE_MANIFEST_COMPONENT)"

.PHONY: pipeline-manifest/_update
# Update component $COMPONENT_NAME to have version $COMPONENT_VERSION in the pipeline manifest in stage $PIPELINE_STAGE
pipeline-manifest/_update: %_update:
	$(call assert-set,COMPONENT_NAME)
	$(call assert-set,COMPONENT_VERSION)
	@if [ -z "$(SELF) -s pipeline-manifest/_read" ]; \
	then $(SELF) pipeline-manifest/_add; \
	else $(SELF) pipeline-manifest/_replace REPLACED_COMPONENT=$(PIPELINE_MANIFEST_COMPONENT); \
	fi

.PHONY: pipeline-manifest/replace
## Remove component named $REPLACED_COMPONENT and add component named $COMPONENT_NAME at version $COMPONENT_VERSION in stage $PIPELINE_STAGE
pipeline-manifest/replace: %replace: %_clone %_replace
	@$(SELF) pipeline-manifest/_push PIPELINE_GIT_MESSAGE="Replaced $(REPLACED_COMPONENT) with $(PIPELINE_MANIFEST_COMPONENT)"

.PHONY: pipeline-manifest/_replace
# Remove component named $REPLACED_COMPONENT and add component named $COMPONENT_NAME at version $COMPONENT_VERSION in stage $PIPELINE_STAGE
pipeline-manifest/_replace: %_replace:
	$(call assert-set,COMPONENT_NAME)
	$(call assert-set,COMPONENT_VERSION)
	$(call assert-set,REPLACED_COMPONENT)
	@$(SELF) pipeline-manifest/_delete DELETED_COMPONENT=$(REPLACED_COMPONENT)
	@$(SELF) pipeline-manifest/_add

.PHONY: pipeline-manifest/delete
## Remove component named $DELETED_COMPONENT from $PIPELINE_STAGE's manifest pipeline
pipeline-manifest/delete: %delete: %_clone %_delete
	@$(SELF) pipeline-manifest/_push PIPELINE_GIT_MESSAGE="Deleted $(PIPELINE_MANIFEST_COMPONENT)"

.PHONY: pipeline-manifest/_delete
# Remove component named $DELETED_COMPONENT from $PIPELINE_STAGE's manifest pipeline
pipeline-manifest/_delete: %_delete:
	$(call assert-set,DELETED_COMPONENT)
	@$(JQ) '[$(PM_DELETION_QUERY)]' $(PIPELINE_MANIFEST_DIR)/$(PIPELINE_STAGE).json > tmp; mv tmp $(PIPELINE_MANIFEST_DIR)/$(PIPELINE_STAGE).json

.PHONY: pipeline-manifest/_promote
# Remove component named $DELETED_COMPONENT from $PIPELINE_STAGE's manifest pipeline
pipeline-manifest/_promote: %_promote: %_clone:
	$(call assert-set,PROMTE_FROM)
	$(call assert-set,PROMTE_TO)
	cp $(PROMTE_FROM).json $(PROMTE_TO).json