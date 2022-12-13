#!/bin/bash

if [[ -z "$GITHUB_TOKEN" ]]
then
  echo "Please export GITHUB_TOKEN"
  exit 1
fi

op_type=$1
op_ver=$2
up_org=$3
up_repo=$4
com_org=$5
com_branch=$6

TITLE="operator $op_type ($op_ver)"
BODY="Update $op_type to $op_ver!"
HEAD="$com_org:$op_type-$op_ver"
BASE="$com_branch"

echo "Creating a PR titled '$TITLE', with the message $BODY, from $HEAD to the $BASE branch of $up_org/$up_repo"

curl \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/$up_org/$up_repo/pulls \
  -d '{"title":"'"$TITLE"'","body":"'"$BODY"'","head":"'"$HEAD"'","base":"'"$BASE"'"}'