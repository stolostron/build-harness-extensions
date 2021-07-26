#!/bin/bash

# Incoming variables:
#   $1 - name of the manifest json file (should exist)
#   $2 - name of the sha'd manifest json file (to be created)
#   $3 - name of the instrumented manifest json file (to be created)
#   $4 - image-to-alias dictionary (image-alias.json, should exist)
#
# Required environment variables:
#   $QUAY_TOKEN - you know, the token... to quay (needs to be able to read open-cluster-management stuffs
#

if [[ -z "$QUAY_TOKEN" ]]
then
  echo "Please export QUAY_TOKEN"
  exit 1
fi

manifest_filename=$1
shad_filename=$2
instrumented_filename=$3
dictionary_filename=$4
pipeline_repo=$5

echo Current directory: $PWD
echo Incoming manfiest filename: $manifest_filename
echo Creating shad manfiest filename: $shad_filename
echo Creating instrumented manfiest filename: $instrumented_filename

rm manifest-sha.badjson 2> /dev/null
rm manifest-instrumented.badjson 2> /dev/null
cat $manifest_filename | jq -rc '.[]' | while IFS='' read item;do
  name=$(echo $item | jq -r '.["image-name"]')
  nameinstrumented=$(echo $item | jq -r '.["image-name"]')-coverage
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
  echo image name: [$name] instrumented name: [$nameinstrumented] remote: [$remote] repostory: [$repository] tag: [$tag] image_key: [$image_key]

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
  echo $item | jq --arg sha_value $sha_value --arg image_key $image_key '. + { "image-digest": $sha_value, "image-key": $image_key }' >> manifest-sha.badjson

  # Attempt to grab an instrumented version of the image
  url="https://quay.io/api/v1/repository/$repository/$nameinstrumented/tag/?onlyActiveTags=true&specificTag=$tag"
  # echo $url
  curl_command="curl -s -X GET -H \"Authorization: Bearer $QUAY_TOKEN\" \"$url\""
  instrumented_value=$(eval "$curl_command | jq -r .tags[0].manifest_digest")
  echo instrumented image sha: $instrumented_value
  if [[ "null" = "$instrumented_value" ]]
  then
    echo $item | jq --arg sha_value $sha_value --arg image_key $image_key '. + { "image-digest": $sha_value, "image-key": $image_key }' >> manifest-instrumented.badjson
  else
    echo $item | jq --arg image_name $nameinstrumented --arg instrumented_value $instrumented_value --arg image_key $image_key '. + { "image-name": $image_name, "image-digest": $instrumented_value, "image-key": $image_key }' >> manifest-instrumented.badjson
  fi
done
echo Creating $shad_filename file
jq -s '.' < manifest-sha.badjson > $shad_filename
rm manifest-sha.badjson 2> /dev/null

if [[ ! -z "$instrumented_filename" ]]; then
  echo Creating $instrumented_filename file
  jq -s '.' < manifest-instrumented.badjson > $instrumented_filename
  rm manifest-instrumented.badjson 2> /dev/null
fi
