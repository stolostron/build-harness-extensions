#!/bin/sh
#
# Do sha leveling in case there are multiple builds coming from a single repo
#
# Search for components that come from the same repo and update them all with the latest sha
# coming in from the supplied component name, replacing the manifest in the process

component=$1
manifest_filename=$2

affected_repo=`jq -r --arg component $component '.[] | select( ."image-name" == $component)."git-repository"' $manifest_filename`
new_sha=`jq -r --arg component $component '.[] | select( ."image-name" == $component)."git-sha256"' $manifest_filename`
jq --arg match $affected_repo --arg replace $new_sha 'map(if ."git-repository" == $match then ( ."git-sha256" = $replace ) else . end)' $manifest_filename > manifest-modified.json
echo "Diff from sha leveling follows (may be blank):"
diff -U 3 $manifest_filename manifest-modified.json
echo Diff from sha leveling complete.
mv manifest-modified.json $manifest_filename
