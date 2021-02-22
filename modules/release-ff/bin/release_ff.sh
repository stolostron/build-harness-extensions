#!/bin/bash

set -e

RELEASE_FF_BRANCH=$1
RELEASE_MAIN_BRANCH=$2
if [[ -z "$RELEASE_MAIN_BRANCH" ]]
then
  RELEASE_MAIN_BRANCH=master
fi

if [[ -z "$RELEASE_FF_BRANCH" ]]
then
  echo "RELEASE_FF_BRANCH not set. Skipping fast-forward of release branch."
  exit 0
fi

rm -rf repo-copy
REPO_URL=$(git remote get-url origin)
if [[ -n "$GITHUB_USER" && -n "$GITHUB_TOKEN" ]]
then
  echo "Using GITHUB_USER and GITHUB_TOKEN for authentication"
  REPO_URL=${REPO_URL/https:\/\//https:\/\/${GITHUB_USER}\:${GITHUB_TOKEN}@}
fi
git clone -b ${RELEASE_MAIN_BRANCH} ${REPO_URL} repo-copy
cd repo-copy
if ! git checkout -b ${RELEASE_FF_BRANCH} origin/${RELEASE_FF_BRANCH}
then
  echo "Release branch does not exist. Creating new branch."
  git checkout -b ${RELEASE_FF_BRANCH}
  git push origin ${RELEASE_FF_BRANCH}
else
  git merge --ff-only ${RELEASE_MAIN_BRANCH}
  git push
fi
