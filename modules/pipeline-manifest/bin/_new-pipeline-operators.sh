#!/bin/sh -e

# $1 - operator repo (repo that needs the new branch)
# $2 - existing up-to-date branch to copy from
# $3 - branch prefix (release vs. backplane)
# $4 - to-be branch #3-x.y

TMPPLACE=newpipe-tmp

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then 
echo "I need four parameters: "
printf "\n"
echo "1 - operator repo (repo that needs the new branch)"
echo "2 - existing up-to-date branch to copy from"
echo "3 - branch prefix (release vs. backplane)"
echo "4 - to-be branch (#3-x.y)"
exit 1;
fi

if [ -d "$TMPPLACE" ]; then echo "The directory $TMPPLACE exists. I need that, please remove it in order to continue."; exit 1;
fi


setup() {
  # $1 - operator repo (repo that needs the new branch)
  mkdir $TMPPLACE
  cd $TMPPLACE
  git clone git@github.com:stolostron/$1 $TMPPLACE
  cd $TMPPLACE
}

teardown() {
  cd ../..
}

operate() {
  # $2 - existing up-to-date branch to copy from
  # $3 - branch prefix (release vs. backplane)
  # $4 - to-be branch #3-x.y
  git checkout $2
  git pull
  git checkout -b $3-$4
  touch README.md
  git commit -am "Cut new version branch."
  git push --set-upstream origin $3-$4
}

setup $1
operate $2 $3 $4
teardown
