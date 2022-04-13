#!/bin/bash
set -e

# Execute all the mechanics of creating a custom catalog
#  1. Make sure we can talk to brew to extract the downstream build contents
#  2. Check out/refresh the ashdod and release projects, required for this process
#  3. Mirror the built images
#  3b. Mirror the openshift images
#  4. Query the production redhat docker registry to see what upgrade bundles we can add
#  5. Build our catalog and push it
#
# Main Parameters:
#  $1: GitHub organization name

# We send out the postgres sha to the downstream mapping file... this is the hardcoded version we are using today:
postgres_spec=registry.redhat.io/rhel8/postgresql-12@sha256:da0b8d525b173ef472ff4c71fae60b396f518860d6313c4f3287b844aab6d622

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
	# Filter out v2.3.6 version, released prematurely
	# jq '[.[] | select(.version | contains("v2.3.6") | not)]' $TEMPFILE > $TEMPFILE2; mv $TEMPFILE2 $TEMPFILE
	# Build the extrabs strucutre for this bundle
	jq -r '.[].version' $TEMPFILE | xargs -L1 -I'{}' echo  "-B registry.redhat.io/rhacm2/$BUNDLE:{}" > .extrabs-$BUNDLE
	export COMPUTED_UPGRADE_BUNDLES=$(cat .extrabs-$BUNDLE)
	echo Adding upgrade bundles:
	echo $COMPUTED_UPGRADE_BUNDLES
	# Build a catalog from bundle
	cd release
	echo tools/downstream-testing/build-catalog.sh $BUNDLE_TAG $PIPELINE_MANFIEST_INDEX_IMAGE_TAG quay.io/acm-d/$INDEX quay.io/acm-d/$BUNDLE
	tools/downstream-testing/build-catalog.sh $BUNDLE_TAG $PIPELINE_MANFIEST_INDEX_IMAGE_TAG quay.io/acm-d/$INDEX quay.io/acm-d/$BUNDLE || { cd .. && echo I BROKE && return 1; }
	cd ..
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

setup () {
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

if [ -d release ];  \
    then { echo Grooming release repo; cd release; git checkout release-$PIPELINE_MANIFEST_RELEASE_VERSION && git pull --quiet && cd ..; } || { cd .. && return 1; } \
    else echo Cloning release repo; git clone git@github.com:$PIPELINE_MANIFEST_ORG/release.git release; cd release; git checkout release-$PIPELINE_MANIFEST_RELEASE_VERSION; cd ..; \
fi

if [ -d pipeline ];  \
    then { echo Grooming pipeline repo && cd pipeline && git checkout $PIPELINE_MANIFEST_RELEASE_VERSION-integration && git pull --quiet && cd ..; } || { cd .. && return 1; } \
    else echo Cloning pipeline repo; git clone git@github.com:$PIPELINE_MANIFEST_ORG/pipeline.git pipeline; cd pipeline; git checkout $PIPELINE_MANIFEST_RELEASE_VERSION-integration; cd ..; \
fi

if [ -d deploy ];  \
    then { echo Grooming deploy repo && cd deploy && git checkout master && git pull --quiet && cd ..; } || { cd .. && return 1; } \
    else echo Cloning deploy repo; git clone git@github.com:$PIPELINE_MANIFEST_ORG/deploy.git deploy; cd deploy; git checkout master; cd ..; \
fi
}

