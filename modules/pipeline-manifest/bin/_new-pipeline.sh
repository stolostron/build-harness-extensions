#!/bin/sh

set -e

# $1 - repo (pipeline vs. backplane-pipeline)
# $2 - existing branch x.y
# $3 - to-be branch x.y

TMPPLACE=newpipe-tmp
GIT_DIR=$TMPPLACE/pipeline
GIT="git -C $GIT_DIR"

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "I need three parameters: repo (pipeline or backplane-pipeline), old branch x.y number, new branch x.y number."
  exit 1
fi

if [ -d "$TMPPLACE" ]; then
  echo "The directory $TMPPLACE exists.  Remove it in order to continue."
  exit 1
fi

setup() {
  # $1 - pipeline/backplane-pipeline repo
  mkdir $TMPPLACE
  git clone "https://github.com/stolostron/$1" "$GIT_DIR"
  $GIT fetch --all
}

operate() {
  # $1 - existing branch x.y
  # $2 - to-be branch x.y
  # $3 - branch suffix
  $GIT checkout "$1-$3"
  $GIT checkout --orphan "$2-$3"
  rm $GIT_DIR/snapshots/.gitkeep || true
  if [ -d "$GIT_DIR/snapshots" ] && [ -z "$(find $GIT_DIR/snapshots -maxdepth 0 -empty)" ]; then
    rm $GIT_DIR/snapshots/*
  fi
  touch $GIT_DIR/snapshots/.gitkeep
  $GIT add .
  $GIT commit -am "Initial commit for $2-$3"
  $GIT push --set-upstream origin "$2-$3"
}

setup "$1"
operate "$2" "$3" integration
operate "$2" "$3" dev
operate "$2" "$3" nightly
operate "$2" "$3" preview
if [ "$1" = "pipeline" ]; then
  operate "$2" "$3" stable
fi
