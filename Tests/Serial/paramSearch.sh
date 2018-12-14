#! /usr/bin/env bash

# see ./config for environment variables
# This script and scripts it calls are configured to assume:
# 1) This directory is $TEST_NAME (set in config)
# 2) There is a directory MerkleTree (or the name of your repo)
#    in the same directory as paramSearch
# 3) There is a tagged commit in MerkleTree tagged as $REPO_TAG (set in config)
# 4) Certain files exist: $TOP_DIR/MerkleTree_test.go, etc.
#    (set in config, just need a _test.go file that works in your repo)
# 5) the script will be executed with no arguments from this directory,
#    or from TOP_DIR and this script will try to infer its location

# use some path magic to get to the right directory depending on where this
# script is called from
CALLING_PATH=${0%/*}
if [ ${#CALLING_PATH} -gt 1 ]; then
    echo cd $CALLING_PATH
    cd $CALLING_PATH
fi

source ./config

TOP_DIR=../.. 
THIS_DIR=Tests/$TEST_NAME # relative to TOP_DIR
TMP_DIR=$THIS_DIR/tmp
REPO_COPY=$TMP_DIR/${REPO_NAME}Copy

cd $TOP_DIR
if [ -d $REPO_COPY ]; then
    /bin/rm -rf $REPO_COPY
fi
mkdir -p $TMP_DIR
mkdir -p $THIS_DIR/$RESULTS_DIR

cd ..
echo "Copying $REPO_NAME to $TOP/$REPO_COPY"
cp -r $REPO_NAME $TOP/$REPO_COPY # 2> /dev/null
cd $TOP/$REPO_COPY

echo "Checking out $REPO_TAG"
git checkout $REPO_TAG &> /dev/null

TOP_DIR=../../../..
# copy special _test.go file (to overwrite) into the copy of the repo
cp $TOP_DIR/$TEST_FILE .

echo "Running test_single.py with output in $THIS_DIR/$RESULTS_FILE"
$TOP_DIR/$THIS_DIR/src/test_single.py $TOP_DIR/$THIS_DIR/$RESULTS_FILE

echo -n "Run time: "
cat $TOP_DIR/$THIS_DIR/$RESULTS_FILE

# comment these out if you want to save the modified repo
echo Removing $REPO_COPY
/bin/rm -rf $TOP_DIR/$REPO_COPY

echo "$THIS_DIR $0 DONE"
