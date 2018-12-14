#! /usr/bin/env bash 

echo Results
echo =======
ls -1d Tests/*/results/*
echo ""

echo -n "Are you really sure you want to delete all results in Tests? (y or n) [n] "

read answer

if  [[ $answer == y* ]] || [[ $answer == Y* ]] ; then
    echo Ok, here we go...
    /bin/rm -rf Tests/*/results/*
    echo They\'re gone.
else
    echo Doing nothing
fi

