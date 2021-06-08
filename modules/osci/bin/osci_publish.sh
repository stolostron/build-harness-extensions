#!/bin/bash

echo $OSCI_DATETIME > DATETIME
echo ">>> Wait for the publish delay if set"
if (( OSCI_PUBLISH_DELAY > 0 )); then
    echo "$(date): Waiting $OSCI_PUBLISH_DELAY minutes for post-submit image job to finish"
	sleep $(( OSCI_PUBLISH_DELAY * 60 ))
	echo "$(date): Done waiting"
fi
echo ">>> Updating manifest"
OSCI_RETRY=0
OSCI_RETRY_DELAY=8
while true; do
	echo ">>> Checking for an existing pipeline repo clone"
	if [[ -d $OSCI_MANIFEST_DIR ]]; then
		echo ">>> Removing existing pipeline repo clone"
		rm -rf $OSCI_MANIFEST_DIR
	fi
	echo ">>> Cloning the pipeline repo"
	git clone -b $OSCI_PIPELINE_GIT_BRANCH $OSCI_PIPELINE_GIT_URL $OSCI_MANIFEST_DIR
	echo ">>> Setting git user name and email"
	pushd $OSCI_MANIFEST_DIR > /dev/null
	git config user.email $OSCI_GIT_USER_EMAIL
	git config user.name $OSCI_GIT_USER_NAME
	popd > /dev/null
	echo ">>> Checking if the component has an entry in the image alias file"
	if [[ -z $(jq "$OSCI_MANIFEST_QUERY" $OSCI_MANIFEST_DIR/$OSCI_IMAGE_ALIAS_FILENAME) ]]; then
		echo "Component $OSCI_COMPONENT_NAME does not have an entry in $OSCI_MANIFEST_DIR/$OSCI_IMAGE_ALIAS_FILENAME"
		echo "Failing the build."
		exit 1
	else
		echo "Component $OSCI_COMPONENT_NAME has an entry in $OSCI_MANIFEST_DIR/$OSCI_IMAGE_ALIAS_FILENAME"
	fi
	echo ">>> Check if the component is already in the manifest file"
    if [[ -n $(jq "$OSCI_MANIFEST_QUERY" $OSCI_MANIFEST_DIR/$OSCI_MANIFEST_FILENAME) ]]; then
		echo ">>> Deleting the component from the manifest file"
		jq "[$OSCI_DELETION_QUERY]" $OSCI_MANIFEST_DIR/$OSCI_MANIFEST_FILENAME > tmp
		mv tmp $OSCI_MANIFEST_DIR/$OSCI_MANIFEST_FILENAME
	fi
	echo ">>> Adding the component to the manifest file"
	jq "$OSCI_ADDITION_QUERY" $OSCI_MANIFEST_DIR/$OSCI_MANIFEST_FILENAME > tmp
	mv tmp $OSCI_MANIFEST_DIR/$OSCI_MANIFEST_FILENAME
	echo ">>> Sorting the manifest file"
	jq "$OSCI_SORT_QUERY" $OSCI_MANIFEST_DIR/$OSCI_MANIFEST_FILENAME > tmp
	mv tmp $OSCI_MANIFEST_DIR/$OSCI_MANIFEST_FILENAME
	echo ">>> Committing the manifest file update"
	pushd $OSCI_MANIFEST_DIR > /dev/null
	git commit -am "Updated $OSCI_COMPONENT_NAME"
	echo ">>> Pushing pipeline repo"
	if git push ; then
		echo ">>> Successfully pushed update to pipeline repo"
		popd > /dev/null
		break
	fi
	popd > /dev/null
	echo ">>> ERROR Failed to push update to pipeline repo"
	if (( OSCI_RETRY > 5 )); then
		echo ">>> Too many retries updating manifest. Aborting"
		exit 1
	fi
	OSCI_RETRY=$(( OSCI_RETRY + 1 ))
	echo ">>> Waiting $OSCI_RETRY_DELAY seconds to retry ($OSCI_RETRY)..."
	sleep $OSCI_RETRY_DELAY
	echo ">>> Retrying updating manifest."
	OSCI_RETRY_DELAY=$(( OSCI_RETRY_DELAY * 2 ))
done
echo ">>> Backup manifest and image alias files"
cp $OSCI_MANIFEST_DIR/$OSCI_MANIFEST_FILENAME $OSCI_MANIFEST_FILENAME
cp $OSCI_MANIFEST_DIR/$OSCI_IMAGE_ALIAS_FILENAME $OSCI_IMAGE_ALIAS_FILENAME
echo ">>> Switch to retag branch of pipeline repo"
pushd $OSCI_MANIFEST_DIR > /dev/null
git checkout $OSCI_PIPELINE_RETAG_BRANCH
popd > /dev/null
echo ">>> Add additional data to retag branch"
echo $OSCI_DATETIME > $OSCI_MANIFEST_DIR/TAG
echo $OSCI_PIPELINE_GIT_BRANCH > $OSCI_MANIFEST_DIR/ORIGIN_BRANCH
echo $OSCI_RELEASE_VERSION > $OSCI_MANIFEST_DIR/RELEASE_VERSION
echo $OSCI_Z_RELEASE_VERSION > $OSCI_MANIFEST_DIR/Z_RELEASE_VERSION
echo $OSCI_COMPONENT_NAME > $OSCI_MANIFEST_DIR/COMPONENT_NAME
echo ">>> Restore manifest and image alias files"
cp $OSCI_MANIFEST_FILENAME $OSCI_MANIFEST_DIR/$OSCI_MANIFEST_FILENAME
cp $OSCI_IMAGE_ALIAS_FILENAME $OSCI_MANIFEST_DIR/$OSCI_IMAGE_ALIAS_FILENAME
echo ">>> Commit update to retag branch"
pushd $OSCI_MANIFEST_DIR > /dev/null
git commit -am "Stage $OSCI_Z_RELEASE_VERSION snapshot of $OSCI_COMPONENT_NAME-$OSCI_COMPONENT_SUFFIX"
echo ">>> Push retag branch update to pipeline repo"
git push
popd > /dev/null
echo "Successfully updated $OSCI_COMPONENT_NAME to $OSCI_COMPONENT_NAME:$OSCI_COMPONENT_VERSION in https://$OSCI_PIPELINE_SITE/$OSCI_PIPELINE_ORG/$OSCI_PIPELINE_REPO#$OSCI_RELEASE_VERSION-$OSCI_PIPELINE_STAGE"
