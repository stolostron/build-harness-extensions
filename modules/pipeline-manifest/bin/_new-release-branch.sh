#!/bin/sh

# $1 - repo (pipeline vs. backplane-pipeline)
# $2 - existing branch x.y
# $3 - to-be branch x.y

TMPPLACE=newrelease-tmp

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then echo "I need three parameters: pipeline (release or backplane), new branch x.y number, community x.y number, optional backplane x.y number" ; exit 1;
fi

if [ -d "$TMPPLACE" ]; then echo "The directory $TMPPLACE exists.  Remove it in order to continue."; exit 1;
fi

setup() {
  # $1 - pipeline/backplane-pipeline repo
  mkdir $TMPPLACE
  cd $TMPPLACE
  git clone git@github.com:stolostron/release $TMPPLACE
  cd $TMPPLACE
}

teardown() {
  cd ../..
}

community_creation() {
    # $1 - pipeline
    # $2 - pipeline x.y
    # $3 - community x.y 
    # $4 - community branch name
    # $5 - communtiy tag name
    git checkout main
    git pull
    git checkout -b $4-$3
    touch TAG
    touch RELEASE_VERSION
    cat $3 > RELEASE_VERSION
    touch Z_RELEASE_VERSION
    cat $3.0 > Z_RELEASE_VERSION
    if [ "$1" = "release" ];
        touch ACM_Z_RELEASE_VERSION
        cat $2.0 > ACM_Z_RELEASE_VERSION
        touch STOLOSTRON_ENGINE_RELEASE_VERSION
        cat $3 > STOLOSTRON_ENGINE_RELEASE_VERSION
    elif [ "$1" = "backplane" ];
        touch BACKPLANE_Z_RELEASE_VERSION
        cat $2.0 > BACKPLANE_Z_RELEASE_VERSION
    fi
    git commit -am "Inital cutover for new branch"
    git push --set-upstream origin $4-$3
}

operate() {
  # $1 - pipeline-prefix
  # $2 - to-be branch x.y
  # $3 - communtiy branch x.y
  # $4 - community name
  # $5 - optional backplane version
  git pull
  git checkout -b $1-$2
  touch TAG
  touch RELEASE_VERSION
  cat $2 > RELEASE_VERSION
  touch Z_RELEASE_VERSION
  cat $2.0 > Z_RELEASE_VERSION
  touch ${4}_RELEASE_VERSION
  cat $3 > ${4}_RELEASE_VERSION
  if [ ! -z $5 ]; then
    touch BACKPLANE_RELEASE_FILE
    cat $5 > BACKPLANE_RELEASE_FILE
  git commit -am "Inital cutover for new branch"
  git push --set-upstream origin $1-$2
}

setup
if [ "$1" = "backplane" ]; then
    operate $1 $2 $3 STOLOSTRON_ENGINE
    community_creation $1 $2 $4 stolostron-engine
  # branch creation
  # stolostron-engine setup
elif [ "$1" = "release" ]; then
    operate $1 $2 $3 STOLOSTRON $4
    community_creation $1 $2 $4 stolostron
  # branch creation
  # add backplane files
  # stolostron setup
fi
teardown
