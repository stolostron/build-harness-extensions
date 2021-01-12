#!/bin/bash

# Execute all the mechanics of creating a custom catalog
#  1. Make sure we can talk to brew to extract the downstream build contents
#  2. Check out/refresh the ashdod and release projects, required for this process
#  3. Mirror the built images
#  3b. Mirror the openshift images
#  4. Query the production redhat docker registry to see what upgrade bundles we can add
#  5. Build our catalog and push it

# Get logged into brew, update/check out the repos we need
echo Preparing environment for release $Z_RELEASE_VERSION tagged as $PIPELINE_MANFIEST_INDEX_IMAGE_TAG...
OC=$BUILD_HARNESS_PATH/vendor/oc
BIN_PATH=$BUILD_HARNESS_PATH/../build-harness-extensions/modules/pipeline-manifest/bin
rm -rf /tmp/acm-custom-registry
brew hello
if [ -d ashdod ];  \
    then cd ashdod; git pull --quiet;cd ..; \
    else git clone -b master git@github.com:rh-deliverypipeline/ashdod.git ashdod; \
fi
if [ -d release ];  \
    then cd release; git checkout release-$PIPELINE_MANIFEST_RELEASE_VERSION; git pull --quiet;cd ..; \
    else git clone -b release-$PIPELINE_MANIFEST_RELEASE_VERSION git@github.com:open-cluster-management/release.git release; \
fi

# Mirror the images we explicitly build
echo Mirroring main images from advisory $PIPELINE_MANIFEST_ADVISORY_ID...
cd ashdod; python3 -u ashdod/main.py --advisory_id $PIPELINE_MANIFEST_ADVISORY_ID --org $PIPELINE_MANIFEST_MIRROR_ORG | tee ../.ashdod_output; cd ..
if [[ ! -s .ashdod_output ]]; then
  echo No output from ashdod\; aborting
  exit 1
fi
echo "acm-operator-bundle tag:"
cat .ashdod_output | grep "Image to mirror: acm-operator-bundle:" | awk -F":" '{print $3}' | tee .acm_operator_bundle_tag
echo "klusterlet-operator-bundle tag:"
cat .ashdod_output | grep "Image to mirror: klusterlet-operator-bundle:" | awk -F":" '{print $3}' | tee .klusterlet_operator_bundle_tag

# Mirror the openshift images we depend on
# Note: the oc image extract command is so dangerous that we ensure we are in a known-good location before attempting extraction
tempy=$(mktemp -d)
if [[ "$tempy" = "" ]]; then
  echo Not doing it, no way, no how
