#!/bin/bash
set -e

# Execute all the mechanics of creating a custom catalog
#  1. Make sure we can talk to brew to extract the downstream build contents
#  2. Check out/refresh the ashdod and release projects, required for this process
#  3. Mirror the built images
#  3b. Mirror the openshift images
#  4. Query the production redhat docker registry to see what upgrade bundles we can add
#  5. Build our catalog and push it
#  6. Push index image change to ACM's pipeline
#
# Main Parameters:
#  $1: GitHub organization name

# We send out the postgres sha to the downstream mapping file... this is the hardcoded version we are using today:
postgres_spec=registry.redhat.io/rhel8/postgresql-12@sha256:952ac9a625c7600449f0ab1970fae0a86c8a547f785e0f33bfae4365ece06336

# Take an arbitrary bundle and create an index image out of it
# make_index Parameters:
#  $1: bundle name (i.e. acm-operator-bundle, klusterlet-operator-bundle, etc.)
#  $2: bundle and index tag (i.e. 2.2.0-DOWNSTREAM-2021-01-14-06-28-39)
#  $3: index name (i.e. acm-custom-registry, klusterlet-custom-registry)
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
	cd release; echo tools/downstream-testing/build-catalog.sh $BUNDLE_TAG $PIPELINE_MANFIEST_INDEX_IMAGE_TAG quay.io/acm-d/$INDEX quay.io/acm-d/$BUNDLE; tools/downstream-testing/build-catalog.sh $BUNDLE_TAG $PIPELINE_MANFIEST_INDEX_IMAGE_TAG quay.io/acm-d/$INDEX quay.io/acm-d/$BUNDLE; cd ..
	rm -rf /tmp/acm-custom-registry
	if [[ -z $PIPELINE_MANIFEST_MIRROR_BONUS_TAG ]]; then
		echo Didn\'t get a bonus tag
	else
		echo Got at a bonus tag: $PIPELINE_MANIFEST_MIRROR_BONUS_TAG
		echo docker tag quay.io/acm-d/$INDEX:$PIPELINE_MANFIEST_INDEX_IMAGE_TAG quay.io/acm-d/$INDEX:$PIPELINE_MANIFEST_MIRROR_BONUS_TAG
		docker tag quay.io/acm-d/$INDEX:$PIPELINE_MANFIEST_INDEX_IMAGE_TAG quay.io/acm-d/$INDEX:$PIPELINE_MANIFEST_MIRROR_BONUS_TAG
		docker push quay.io/acm-d/$INDEX:$PIPELINE_MANIFEST_MIRROR_BONUS_TAG
	fi
}

# Get logged into brew, update/check out the repos we need
echo Preparing environment for release $Z_RELEASE_VERSION tagged as $PIPELINE_MANFIEST_INDEX_IMAGE_TAG...
OC=$BUILD_HARNESS_PATH/vendor/oc
BIN_PATH=$BUILD_HARNESS_PATH/../build-harness-extensions/modules/pipeline-manifest/bin
PIPELINE_MANIFEST_ORG=$1

rm -rf /tmp/acm-custom-registry
if [ -d ashdod ];  \
    then cd ashdod; git pull --quiet;cd ..; \
    else git clone --single-branch --branch master git@github.com:rh-deliverypipeline/ashdod.git ashdod; \
fi
echo Squaring up release repo...
if [ -d release ];  \
    then cd release; git checkout backplane-$PIPELINE_MANIFEST_RELEASE_VERSION; git pull --quiet;cd ..; \
    else git clone --single-branch --branch backplane-$PIPELINE_MANIFEST_RELEASE_VERSION git@github.com:$PIPELINE_MANIFEST_ORG/release.git release; \
fi
echo Squaring up backplane-pipeline repo...
if [ -d backplane-pipeline ];  \
    then cd backplane-pipeline; git checkout $PIPELINE_MANIFEST_RELEASE_VERSION-integration; git pull --quiet;cd ..; \
    else git clone --single-branch --branch $PIPELINE_MANIFEST_RELEASE_VERSION-integration git@github.com:$PIPELINE_MANIFEST_ORG/backplane-pipeline.git backplane-pipeline; \
fi
echo Squaring up deploy repo...
if [ -d deploy ];  \
    then cd deploy; git checkout master; git pull --quiet;cd ..; \
    else git clone --single-branch --branch master git@github.com:$PIPELINE_MANIFEST_ORG/deploy.git deploy; \
fi

