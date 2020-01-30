# A simple build harness module to install the newest version of the oc cli.

OC_BUILD_VERSION?=latest
OC_SOURCE_URL?="https://mirror.openshift.com/pub/openshift-v4/clients/oc/${OC_BUILD_VERSION}/linux/oc.tar.gz"

OC_DEST_PATH?=${BUILD_HARNESS_PATH}/vendor
OC_TAR_PATH?=${OC_DEST_PATH}/oc.tar.gz
OC?=${OC_DEST_PATH}/oc

.PHONY: oc/install
## Install the oc cli
oc/install: %install:
	wget -O ${OC_TAR_PATH} ${OC_SOURCE_URL}
	tar -xf ${OC_TAR_PATH} -C ${OC_DEST_PATH}
	rm -f ${OC_TAR_PATH}