else
  ocwd=$(pwd)
  pushd . && cd $tempy && $OC image extract quay.io/acm-d/acm-operator-bundle:$(cat $ocwd/.acm_operator_bundle_tag) --file=extras/* && popd
  cat $tempy/$(ls $tempy/) | jq -rc '.[]' | while IFS='' read item;do
    remote=$(echo $item | jq -r '.["image-remote"]')
    if [[ "registry.redhat.io/openshift4" = "$remote" ]]
    then
      name=$(echo $item | jq -r '.["image-name"]')
      tag=$(echo $item | jq -r '.["image-tag"]')
      echo oc image mirror --keep-manifest-list=true --filter-by-os=. $remote/$name:$tag quay.io/acm-d/$name:$tag
      echo $($OC image mirror --keep-manifest-list=true --filter-by-os=. $remote/$name:$tag quay.io/acm-d/$name:$tag)
    fi
  done
  rm -rf $tempy
fi

# Find the prior bundles to include
echo Locating upgrade bundles...
docker login -u $PIPELINE_MANIFEST_REDHAT_USER -p $PIPELINE_MANIFEST_REDHAT_TOKEN registry.access.redhat.com
export REDHAT_REGISTRY_TOKEN=$(curl --silent -u "$PIPELINE_MANIFEST_REDHAT_USER":$PIPELINE_MANIFEST_REDHAT_TOKEN "https://sso.redhat.com/auth/realms/rhcc/protocol/redhat-docker-v2/auth?service=docker-registry&client_id=curl&scope=repository:rhel:pull" | jq -r '.access_token')
rm .extrabs-acm

# Prepare for battle
TEMPFILE=.extrabs-acm.json
TEMPFILE2=$TEMPFILE''2
echo "[]" > $TEMPFILE

BUNDLE=acm-operator-bundle
# Extract version list, Pull out timestamp
curl --silent --location -H "Authorization: Bearer $REDHAT_REGISTRY_TOKEN" https://registry.redhat.io/v2/rhacm2/$BUNDLE/tags/list | jq -r '.tags[] | select(test("'$PIPELINE_MANIFEST_BUNDLE_REGEX'"))' | xargs -L1 -I'{}' $BIN_PATH/_get_timestamp.sh $TEMPFILE $BUNDLE {}

# Sort results
jq '. | sort_by(.["timestamp"])' $TEMPFILE > $TEMPFILE2; mv $TEMPFILE2 $TEMPFILE

# Build the extrabs strucutre for acm-operator-bundle
jq -r '.[].version' $TEMPFILE | xargs -L1 -I'{}' echo  "-B registry.redhat.io/rhacm2/acm-operator-bundle:{}" > .extrabs-acm
export COMPUTED_UPGRADE_BUNDLES=$(cat .extrabs-acm)
echo Adding upgrade bundles:
echo $COMPUTED_UPGRADE_BUNDLES
# Build a catalog from acm-operator-bundle
cd release; echo tools/downstream-testing/build-catalog.sh $(cat ../.acm_operator_bundle_tag) $PIPELINE_MANFIEST_INDEX_IMAGE_TAG; tools/downstream-testing/build-catalog.sh $(cat ../.acm_operator_bundle_tag) $PIPELINE_MANFIEST_INDEX_IMAGE_TAG; cd ..

if [[ "$PIPELINE_MANIFEST_RELEASE_VERSION" == "2.0" || "$PIPELINE_MANIFEST_RELEASE_VERSION" == "2.1" ]]; then echo No klusterlet index expected in version $PIPELINE_MANIFEST_RELEASE_VERSION;
else
  echo klusterlet index expected in version $PIPELINE_MANIFEST_RELEASE_VERSION

  # Prepare for battle
  TEMPFILE=.extrabs-klusterlet.json
  TEMPFILE2=$TEMPFILE''2
  echo "[]" > $TEMPFILE

  BUNDLE=klusterlet-operator-bundle
  # Extract version list, Pull out timestamp
  curl --silent --location -H "Authorization: Bearer $REDHAT_REGISTRY_TOKEN" https://registry.redhat.io/v2/rhacm2/$BUNDLE/tags/list | jq -r '.tags[] | select(test("'$PIPELINE_MANIFEST_BUNDLE_REGEX'"))' | xargs -L1 -I'{}' build-harness-extensions/modules/pipeline-manifest/bin/_get_timestamp.sh $TEMPFILE $BUNDLE {}

  # Sort results
  jq '. | sort_by(.["timestamp"])' $TEMPFILE > $TEMPFILE2; mv $TEMPFILE2 $TEMPFILE

  # Build the extrabs strucutre for klusterlet-operator-bundle
  jq -r '.[].version' $TEMPFILE | xargs -L1 -I'{}' echo  "-B registry.redhat.io/rhacm2/klusterlet-operator-bundle:{}" > .extrabs-klusterlet
  export COMPUTED_UPGRADE_BUNDLES=$(cat .extrabs-klusterlet)
  echo Adding upgrade bundles:
  echo $COMPUTED_UPGRADE_BUNDLES

  # Build a catalog from klusterlet-operator-bundle
  cd release; echo tools/downstream-testing/build-catalog.sh $(cat ../.klusterlet_operator_bundle_tag) $PIPELINE_MANFIEST_INDEX_IMAGE_TAG quay.io/acm-d/klusterlet-custom-registry quay.io/acm-d/klusterlet-operator-bundle; tools/downstream-testing/build-catalog.sh $(cat ../.klusterlet_operator_bundle_tag) $PIPELINE_MANFIEST_INDEX_IMAGE_TAG quay.io/acm-d/klusterlet-custom-registry quay.io/acm-d/klusterlet-operator-bundle; cd ..
fi

# Try to make the droppings writable - useful for shared machines
chmod a+w -R /tmp/acm-custom-registry*
