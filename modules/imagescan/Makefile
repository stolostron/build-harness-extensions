# Full path to this modules' scripts directory.
IMAGESCAN_DIR=${BUILD_HARNESS_PATH}/../build-harness-extensions/modules/imagescan

# Find component name and component version from repo artifacts
IMAGESCAN_IMAGE_NAME ?= $(shell cat ${BUILD_HARNESS_PATH}/../COMPONENT_NAME 2> /dev/null)
IMAGESCAN_IMAGE_VERSION ?= $(shell cat ${BUILD_HARNESS_PATH}/../COMPONENT_VERSION 2> /dev/null)
IMAGESCAN_IMAGE_TAG_EXTENSION ?= ${COMPONENT_TAG_EXTENSION}

# Build the details for the remote destination repo for the image
IMAGESCAN_DOCKER_REPO ?= "quay.io/open-cluster-management"
IMAGESCAN_TOKEN ?= "eDA5ZlNIMnlKMWZXbER6bVZvSThHMmFVeWNlenJHeTM3SExmR3VPUQ=="

.PHONY: imagescan/status
## Check the image scan status
imagescan/status: %status:
	@$(call assert-set,IMAGESCAN_TOKEN)
	@$(call assert-set,IMAGESCAN_IMAGE_NAME)
	@$(call assert-set,IMAGESCAN_IMAGE_VERSION)
	@python3 $(IMAGESCAN_DIR)/imagescan.py --image ${IMAGESCAN_DOCKER_REPO}/${IMAGESCAN_IMAGE_NAME}:${IMAGESCAN_IMAGE_VERSION}${IMAGESCAN_IMAGE_TAG_EXTENSION} --imagescan_token $(IMAGESCAN_TOKEN)
