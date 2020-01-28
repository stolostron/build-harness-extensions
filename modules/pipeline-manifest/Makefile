# GITHUB_USER containing '@' char must be escaped with '%40'
GITHUB_USER := $(shell echo $(GITHUB_USER) | sed 's/@/%40/g')
GITHUB_TOKEN ?=

# The URL for the pipeline repo
PIPELINE_MANIFEST_GIT_REPO ?= 
# The name of the component to modify
PIPELINE_MANIFEST_COMPONENT ?= 
# The payload to change of the component specified by PIPELINE_MANIFEST_COMPONENT
PIPELINE_MANIFEST_PAYLOAD ?= 

.PHONY: pipeline-manifest/clone
## Clone the configured pipeline manifest repo
pipeline-manifest/clone: %clone:
	@echo pipeline-manifest/clone

.PHONY: pipeline-manifest/pull
## Pull the configured pipeline manifest repo
pipeline-manifest/pull: %pull:
	@echo pipeline-manifest/pull

.PHONY: pipeline-manifest/push
## Push the configured pipeline manifest repo
pipeline-manifest/push: %push:
	@echo pipeline-manifest/push

.PHONY: pipeline-manifest/update
## Update the pipeline manifest for the specified component
pipeline-manifest/update: %update:
	@echo pipeline-manifest/update

