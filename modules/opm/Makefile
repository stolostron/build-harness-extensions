CURL := $(shell which curl 2> /dev/null)
OPM_VERSION ?= v1.6.1
OPM_URL ?= https://github.com/operator-framework/operator-registry/releases/download/$(OPM_VERSION)/$(BUILD_HARNESS_OS)-$(BUILD_HARNESS_ARCH)-opm
OPM ?= $(BUILD_HARNESS_PATH)/vendor/opm

# A comma-separated list of bundle images (e.g. make catalog-build OPM_BUNDLE_IMGS=quay.io/identitatem/idp-mgmt-config-bundle:0.0.1,quay.io/identitatem/idp-mgmt-config-bundle:0.0.2).
# These images MUST exist in a registry and be pull-able.
OPM_BUNDLE_IMGS ?= $(OPM_BUNDLE_IMG)

# The image tag given to the resulting catalog image (e.g. make catalog-build CATALOG_IMG=quay.io/identitatem/idp-mgmt-config-catalog:0.0.1).
OPM_CATALOG_IMG ?= $(OPM_IMAGE_TAG_BASE)-catalog:v$(OPM_VERSION)

# Set CATALOG_BASE_IMG to an existing catalog image tag to add $OPM_BUNDLE_IMGS to that image.
ifneq ($(origin OPM_CATALOG_BASE_IMG), undefined)
OPM_FROM_INDEX_OPT := --from-index $(OPM_CATALOG_BASE_IMG)
endif

.PHONY: opm/install
## Install opm
opm/install: %install:
	@[ -x $(OPM) ] || ( \
		echo "Version: $(OPM_VERSION) Platform: $(OPM_PLATFORM) Arch: $(OPM_ARCH)" && \
		echo "Installing OPM $(OPM_VERSION) ($(BUILD_HARNESS_OS)-$(BUILD_HARNESS_ARCH)-opm) from $(OPM_URL)" && \
		curl '-#' -fL -o $(OPM) $(OPM_URL) && \
		chmod +x $(OPM) \
		)


# Build a catalog image by adding bundle images to an empty catalog using the operator package manager tool, 'opm'.
# This recipe invokes 'opm' in 'semver' bundle add mode. For more information on add modes, see:
# https://github.com/operator-framework/community-operators/blob/7f1438c/docs/packaging-operator.md#updating-your-existing-operator
.PHONY: opm/catalog-build
## Build a catalog image.
opm/catalog-build: opm/install
	$(OPM) index add --container-tool docker --mode semver --tag $(OPM_CATALOG_IMG) --bundles $(OPM_BUNDLE_IMGS) $(OPM_FROM_INDEX_OPT)
