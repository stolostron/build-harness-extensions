#!/bin/bash
set -e

# Execute all the mechanics of creating a custom catalog
#  1. Make sure we can talk to brew to extract the downstream build contents
#  2. Check out/refresh the ashdod and release projects, required for this process
#  3. Mirror the built images
#  3b. Mirror the openshift images
#  4. Query the production redhat docker registry to see what upgrade bundles we can add
#  5. Build our catalog and push it

# Take an arbitrary bundle and create an index image out of it
# Parameters:
#  $1: bundle name (i.e. acm-operator-bundle, cmb-operator-bundle, klusterlet-operator-bundle, etc.)
#  $2: bundle and index tag (i.e. 2.2.0-DOWNSTREAM-2021-01-14-06-28-39)
#  $3: index name (i.e. acm-custom-registry, cmb-custom-registry, klusterlet-custom-registry)
make_index () {
	BUNDLE=$1
	BUNDLE_TAG=$2
	INDEX=$3
	# Prepare for battle
	TEMPFILE=.extrabs.$1.json
	TEMPFILE2=.extrabs.$1-2.json
	echo "[]" > $TEMPFILE

 	echo Locating upgrade bundles for $BUNDLE...

	# Extract version list, Pull out timestamp
	curl --silent --location -H "Authorization: Bearer $REDHAT_REGISTRY_TOKEN" https://registry.redhat.io/v2/rhacm2/$BUNDLE/tags/list | jq -r '.tags[] | select(test("'$PIPELINE_MANIFEST_BUNDLE_REGEX'"))' | xargs -L1 -I'{}' $BIN_PATH/_get_timestamp.sh $TEMPFILE $BUNDLE {}

	# Sort results
	jq '. | sort_by(.["timestamp"])' $TEMPFILE > $TEMPFILE2; mv $TEMPFILE2 $TEMPFILE
	# Filter out vX.Y results; require vX.Y.Z
	jq '[.[] | select(.version | test("v\\d{1,2}\\.\\d{1,2}\\.\\d{1,2}"))]' $TEMPFILE > $TEMPFILE2; mv $TEMPFILE2 $TEMPFILE

	# Build the extrabs strucutre for this bundle
	jq -r '.[].version' $TEMPFILE | xargs -L1 -I'{}' echo  "-B registry.redhat.io/rhacm2/$BUNDLE:{}" > .extrabs-$BUNDLE
	export COMPUTED_UPGRADE_BUNDLES=$(cat .extrabs-$BUNDLE)
	echo Adding upgrade bundles:
	echo $COMPUTED_UPGRADE_BUNDLES
	# Build a catalog from bundle
	cd release; echo tools/custom-registry-gen/gen-custom-registry.sh \
   -B quay.io/acm-d/$BUNDLE:v1.0.0-2 \
   -r quay.io/acm-d -n $INDEX \
   -t $PIPELINE_MANFIEST_INDEX_IMAGE_TAG -P; cd ..
	cd release; tools/custom-registry-gen/gen-custom-registry.sh \
   -B quay.io/acm-d/$BUNDLE:v1.0.0-2 \
   -r quay.io/acm-d -n $INDEX \
   -t $PIPELINE_MANFIEST_INDEX_IMAGE_TAG -P; cd ..
	rm -rf /tmp/acm-custom-registry
	if [[ -z $PIPELINE_MANIFEST_MIRROR_BONUS_TAG ]]; then
		echo Didn\'t get a bonus tag
	else
		echo Got at a bonus tag: $PIPELINE_MANIFEST_MIRROR_BONUS_TAG
		echo docker tag quay.io/acm-d/$INDEX:$PIPELINE_MANFIEST_INDEX_IMAGE_TAG quay.io/acm-d/$INDEX:$PIPELINE_MANIFEST_MIRROR_BONUS_TAG
		#docker tag quay.io/acm-d/$INDEX:$PIPELINE_MANFIEST_INDEX_IMAGE_TAG quay.io/acm-d/$INDEX:$PIPELINE_MANIFEST_MIRROR_BONUS_TAG
		#docker push quay.io/acm-d/$INDEX:$PIPELINE_MANIFEST_MIRROR_BONUS_TAG
	fi
}

# Get logged into brew, update/check out the repos we need
echo Preparing environment for release $Z_RELEASE_VERSION tagged as $PIPELINE_MANFIEST_INDEX_IMAGE_TAG...
OC=$BUILD_HARNESS_PATH/vendor/oc
BIN_PATH=$BUILD_HARNESS_PATH/../build-harness-extensions/modules/pipeline-manifest/bin

rm -rf /tmp/acm-custom-registry
if [ -d release ];  \
    then cd release; git checkout backplane-$PIPELINE_MANIFEST_RELEASE_VERSION; git pull --quiet;cd ..; \
    else git clone -b backplane-$PIPELINE_MANIFEST_RELEASE_VERSION git@github.com:open-cluster-management/release.git release; \
fi
if [ -d backplane-pipeline ];  \
    then cd backplane-pipeline; git checkout $PIPELINE_MANIFEST_RELEASE_VERSION-integration; git pull --quiet;cd ..; \
    else git clone -b $PIPELINE_MANIFEST_RELEASE_VERSION-integration git@github.com:open-cluster-management/backplane-pipeline.git backplane-pipeline; \
fi
if [ -d deploy ];  \
    then cd deploy; git checkout master; git pull --quiet;cd ..; \
    else git clone -b master git@github.com:open-cluster-management/deploy.git deploy; \
fi

if [[ -z $SKIP_MIRROR ]]; then
  brew hello
  # Mirror the images we explicitly build in the errata; expect source-list.json to be written, gives us build sources
  echo Mirroring images with tag $PIPELINE_MANIFEST_MIRROR_TAG...
  python3 -u $BIN_PATH/_stealthy_mirror.py | tee .stealthy_output

  if [[ ! -s .stealthy_output ]]; then
    echo No output from mirroring\; aborting
    exit 1
  fi

  echo "backplane-operator-bundle tag:"
  cat .stealthy_output | grep "backplane-operator-bundle" | awk -F" " '{print $6}' | awk -F"," '{print $1}' | tee .backplane_operator_bundle_tag

else
  echo SKIP_MIRROR defined, skipping mirror
fi

if [[ -z $SKIP_INDEX ]]; then
  # Do the dance to get our proper quay access
  docker login -u $PIPELINE_MANIFEST_REDHAT_USER -p $PIPELINE_MANIFEST_REDHAT_TOKEN registry.access.redhat.com
  export REDHAT_REGISTRY_TOKEN=$(curl --silent -u "$PIPELINE_MANIFEST_REDHAT_USER":$PIPELINE_MANIFEST_REDHAT_TOKEN "https://sso.redhat.com/auth/realms/rhcc/protocol/redhat-docker-v2/auth?service=docker-registry&client_id=curl&scope=repository:rhel:pull" | jq -r '.access_token')

  # Call make_index with backplane
  make_index backplane-operator-bundle $(cat .backplane_operator_bundle_tag) backplane-custom-registry

  # Finally, send out the backplane custom registry to the downstream mirror mapping file
  amd_sha=$($OC image info quay.io/acm-d/backplane-custom-registry:$Z_RELEASE_VERSION-DOWNANDBACK-$DATESTAMP --filter-by-os=amd64 --output=json | jq -r '.digest')
  echo quay.io/acm-d/backplane-custom-registry@$amd_sha=__DESTINATION_ORG__/backplane-custom-registry:$Z_RELEASE_VERSION-DOWNANDBACK-$DATESTAMP >> mapping.txt

else
  echo SKIP_INDEX defined, skipping index makeage
fi
