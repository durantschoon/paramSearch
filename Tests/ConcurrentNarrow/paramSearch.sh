#! /usr/bin/env bash

# see ./config for environment variables
# This script creates and exports the TRIAL_NAME variable
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

if [ `basename $PWD` != $TEST_NAME ]; then
    echo "TEST_NAME \"$TEST_NAME\" in ./config does not match the current diretory"
    echo "It is likely you've copied this directory but not updated ./config"
    echo "Exiting"
    exit 1
fi

TOP_DIR=../.. 
THIS_DIR=Tests/$TEST_NAME # relative to TOP_DIR
TMP_DIR=$THIS_DIR/tmp
REPO_COPY=$TMP_DIR/${REPO_NAME}Copy

# tester is 4 levels deep when called
TESTER=../../../../src/test_params.py
HEAT_MAP_ANIM=$TOP_DIR/src/update_heatmap_anim.py

cd $TOP_DIR
mkdir -p $TMP_DIR
mkdir -p $THIS_DIR/$DATA_DIR
mkdir -p $THIS_DIR/$STATS_DIR
mkdir -p $THIS_DIR/$IMAGES_DIR
mkdir -p $THIS_DIR/$RESULTS_DIR

cd $THIS_DIR
# copy special _test.go file (to overwrite) into the copy of the repo
cp $TOP_DIR/$TEST_FILE .

# determine the next trial number
pushd $STATS_DIR > /dev/null
if [ -d trial001 ]; then
    TRIAL_NUM=`ls -d trial* | sort -rn | head -1 | grep -o '[0-9]\+'`
    let n=$TRIAL_NUM+1
    TRIAL_NAME=`printf "trial%03d" $n`
else
    TRIAL_NAME=trial001
fi
export TRIAL_NAME
mkdir $TRIAL_NAME
popd > /dev/null
export STATS_TRIAL_DIR=$STATS_DIR/$TRIAL_NAME

COUNTER=1

VAR1_LIMIT=$VAR1_START

while [ $VAR1_LIMIT -le $VAR1_END ]; do
    VAR2_LIMIT=$VAR2_START
    while [ $VAR2_LIMIT -le $VAR2_END ]; do
        {
            pushd $TOP_DIR/.. > /dev/null # A
            
            SUFFIX=`printf "%03d" $COUNTER`
            if [ -d $TOP/$REPO_COPY$SUFFIX ]; then
                /bin/rm -rf $TOP/$REPO_COPY$SUFFIX
            fi
            
            echo "Copying $REPO_NAME to $TOP/$REPO_COPY$SUFFIX"
            cp -r $REPO_NAME $TOP/$REPO_COPY$SUFFIX # 2> /dev/null
            pushd $TOP/$REPO_COPY$SUFFIX > /dev/null # B
            
            echo "  Checking out $REPO_TAG"
            git checkout $REPO_TAG &> /dev/null

            echo "  $TESTER -$VAR1 $VAR1_LIMIT -$VAR2 $VAR2_LIMIT"
            $TESTER -$VAR1 $VAR1_LIMIT -$VAR2 $VAR2_LIMIT;

            popd > /dev/null # B

            # end program here to inspect your 1st trial in tmp/
            # echo SUICIDE && exit 0 # uncomment this line
            # you can then manually run "go test" in the copied repo

            if [ "$REMOVE_REPO" == "true" ]; then
                echo "  Removing $TOP/$REPO_COPY$SUFFIX"
                /bin/rm -rf $TOP/$REPO_COPY$SUFFIX
            fi

            popd > /dev/null # A

            # concurrency part 1 
            # } &
            # could run these blocks in the background
            # but there's too much load
        }

        VAR2_LIMIT=$(echo $VAR2_LIMIT*$VAR2_MULT | bc) # multiply
        VAR2_LIMIT=${VAR2_LIMIT%.*} # take floor to convert to int for while test
        let COUNTER=COUNTER+1
    done
    VAR1_LIMIT=$(echo $VAR1_LIMIT*$VAR1_MULT | bc) # multiply
    VAR1_LIMIT=${VAR1_LIMIT%.*} # take floor to convert to int for while test
done

# concurrency part 2 but there's too much load
# wait

cat $STATS_TRIAL_DIR/* | sort -n | uniq > $RESULTS_DIR/STATS_$TRIAL_NAME.csv

# update heatmap animation if not done since last time
mkdir -p $IMAGES_DIR
$HEAT_MAP_ANIM -data_images_dir $IMAGES_DIR -results_images_dir $RESULTS_IMAGES_DIR -out animated.gif

jupyter notebook notebook.ipynb 

