#!/bin/sh

# Assumes: PIPELINE_MANIFEST_ORG is set to the GitHub org where repos live

# $1 - repo (pipeline vs. backplane-pipeline)
# $2 - existing branch x.y
# $3 - to-be branch x.y

TMPPLACE=newpipe-tmp

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then echo "I need three parameters: repo (pipeline or backplane-pipeline), old branch x.y number, new branch x.y number."; exit 1;
fi

if [ -d "$TMPPLACE" ]; then echo "The directory $TMPPLACE exists.  Remove it in order to continue."; exit 1;
fi

setup() {
  # $1 - pipeline/backplane-pipeline repo
  mkdir $TMPPLACE
  cd $TMPPLACE
  git clone git@github.com:$PIPELINE_MANIFEST_ORG/$1 $TMPPLACE
  cd $TMPPLACE
}

teardown() {
  cd ../..
}

operate() {
  # $1 - existing branch x.y
  # $2 - to-be branch x.y
  # $3 - branch suffix
  git checkout $1-$3
  git pull
  git checkout -b $2-$3
  rm snapshots/*
  touch snapshots/.gitkeep
  git commit -am "Clean out snapshots for new branch"
  git push --set-upstream origin $2-$3
}

setup $1
operate $2 $3 integration
operate $2 $3 edge
operate $2 $3 stable
teardown
