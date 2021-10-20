#!/bin/sh
#make
#make jq/install > /dev/null

# Notes - set these in your environment or here:
#export GITHUB_TOKEN=your_token
#export PIPELINE_MANIFEST_LATEST_BRANCH=x.y-integration
#export PIPELINE_MANIFEST_LATEST_Z_RELEASE=x.y.z
#export MANIFEST_FILE=`make pipeline-manifest/_get_latest_manifest`
#export PIPELINE_REPO_BRANCH=$PIPELINE_MANIFEST_LATEST_BRANCH

NEW_BRANCH=release-x.y
OLD_BRANCH=
OLD_BRANCH1=master
OLD_BRANCH2=main

rm pipeline.json 2> /dev/null
$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3.raw" https://raw.githubusercontent.com/open-cluster-management/pipeline/$PIPELINE_REPO_BRANCH/snapshots/$MANIFEST_FILE --output pipeline.json)

cat pipeline.json | jq -rc '.[]' | while IFS='' read item;do
  #
  # For a component in the pipeline...
  #
  gitrepo=$(echo $item | jq -r '.["git-repository"]')
  name=`basename $gitrepo`
  repo=`dirname $gitrepo`
  echo git repo: [$repo] name: [$name]

  #
  # Grab the git commit sha of component's "master" branch
  #
  MASTER_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$gitrepo/git/refs/heads/$OLD_BRANCH1" | jq -r '.object.sha')
  if [ $MASTER_SHA == "null" ]; then
    MASTER_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$gitrepo/git/refs/heads/$OLD_BRANCH2" | jq -r '.object.sha')
    OLD_BRANCH=$OLD_BRANCH2
  else
    OLD_BRANCH=$OLD_BRANCH1
  fi

  #
  # Create a new branch if we have a master sha
  #
  if [ $MASTER_SHA == "null" ]; then
    echo "No master/main branch - ignoring"
  else
    if [ $repo == "open-cluster-management" ]; then
      #
      # Create the new branch off of master/main
      #
      echo Cutting new branch off of $name, branch $OLD_BRANCH at sha $MASTER_SHA
      output=`curl -s --show-error -X POST -H "Authorization: token $GITHUB_TOKEN" -d  "{\"ref\": \"refs/heads/$NEW_BRANCH\",\"sha\": \"$MASTER_SHA\"}" "https://api.github.com/repos/$gitrepo/git/refs"`
      #output='curl -s --show-error -X POST -H "Authorization: token $GITHUB_TOKEN" -d  "{\"ref\": \"refs/heads/$NEW_BRANCH\",\"sha\": \"$MASTER_SHA\"}" "https://api.github.com/repos/$gitrepo/git/refs"'
      echo $output
    else
      echo "Not in open-cluster-management - ignoring"
    fi
  fi
done
