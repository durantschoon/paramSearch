#! /usr/bin/env bash

# Comment out or in only the tests you want to run

# Pass the subdirectory so scripts can find all their files

./Tests/Serial/paramSearch.sh &
./Tests/ConcurrentBroad/paramSearch.sh &
./Tests/ConcurrentNarrow/paramSearch.sh &

wait

echo `basename $PWD` "$0 DONE"
