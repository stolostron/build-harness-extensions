# A simple build harness module to install the newest version of the oc cli.

OC_BUILD_VERSION ?= latest
OC_PLATFORM ?= $(shell echo $(BUILD_HARNESS_OS) | sed 's/darwin/mac/g')
OC_SOURCE_URL ?= https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$(OC_BUILD_VERSION)

OC_DEST_PATH ?= ${BUILD_HARNESS_PATH}/vendor
OC_TAR_PATH ?= ${OC_DEST_PATH}/oc.tar.gz
OC ?= ${OC_DEST_PATH}/oc
OC_CLUSTER_USER ?=
OC_CLUSTER_PASS ?=
OC_CLUSTER_TOKEN ?=
OC_CLUSTER_URL ?=
OC_LOGIN_OPTIONS ?= --insecure-skip-tls-verify=true
OC_COMMAND ?=
OC_LOGGED_IN ?= $(OC_DEST_PATH)/.oc_cli_logged_in
OC_FORCE_LOGIN ?= 
OC_SILENT ?= true

.PHONY: oc/install
## Install the oc cli
#   Contains GLIBC version detection since `oc` v4.16 is compatible with GLIBC 2.32 and greater. Errors appear as:
#   oc: /lib64/libc.so.6: version `GLIBC_2.34' not found (required by oc)
oc/install: %install:
	@if [ ! -x $(OC) ]; then \
		OC_BINARY="openshift-client-${OC_PLATFORM}"; \
		if command -v ldd $&>/dev/null; then \
			OC_LIBC_VERSION="$$(ldd --version | head -1 | awk '{print $$NF}')"; \
		fi; \
		if [ -n "$${OC_LIBC_VERSION}" ] && [  "$${OC_LIBC_VERSION%\.*}" -le "2" ] && [ "$${OC_LIBC_VERSION#*\.}" -lt "32" ]; then \
			OC_BINARY="$${OC_BINARY}-${BUILD_HARNESS_ARCH}-rhel8"; \
		fi; \
		if [ ! -z "$(OC_SILENT)" ]; then \
			curl -s -L -X GET ${OC_SOURCE_URL}/$${OC_BINARY}.tar.gz -o ${OC_TAR_PATH} > /dev/null; \
			tar -xf ${OC_TAR_PATH} -C ${OC_DEST_PATH} > /dev/null; \
			rm -f ${OC_TAR_PATH} > /dev/null; \
		else \
			curl -L -X GET ${OC_SOURCE_URL}/$${OC_BINARY}.tar.gz -o ${OC_TAR_PATH}; \
			tar -xf ${OC_TAR_PATH} -C ${OC_DEST_PATH}; \
			rm -f ${OC_TAR_PATH}; \
		fi \
	fi;

.PHONY: oc/login
## Login to the OC Environment
oc/login: %login: %install
	@if [ ! -z "$(OC_FORCE_LOGIN)" ] || [ ! -e "$(OC_LOGGED_IN)" ]; then \
		if [ ! -z "$(OC_SILENT)" ]; then \
			if [ ! -z "$(OC_CLUSTER_TOKEN)" ]; then \
				$(OC) login $(OC_CLUSTER_URL) $(OC_LOGIN_OPTIONS) --token=$(OC_CLUSTER_TOKEN) > /dev/null && touch $(OC_LOGGED_IN); \
			else \
				if [ -z "$(OC_CLUSTER_USER)" ]; then echo OC_CLUSTER_USER unset;  exit 1; fi; \
				if [ -z "$(OC_CLUSTER_PASS)" ]; then echo OC_CLUSTER_PASS unset;  exit 1; fi; \
				$(OC) login $(OC_CLUSTER_URL) $(OC_LOGIN_OPTIONS) -u $(OC_CLUSTER_USER) -p $(OC_CLUSTER_PASS) > /dev/null && touch $(OC_LOGGED_IN); \
			fi; \
		else \
			if [ ! -z "$(OC_CLUSTER_TOKEN)" ]; then \
				$(OC) login $(OC_CLUSTER_URL) $(OC_LOGIN_OPTIONS) --token=$(OC_CLUSTER_TOKEN) && touch $(OC_LOGGED_IN); \
			else \
				if [ -z "$(OC_CLUSTER_USER)" ]; then echo OC_CLUSTER_USER unset;  exit 1; fi; \
				if [ -z "$(OC_CLUSTER_PASS)" ]; then echo OC_CLUSTER_PASS unset;  exit 1; fi; \
				$(OC) login $(OC_CLUSTER_URL) $(OC_LOGIN_OPTIONS) -u $(OC_CLUSTER_USER) -p $(OC_CLUSTER_PASS) && touch $(OC_LOGGED_IN); \
			fi; \
		fi; \
	fi;

.PHONY: oc/command
## Run $(OC_COMMAND) from CLI
oc/command: %command: %install %login
	$(OC) $(OC_COMMAND) 
	@if [ "$(OC_COMMAND)" = "logout" ]; \
	then rm -f $(OC_LOGGED_IN); \
	fi
