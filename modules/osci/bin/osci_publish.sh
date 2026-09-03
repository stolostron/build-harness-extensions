#!/bin/bash

function git_cmd() {
	git -C "$OSCI_PIPELINE_DIR" "$@"
}

# Fail if the Z_RELEASE_VERSION fetch didn't work so the script doesn't continue with an empty/invalid value.
if [[ -z "$OSCI_Z_RELEASE_VERSION" || -z "$OSCI_Y_RELEASE_VERSION" ]]; then
	echo "Invalid OSCI_Z_RELEASE_VERSION='$OSCI_Z_RELEASE_VERSION' (OSCI_Y_RELEASE_VERSION='$OSCI_Y_RELEASE_VERSION')."
	echo "Failed to fetch a usable Z_RELEASE_VERSION from https://raw.githubusercontent.com/${OSCI_PIPELINE_ORG}/release/${OSCI_RELEASE_BRANCH}/Z_RELEASE_VERSION"
	exit 1
fi

echo "$OSCI_DATETIME" >DATETIME
echo ">>> Checking to see if OSCI_PUBLISH_DELAY is set..."
if ((OSCI_PUBLISH_DELAY > 0)); then
	echo "$(date): Waiting $OSCI_PUBLISH_DELAY minutes for post-submit image job to finish"
	sleep $((OSCI_PUBLISH_DELAY * 60))
	echo "$(date): Done waiting"
else
	echo "$(date): OSCI_PUBLISH_DELAY is 0 or not set"
fi
echo ">>> Updating manifest"
OSCI_RETRY=0
OSCI_RETRY_DELAY=8
while true; do
	echo ">>> Checking for an existing pipeline repo clone"
	if [[ -d "$OSCI_PIPELINE_DIR" ]]; then
		echo ">>> Removing existing pipeline repo clone"
		rm -rf "$OSCI_PIPELINE_DIR"
	fi
	echo ">>> Incoming: OSCI_PIPELINE_PRODUCT_PREFIX=$OSCI_PIPELINE_PRODUCT_PREFIX, OSCI_RELEASE_VERSION=$OSCI_RELEASE_VERSION"
	echo ">>> Cloning the pipeline repo from $OSCI_PIPELINE_SITE/$OSCI_PIPELINE_ORG/$OSCI_PIPELINE_REPO.git, branch $OSCI_PIPELINE_GIT_BRANCH"
	git clone -b "$OSCI_PIPELINE_GIT_BRANCH" "$OSCI_PIPELINE_GIT_URL" "$OSCI_PIPELINE_DIR" || {
		echo "Could not clone pipeline repo. Aborting"
		exit 1
	}
	echo ">>> Setting git user name and email"
	git_cmd config user.email "$OSCI_GIT_USER_EMAIL"
	git_cmd config user.name "$OSCI_GIT_USER_NAME"
	echo ">>> Checking if the component has an entry in the image alias file"
	if [[ -z "$(jq "$OSCI_MANIFEST_QUERY" "$OSCI_PIPELINE_DIR/$OSCI_IMAGE_ALIAS_FILENAME")" ]]; then
		echo "Component $OSCI_COMPONENT_NAME does not have an entry in $OSCI_PIPELINE_DIR/$OSCI_IMAGE_ALIAS_FILENAME"
		echo "Failing the build."
		exit 1
	else
		echo "Component $OSCI_COMPONENT_NAME has an entry in $OSCI_PIPELINE_DIR/$OSCI_IMAGE_ALIAS_FILENAME"
	fi
	echo ">>> Check if the component is already in the manifest file"
	if [[ -n "$(jq "$OSCI_MANIFEST_QUERY" "$OSCI_PIPELINE_DIR/$OSCI_MANIFEST_FILENAME")" ]]; then
		echo ">>> Deleting the component from the manifest file"
		jq "[$OSCI_DELETION_QUERY]" "$OSCI_PIPELINE_DIR/$OSCI_MANIFEST_FILENAME" >tmp
		mv tmp "$OSCI_PIPELINE_DIR/$OSCI_MANIFEST_FILENAME"
	fi
	echo ">>> Adding the component to the manifest file"
	if [[ -z "$OSCI_IMAGE_REMOTE_REPO_SRC" ]]; then
		jq "$OSCI_ADDITION_QUERY" "$OSCI_PIPELINE_DIR/$OSCI_MANIFEST_FILENAME" >tmp
	else
		jq "$OSCI_ADDITION_QUERY_REMOTE_SRC" "$OSCI_PIPELINE_DIR/$OSCI_MANIFEST_FILENAME" >tmp
	fi
	mv tmp "$OSCI_PIPELINE_DIR/$OSCI_MANIFEST_FILENAME"
	echo ">>> Sorting the manifest file"
	jq "$OSCI_SORT_QUERY" "$OSCI_PIPELINE_DIR/$OSCI_MANIFEST_FILENAME" >tmp
	mv tmp "$OSCI_PIPELINE_DIR/$OSCI_MANIFEST_FILENAME"
	echo ">>> Committing the manifest file update"
	git_cmd commit -am "Updated $OSCI_COMPONENT_NAME"
	echo ">>> Pushing pipeline repo"
	if git_cmd push; then
		echo ">>> Successfully pushed update to pipeline repo"
		break
	fi
	echo ">>> ERROR Failed to push update to pipeline repo"
	if ((OSCI_RETRY > 5)); then
		echo ">>> Too many retries updating manifest. Aborting"
		exit 1
	fi
	OSCI_RETRY=$((OSCI_RETRY + 1))
	echo ">>> Waiting $OSCI_RETRY_DELAY seconds to retry ($OSCI_RETRY)..."
	sleep $OSCI_RETRY_DELAY
	echo ">>> Retrying updating manifest."
	OSCI_RETRY_DELAY=$((OSCI_RETRY_DELAY * 2))
