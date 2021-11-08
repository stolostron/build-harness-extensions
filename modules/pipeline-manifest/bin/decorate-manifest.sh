#!/bin/bash

# Incoming variables:
#   $1 - name of the manifest json file (should exist)
#   $2 - name of the sha'd manifest json file (to be created)
#   $3 - image-to-alias dictionary (image-alias.json, should exist)
#   $4 - name of the GitHub pipeline repo (pipeline vs. backplane-pipeline)
#   $5 - Quay org/repo name of "home" registry - "visitor" images will be mirrored here ($PIPELINE_MANIFEST_REMOTE_REPO)
#   $6 - Tag (datestamp) to add to mirrored "away" images
#
# Required environment variables:
#   $QUAY_TOKEN - you know, the token... to quay (needs to be able to read quay org stuffs
#

if [[ -z "$QUAY_TOKEN" ]]
then
  echo "Please export QUAY_TOKEN"
  exit 1
fi

manifest_filename=$1
shad_filename=$2
dictionary_filename=$3
pipeline_repo=$4
home_quay_org=$5
home_tag=$6

OC=$BUILD_HARNESS_PATH/vendor/oc

echo Pipeline repo: $pipeline_repo Current directory: $PWD
echo Home Quay org: $home_quay_org
echo Incoming manfiest filename: $manifest_filename
echo Creating shad manfiest filename: $shad_filename

rm manifest-sha.badjson 2> /dev/null
cat $manifest_filename | jq -rc '.[]' | while IFS='' read item; do
  name=$(echo $item | jq -r '.["image-name"]')
  remote=$(echo $item | jq -r '.["image-remote"]')
  repository=$(echo $item | jq -r '.["image-remote"]' | awk -F"/" '{ print $2 }')
  tag=$(echo $item | jq -r '.["image-tag"]')
  image_key=$(jq -r --arg image_name $name '.[] | select (.["image-name"]==$image_name) | .["image-key"]' $dictionary_filename )
  if [[ "" = "$image_key" ]]
  then
    echo Oh no, can\'t retrieve image key for $name
    msg="$pipeline_repo/quay_retag (decorate-manifest.sh): :red_circle: Failure in <$TRAVIS_BUILD_WEB_URL|retag> commit: \`$TRAVIS_COMMIT_MESSAGE\`: cannot retrieve image key for $name in $dictionary_filename"
    make simple-slack/send SLACK_MESSAGE="$msg"
    exit 1
  fi
  if [[ "$home_quay_org" = "$remote" ]]; then
    echo "**** Home ****"
  else
    echo "**** Away, mirroring to Home ****"
    # We want to "update" the floating tag as well as create a unique tag so we don't lose a sha
    $OC image mirror $remote/$name:$tag $home_quay_org/$name:$tag $home_quay_org/$name:$tag-$home_tag --keep-manifest-list=true --filter-by-os=.*
  fi
  echo image name: [$name] remote: [$remote] repostory: [$repository] tag: [$tag] image_key: [$image_key]

  # Attempt to grab the sha of the image
  url="https://quay.io/api/v1/repository/$repository/$name/tag/?onlyActiveTags=true&specificTag=$tag"
  # echo $url
  curl_command="curl -s -X GET -H \"Authorization: Bearer $QUAY_TOKEN\" \"$url\""
  #echo $curl_command
  sha_value=$(eval "$curl_command | jq -r .tags[0].manifest_digest")
  echo sha_value: $sha_value
  if [[ "null" = "$sha_value" ]]
  then
    echo Oh no, can\'t retrieve sha from $url
    msg="$pipeline_repo/quay_retag (decorate-manifest.sh): :red_circle: Failure in <$TRAVIS_BUILD_WEB_URL|retag> commit: \`$TRAVIS_COMMIT_MESSAGE\`: cannot retrieve sha from $url"
    make simple-slack/send SLACK_MESSAGE="$msg"
    exit 1
  fi
  echo $item | jq --arg sha_value $sha_value --arg image_key $image_key --arg home_quay_org $home_quay_org '. + { "image-digest": $sha_value, "image-key": $image_key, "image-remote": $home_quay_org }' >> manifest-sha.badjson
done

echo Creating $shad_filename file
jq -s '.' < manifest-sha.badjson > $shad_filename
rm manifest-sha.badjson 2> /dev/null
