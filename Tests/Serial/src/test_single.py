#! /usr/bin/env python

"""Calls 'go test'

Writes time statistics from 'go test' to results file passed in as
first argument

Expects variables in ./config to have been sourced into the environment

"""

import subprocess
import sys

def main():
    "main"
    results_file = sys.argv[1]

    output = subprocess.getoutput("go test").split()
    assert(len(output) == 4 and output[0] == "PASS")

    run_time = output[3]

    with open(results_file, 'w') as f:
        f.write(run_time + "\n")

if __name__ == "__main__":
    main()