done
echo ">>> Backup manifest and image alias files"
cp "$OSCI_PIPELINE_DIR/$OSCI_MANIFEST_FILENAME" "$OSCI_MANIFEST_FILENAME"
cp "$OSCI_PIPELINE_DIR/$OSCI_IMAGE_ALIAS_FILENAME" "$OSCI_IMAGE_ALIAS_FILENAME"
echo ">>> Updating quay retag branch"
OSCI_RETRY=0
OSCI_RETRY_DELAY=8
while true; do
	echo ">>> Checking for an existing pipeline repo clone"
	if [[ -d "$OSCI_PIPELINE_DIR" ]]; then
		echo ">>> Removing existing pipeline repo clone"
		rm -rf "$OSCI_PIPELINE_DIR"
	fi
	echo ">>> Cloning the pipeline repo from $OSCI_PIPELINE_GIT_URL_PATH, branch $OSCI_PIPELINE_GIT_BRANCH"
	git clone -b "$OSCI_PIPELINE_GIT_BRANCH" "$OSCI_PIPELINE_GIT_URL" "$OSCI_PIPELINE_DIR" || {
		echo "Could not clone pipeline repo. Aborting"
		exit 1
	}
	echo ">>> Setting git user name and email"
	git_cmd config user.email "$OSCI_GIT_USER_EMAIL"
	git_cmd config user.name "$OSCI_GIT_USER_NAME"
	echo ">>> Switch to retag branch of pipeline repo"
	git_cmd checkout "$OSCI_PIPELINE_RETAG_BRANCH" || {
		echo "Could not checkout retag branch. Aborting"
		exit 1
	}
	echo ">>> Add additional data to retag branch"
	echo "$OSCI_DATETIME" >"$OSCI_PIPELINE_DIR/TAG"
	echo "$OSCI_PIPELINE_GIT_BRANCH" >"$OSCI_PIPELINE_DIR/ORIGIN_BRANCH"
	echo "$OSCI_Y_RELEASE_VERSION" >"$OSCI_PIPELINE_DIR/RELEASE_VERSION"
	echo "$OSCI_Z_RELEASE_VERSION" >"$OSCI_PIPELINE_DIR/Z_RELEASE_VERSION"
	echo "$OSCI_COMPONENT_NAME" >"$OSCI_PIPELINE_DIR/COMPONENT_NAME"
	echo ">>> Restore manifest and image alias files"
	cp "$OSCI_MANIFEST_FILENAME" "$OSCI_PIPELINE_DIR/$OSCI_MANIFEST_FILENAME"
	cp "$OSCI_IMAGE_ALIAS_FILENAME" "$OSCI_PIPELINE_DIR/$OSCI_IMAGE_ALIAS_FILENAME"
	echo ">>> Commit update to retag branch"
	git_cmd commit -am "Stage $OSCI_Z_RELEASE_VERSION snapshot of $OSCI_COMPONENT_NAME-$OSCI_COMPONENT_SUFFIX"
	echo ">>> Push retag branch update to pipeline repo"
	if git_cmd push; then
		echo "Successfully updated $OSCI_COMPONENT_NAME to $OSCI_COMPONENT_NAME:$OSCI_Z_RELEASE_VERSION in https://$OSCI_PIPELINE_SITE/$OSCI_PIPELINE_ORG/$OSCI_PIPELINE_REPO#$OSCI_Y_RELEASE_VERSION-$OSCI_PIPELINE_STAGE"
		break
	fi
	echo ">>> ERROR Failed to push retag branch update to pipeline repo"
	if ((OSCI_RETRY > 5)); then
		echo ">>> Too many retries updating retag branch. Aborting"
		exit 1
	fi
	OSCI_RETRY=$((OSCI_RETRY + 1))
	echo ">>> Waiting $OSCI_RETRY_DELAY seconds to retry ($OSCI_RETRY)..."
	sleep $OSCI_RETRY_DELAY
	echo ">>> Retrying push to retag branch."
	OSCI_RETRY_DELAY=$((OSCI_RETRY_DELAY * 2))
done
