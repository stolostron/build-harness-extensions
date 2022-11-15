#!/bin/bash

curl \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/$UPSTREAM_OPERATOR_ORG/$UPSTREAM_COMMUNITY_REPO/pulls \
  -d '{"title":"operator $OPERATOR_TYPE ($OPERATOR_VERSION)","body":"Update $OPERATOR_TYPE to $OPERATOR_VERSION!","head":"$COMMUNITY_OPERATOR_ORG:$OPERATOR_TYPE-$OPERATOR_VERSION","base":"$COMMUNITY_OPERATOR_BRANCH"}'