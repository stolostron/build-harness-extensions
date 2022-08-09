# In OpenShift CI, pull related variables are named differently than in Travis.
# They also are not injected until the container starts, so they can't be passed
# in as arguments to make. See:
#
# https://github.com/kubernetes/test-infra/blob/master/prow/jobs.md#job-environment-variables
#
export OSCI_COMPONENT_REPO ?= ${REPO_OWNER}/${REPO_NAME}
export OSCI_COMPONENT_BRANCH ?= ${PULL_BASE_REF}
export OSCI_COMPONENT_SHA256 ?= ${PULL_BASE_SHA}

export OSCI_COMPONENT_NAME ?= $(shell cat COMPONENT_NAME 2> /dev/null)

export OSCI_PIPELINE_PRODUCT_PREFIX ?= release

export OSCI_RELEASE_VERSION ?= $(subst $(OSCI_PIPELINE_PRODUCT_PREFIX)-,,$(OSCI_COMPONENT_BRANCH))
export OSCI_RELEASE_SHA_VERSION ?= $(OSCI_RELEASE_VERSION)

export OSCI_PIPELINE_SITE ?= github.com
export OSCI_PIPELINE_ORG ?= $(PIPELINE_MANIFEST_ORG)
export OSCI_PIPELINE_REPO ?= pipeline
export OSCI_PIPELINE_DIR ?= $(OSCI_PIPELINE_REPO)
export OSCI_PIPELINE_STAGE ?= integration
export OSCI_PIPELINE_RETAG_BRANCH ?= quay-retag
export OSCI_PIPELINE_PROMOTE_FROM ?= $(OSCI_PIPELINE_STAGE)
export OSCI_PIPELINE_PROMOTE_TO ?=
export OSCI_PIPELINE_GIT_BRANCH ?= $(OSCI_RELEASE_VERSION)-$(OSCI_PIPELINE_PROMOTE_FROM)
export OSCI_PIPELINE_GIT_URL ?= https://$(GITHUB_USER):$(GITHUB_TOKEN)@$(OSCI_PIPELINE_SITE)/$(OSCI_PIPELINE_ORG)/$(OSCI_PIPELINE_REPO).git

export OSCI_MANIFEST_BASENAME ?= manifest
export OSCI_MANIFEST_FILENAME ?= $(OSCI_MANIFEST_BASENAME).json
export OSCI_IMAGE_ALIAS_BASENAME ?= image-alias
export OSCI_IMAGE_ALIAS_FILENAME ?= $(OSCI_IMAGE_ALIAS_BASENAME).json
export OSCI_MANIFEST_SNAPSHOT_DIR ?= snapshots

# How long to wait, in minutes, for the images job to finish before triggering
# the actual work of the publish job.
export OSCI_PUBLISH_DELAY ?= 5

export OSCI_IMAGE_REMOTE_REPO ?= $(PIPELINE_MANIFEST_REMOTE_REPO)
export OSCI_IMAGE_REMOTE_REPO_SRC ?= $(OSCI_IMAGE_REMOTE_REPO)
export OSCI_IMAGE_REMOTE_REPO_DST ?= $(OSCI_IMAGE_REMOTE_REPO)

export OSCI_GIT_USER_NAME ?= "ACM CICD"
export OSCI_GIT_USER_EMAIL ?= "acm-cicd@redhat.com"
export OSCI_GIT_MESSAGE ?= Added or Updated $(OSCI_COMPONENT_NAME)

export OSCI_Z_RELEASE_VERSION ?= $(shell curl --silent -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3.raw" https://raw.githubusercontent.com/${OSCI_PIPELINE_ORG}/release/${OSCI_COMPONENT_BRANCH}/Z_RELEASE_VERSION)

export OSCI_COMPONENT_SUFFIX ?= $(OSCI_COMPONENT_SHA256)
export OSCI_COMPONENT_TAG ?= $(OSCI_Z_RELEASE_VERSION)-$(OSCI_COMPONENT_SUFFIX)

export OSCI_MANIFEST_QUERY ?= .[] |select(.["image-name"] == "$(OSCI_COMPONENT_NAME)")
export OSCI_ADDITION_QUERY ?= .[. | length] |= . + {"image-name": "$(OSCI_COMPONENT_NAME)", "image-version": "$(OSCI_RELEASE_VERSION)", "image-tag": "$(OSCI_COMPONENT_TAG)", "git-sha256": "$(OSCI_COMPONENT_SHA256)", "git-repository": "$(OSCI_COMPONENT_REPO)",  "image-remote": "$(OSCI_IMAGE_REMOTE_REPO_DST)", "image-remote-src": "$(OSCI_IMAGE_REMOTE_REPO_SRC)"}
export OSCI_DELETION_QUERY ?= .[] | select(.["image-name"] != "$(OSCI_COMPONENT_NAME)")
export OSCI_SORT_QUERY ?= . | sort_by(.["image-name"])

export OSCI_DATETIME := $(shell (date +%Y-%m-%d-%H-%M-%S))

.PHONY: osci/publish
## Add or update component $OSCI_COMPONENT_NAME to have version $OSCI_Z_RELEASE_VERSION in the pipeline manifest in stage $OSCI_PIPELINE_STAGE
osci/publish:
	@$(BUILD_HARNESS_EXTENSIONS_PATH)/modules/osci/bin/osci_publish.sh