mirror () {
if [[ -z $SKIP_MIRROR ]]; then
  brew hello || return 1
  # Mirror the images we explicitly build in the errata; expect source-list.json to be written, gives us build sources
  echo Mirroring main images from advisory $PIPELINE_MANIFEST_ADVISORY_ID...
  cd ashdod; python3 -u ashdod/main.py --advisory_id $PIPELINE_MANIFEST_ADVISORY_ID --org $PIPELINE_MANIFEST_MIRROR_ORG | tee ../.ashdod_output && cd .. || { cd .. && return 1;}
  if [[ ! -s .ashdod_output ]]; then
    echo No output from ashdod\; aborting
    return 1
  fi

  # We expect ashdod to leave a mapping.txt file that contains all the images it knew to mirror
  cp ashdod/mapping.txt .

  echo "acm-operator-bundle tag:"
  cat .ashdod_output | grep "Image to mirror: acm-operator-bundle:" | awk -F":" '{print $3}' | tee .acm_operator_bundle_tag

  # Mirror the openshift images we depend on
  # Note: the oc image extract command is so dangerous that we ensure we are in a known-good-temporary location before attempting extraction
  tempy=$(mktemp -d)
  if [[ "$tempy" = "" ]]; then
    echo Not doing it, no way, no how
  else
    ocwd=$(pwd)
    pushd . && cd $tempy && $OC image extract quay.io/acm-d/acm-operator-bundle:$(cat $ocwd/.acm_operator_bundle_tag) --file=extras/* --filter-by-os=linux/amd64 && popd
    cp $tempy/$(ls $tempy/) acm-operator-bundle-manifest.json
    cat $tempy/$(ls $tempy/) | jq -rc '.[]' | while IFS='' read item;do
      remote=$(echo $item | jq -r '.["image-remote"]')
      if [[ "registry.redhat.io/openshift4" = "$remote" ]]
      then
        name=$(echo $item | jq -r '.["image-name"]')
        tag=$(echo $item | jq -r '.["image-tag"]')
        echo oc image mirror --keep-manifest-list=true --filter-by-os=.* $remote/$name:$tag quay.io/acm-d/$name:$tag
        $OC image mirror --keep-manifest-list=true --filter-by-os=.* $remote/$name:$tag quay.io/acm-d/$name:$tag || return 1
        amd_sha=$($OC image info quay.io/acm-d/$name:$tag --filter-by-os=linux/amd64 --output=json | jq -r '.listDigest')
        echo quay.io/acm-d/$name@$amd_sha=__DESTINATION_ORG__/$name:$tag >> mapping.txt
      fi
    done
    rm -rf $tempy
  fi
else
  echo SKIP_MIRROR defined, skipping mirror
fi
}

index () {
if [[ -z $SKIP_INDEX ]]; then
  # Do the dance to get our proper quay access
  docker login -u $PIPELINE_MANIFEST_REDHAT_USER -p $PIPELINE_MANIFEST_REDHAT_TOKEN registry.access.redhat.com || return 1
  export REDHAT_REGISTRY_TOKEN=$(curl --silent -u "$PIPELINE_MANIFEST_REDHAT_USER":$PIPELINE_MANIFEST_REDHAT_TOKEN "https://sso.redhat.com/auth/realms/rhcc/protocol/redhat-docker-v2/auth?service=docker-registry&client_id=curl&scope=repository:rhel:pull" | jq -r '.access_token')

  # Call make_index with klusterlet, but it only came into being in 2.2
  if [[ "$PIPELINE_MANIFEST_RELEASE_VERSION" == "2.0" || "$PIPELINE_MANIFEST_RELEASE_VERSION" == "2.1" ]]; then echo No klusterlet index expected in version $PIPELINE_MANIFEST_RELEASE_VERSION;
  else
    echo Skipping klusterlet processing for the time being
    #echo klusterlet index expected in version $PIPELINE_MANIFEST_RELEASE_VERSION
    #make_index klusterlet-operator-bundle $(cat .klusterlet_operator_bundle_tag) klusterlet-custom-registry
  fi

  # Call make_index with acm
  make_index acm-operator-bundle $(cat .acm_operator_bundle_tag) acm-custom-registry || return 1

  # Add postgres to the downstream mirror mapping file
  echo $postgres_spec=__DESTINATION_ORG__/postgresql-12:$Z_RELEASE_VERSION-DOWNSTREAM-$DATESTAMP >> mapping.txt

  # Send out the acm custom registry to the downstream mirror mapping file
  amd_sha=$($OC image info quay.io/acm-d/acm-custom-registry:$Z_RELEASE_VERSION-DOWNSTREAM-$DATESTAMP --filter-by-os=amd64 --output=json | jq -r '.digest')
  echo quay.io/acm-d/acm-custom-registry@$amd_sha=__DESTINATION_ORG__/acm-custom-registry:$Z_RELEASE_VERSION-DOWNSTREAM-$DATESTAMP >> mapping.txt

  # Pull in the version of MCE that matches ACM
  if [[ "$PIPELINE_MANIFEST_RELEASE_VERSION" == "2.5" ]]; then
    MCE_VERSION=`cat release/BACKPLANE_RELEASE_VERSION`
  fi
  if [[ ! -z "$MCE_VERSION" ]]; then
    echo MCE version is set to $MCE_VERSION ... seeking deploy/mirror/$MCE_VERSION-latest-DOWNANDBACK.txt to combine
    # Combine the "latest" backplane downstream mirror mapping file, but retag the mce-custom-registry with the ACM snapshot tag
    echo `cat deploy/mirror/$MCE_VERSION-latest-DOWNANDBACK.txt | grep mce-custom-registry | awk -F: '{ print $3 }'` > mce-snapshot.txt
    eval 'sed -e "s|mce-custom-registry:.*|mce-custom-registry:'$PIPELINE_MANFIEST_INDEX_IMAGE_TAG'|g;" deploy/mirror/'$MCE_VERSION'-latest-DOWNANDBACK.txt >> mapping.txt'
    echo Retagging the \"latest\" MCE index $MCE_VERSION to go with this ACM index
    LATEST_TAG=$MCE_VERSION-latest
    docker pull quay.io/acm-d/mce-custom-registry:$LATEST_TAG
    docker tag quay.io/acm-d/mce-custom-registry:$LATEST_TAG quay.io/acm-d/mce-custom-registry:$PIPELINE_MANFIEST_INDEX_IMAGE_TAG
    docker push quay.io/acm-d/mce-custom-registry:$PIPELINE_MANFIEST_INDEX_IMAGE_TAG
    docker rmi quay.io/acm-d/mce-custom-registry:$PIPELINE_MANFIEST_INDEX_IMAGE_TAG
    docker rmi quay.io/acm-d/mce-custom-registry:$LATEST_TAG
  else
    echo MCE version is unset, not combining backplane downstream mapping
  fi

  # Create the downstream-upstream connected manifest and mirror mapping
  echo Create the downstream-upstream connected manifest and mirror mapping
  retry python3 -u $BIN_PATH/_generate_downstream_manifest.py

  # Push it to the pipeline and deploy repos
  cp downstream-$DATESTAMP-$Z_RELEASE_VERSION.json pipeline/snapshots
  cat mapping.txt | sort -u > deploy/mirror/$Z_RELEASE_VERSION-DOWNSTREAM-$DATESTAMP.txt
  echo working on pipeline
  cd pipeline
  git pull
  git add snapshots/downstream-$DATESTAMP-$Z_RELEASE_VERSION.json
  git commit -am "Added $Z_RELEASE_VERSION downstream manifest of $DATESTAMP" --quiet
  git push --quiet
  echo working on deploy
  cd ../deploy
  git pull
  git add mirror/$Z_RELEASE_VERSION-DOWNSTREAM-$DATESTAMP.txt
  git commit -am "Added $Z_RELEASE_VERSION downstream mirror mapping for $DATESTAMP" --quiet
  git push --quiet
else
  echo SKIP_INDEX defined, skipping index makeage
fi
}

function fail {
  echo fail exiting with $1...
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=5
  local delay=5
  while true; do
    echo Working $@ retry n=$n "$*" \""$@"\"
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "retry failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "Retry of $@ failed after $n attempts."
      fi
    }
  done
}

retry setup $*
retry mirror
retry index
