CURL := $(shell which curl)
DOCKER := $(shell which docker)

QUAY_DRY_RUN ?= false
QUAY_TOKEN ?= 
QUAY_COMPONENT_TAG ?=
QUAY_RETAG_NAME ?=
PIPELINE_MANIFEST_ORG ?= open-cluster-management

# Retag needs to do the following steps:
#  1. Find an image in quay based on what we would call the team's docker tag, and pull out and assign 'QUAY_SHA' from that
#  2. If QUAY_DRY_RUN is set to `true`, then report on the existence or nonexistence of the image; exit with 1 if it doesn't exist 
#  3. If QUAY_DRY_RUN is set to anything other than `true`, use QUAY_SHA as the manifest_digest and tag that image with the snapshot value 'QUAY_RETAG_NAME'
.PHONY: quay/retag
## Add a tag to an image
quay/retag: %retag:
	$(call assert-set,QUAY_TOKEN)
	$(call assert-set,QUAY_RETAG_NAME)
	$(call assert-set,COMPONENT_NAME)
	$(call assert-set,QUAY_COMPONENT_TAG)
	$(call assert-set,PIPELINE_MANIFEST_ORG)
	@$(SELF) jq/install > /dev/null
	@$(eval QUAY_SHA := $(shell $(CURL) -X GET -H "Authorization: Bearer ${QUAY_TOKEN}" "https://quay.io/api/v1/repository/${PIPELINE_MANIFEST_ORG}/${COMPONENT_NAME}/tag/?onlyActiveTags=true&specificTag=${QUAY_COMPONENT_TAG}" | $(JQ) -r .tags[0].manifest_digest))
	@if [ "${QUAY_SHA}" == "null" ] ;then (echo "Tag ${QUAY_COMPONENT_TAG} doesn't exist"; exit 1) ; fi
	@if [ "${QUAY_DRY_RUN}" == "true" ]; \
	then echo "Tag ${QUAY_COMPONENT_TAG} exists"; \
	else $(CURL) -X PUT -H "Authorization: Bearer ${QUAY_TOKEN}" "https://quay.io/api/v1/repository/${PIPELINE_MANIFEST_ORG}/${COMPONENT_NAME}/tag/${QUAY_RETAG_NAME}" -H "Content-Type: application/json" --data '{"manifest_digest": "${QUAY_SHA}"}' ; \
	fi
