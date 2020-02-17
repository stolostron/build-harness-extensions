# Full path to this modules' scripts directory.
CONFIGSCAN_DIR=${BUILD_HARNESS_PATH}/../build-harness-extensions/modules/configscan

# Find component name and component version from repo artifacts
CONFIGSCAN_IMAGE_NAME ?= $(shell cat ${BUILD_HARNESS_PATH}/../COMPONENT_NAME 2> /dev/null)
CONFIGSCAN_IMAGE_VERSION ?= $(shell cat ${BUILD_HARNESS_PATH}/../COMPONENT_VERSION 2> /dev/null)
CONFIGSCAN_IMAGE_TAG_EXTENSION ?= ${COMPONENT_TAG_EXTENSION}

# Build the details for the remote destination repo for the image
CONFIGSCAN_DOCKER_REPO ?= "quay.io/open-cluster-management"

# List of pattern to scan in the image
CONFIGSCAN_PATTERNS ?= "password;_pwd;secret;signature;token;key;[\d|a-z]{40}@;=[\d|a-z]{40,64};\"[\d|a-z]{40,64}\""


.PHONY: configscan/report
## Scan the image config to find potential leaked credentials
configscan/report: %report:
	@$(call assert-set,CONFIGSCAN_IMAGE_NAME)
	@$(call assert-set,CONFIGSCAN_IMAGE_VERSION)
	@python3 $(CONFIGSCAN_DIR)/configscan.py --image $(CONFIGSCAN_DOCKER_REPO)/$(CONFIGSCAN_IMAGE_NAME):$(CONFIGSCAN_IMAGE_VERSION)$(CONFIGSCAN_IMAGE_TAG_EXTENSION) --patterns $(CONFIGSCAN_PATTERNS)