if [[ -z $SKIP_MIRROR ]]; then
  brew hello
  # Mirror the images we explicitly build in the errata; expect source-list.json to be written, gives us build sources
  echo Mirroring main images from advisory $PIPELINE_MANIFEST_ADVISORY_ID...
  cd ashdod; python3 -u ashdod/main.py --advisory_id $PIPELINE_MANIFEST_ADVISORY_ID --org $PIPELINE_MANIFEST_MIRROR_ORG --namespace $PIPELINE_MANIFEST_MIRROR_NAMESPACE | tee ../.ashdod_output; cd ..
  if [[ ! -s .ashdod_output ]]; then
    echo No output from ashdod\; aborting
    exit 1
  fi

  # We expect ashdod to leave a mapping.txt file that contains all the images it knew to mirror
  cp ashdod/mapping.txt .

  echo "mce-operator-bundle tag:"
  cat .ashdod_output | grep "Image to mirror: mce-operator-bundle:" | awk -F":" '{print $3}' | tee .mce_operator_bundle_tag

  # Mirror the openshift images we depend on
  # Note: the oc image extract command is so dangerous that we ensure we are in a known-good-temporary location before attempting extraction
  tempy=$(mktemp -d)
  if [[ "$tempy" = "" ]]; then
    echo Not doing it, no way, no how
  else
    ocwd=$(pwd)
    pushd . && cd $tempy && $OC image extract quay.io/acm-d/mce-operator-bundle:$(cat $ocwd/.mce_operator_bundle_tag) --file=extras/* --filter-by-os=linux/amd64 && popd
    cp $tempy/$(ls $tempy/) mce-operator-bundle-manifest.json
    cat $tempy/$(ls $tempy/) | jq -rc '.[]' | while IFS='' read item;do
      remote=$(echo $item | jq -r '.["image-remote"]')
      if [[ "registry.redhat.io/openshift4" = "$remote" ]]
      then
        name=$(echo $item | jq -r '.["image-name"]')
        tag=$(echo $item | jq -r '.["image-tag"]')
        echo oc image mirror --keep-manifest-list=true --filter-by-os=.* $remote/$name:$tag quay.io/acm-d/$name:$tag
        $OC image mirror --keep-manifest-list=true --filter-by-os=.* $remote/$name:$tag quay.io/acm-d/$name:$tag
        amd_sha=$($OC image info quay.io/acm-d/$name:$tag --filter-by-os=linux/amd64 --output=json | jq -r '.listDigest')
        echo quay.io/acm-d/$name@$amd_sha=__DESTINATION_ORG__/$name:$tag >> mapping.txt
      fi
    done
    rm -rf $tempy
  fi
else
  echo SKIP_MIRROR defined, skipping mirror
fi

if [[ -z $SKIP_INDEX ]]; then
  # Do the dance to get our proper quay access
  docker login -u $PIPELINE_MANIFEST_REDHAT_USER -p $PIPELINE_MANIFEST_REDHAT_TOKEN registry.access.redhat.com
  export REDHAT_REGISTRY_TOKEN=$(curl --silent -u "$PIPELINE_MANIFEST_REDHAT_USER":$PIPELINE_MANIFEST_REDHAT_TOKEN "https://sso.redhat.com/auth/realms/rhcc/protocol/redhat-docker-v2/auth?service=docker-registry&client_id=curl&scope=repository:rhel:pull" | jq -r '.access_token')

  # Call make_index with mce
  make_index mce-operator-bundle $(cat .mce_operator_bundle_tag) mce-custom-registry

  # Take the subject backplane index and give it a "latest" tag relating to the overall backplane version number
  LATEST_TAG=`cat release/RELEASE_VERSION`-latest
  docker pull quay.io/acm-d/mce-custom-registry:$Z_RELEASE_VERSION-DOWNANDBACK-$DATESTAMP
  docker tag quay.io/acm-d/mce-custom-registry:$Z_RELEASE_VERSION-DOWNANDBACK-$DATESTAMP quay.io/acm-d/mce-custom-registry:$LATEST_TAG
  docker push quay.io/acm-d/mce-custom-registry:$LATEST_TAG
  docker rmi quay.io/acm-d/mce-custom-registry:$LATEST_TAG
  docker rmi quay.io/acm-d/mce-custom-registry:$Z_RELEASE_VERSION-DOWNANDBACK-$DATESTAMP

  # Finally, send out the mce custom registry to the downstream mirror mapping file
  mce_sha=$($OC image info quay.io/acm-d/mce-custom-registry:$Z_RELEASE_VERSION-DOWNANDBACK-$DATESTAMP --filter-by-os=amd64 --output=json | jq -r '.digest')
  echo quay.io/acm-d/mce-custom-registry@$mce_sha=__DESTINATION_ORG__/mce-custom-registry:$Z_RELEASE_VERSION-DOWNANDBACK-$DATESTAMP >> mapping.txt

  # Push the mapping file to the deploy repo
  cd deploy
  git pull
  cat ../mapping.txt | sort -u > mirror/$Z_RELEASE_VERSION-DOWNANDBACK-$DATESTAMP.txt
  cat ../mapping.txt | sort -u > mirror/`cat ../release/RELEASE_VERSION`-latest-DOWNANDBACK.txt
  git add mirror/$Z_RELEASE_VERSION-DOWNANDBACK-$DATESTAMP.txt
  git add mirror/`cat ../release/RELEASE_VERSION`-latest-DOWNANDBACK.txt
  git commit -am "Added Backplane $Z_RELEASE_VERSION downstream mirror mapping for $DATESTAMP" --quiet
  git push --quiet
  cd ..

else
  echo SKIP_INDEX defined, skipping index makeage
fi
