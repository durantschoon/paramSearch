#! /usr/bin/env python

"""
Replaces variables in go file
Calls 'go test'
Writes statistics from time 'go test' reports to csv file

Uses environment variables:
REPO_NAME
STATS_TRIAL_DIR
VAR1
VAR2
"""

import argparse
import csv
import os
import re
import subprocess

from collections import namedtuple

VAR_REGEX_TEMPLATE = r'^const\s+%s\s+int\s+=.*'

class FoundReplacement(Exception):
    "Expeption used to signal a replacement was found."
    pass

def get_stats_trial_dir():
    ancestry = [os.pardir]*2
    temp = os.environ.get('STATS_TRIAL_DIR', None)
    if temp is not None:
        # Convert data/stats/trial001
        # to ../../data/stats/trial001
        stats_trial_dir = os.path.join(*ancestry, temp)
    else:
        cmd = "../../src/latest_trial.py"
        trial = subprocess.getoutput(cmd)
        stats_trial_dir = os.path.join(*ancestry, 'data', 'stats', trial)
    return stats_trial_dir

def main():
    "main"

    parser = argparse.ArgumentParser(
        description='Replace variable values in Merkletree.go and '
        'record run time of "go test" in directory RUNTIMES'
    )
    parser.add_argument('-%s' % os.environ['VAR1'], type=int)
    parser.add_argument('-%s' % os.environ['VAR2'], type=int)
    args = parser.parse_args()

    go_file = os.environ['REPO_NAME'] + ".go"
    output_stats_dir = get_stats_trial_dir()

    Replacer = namedtuple('Replacer', ['var', 'value', 'matcher', 'replacement'])
    replacers = []
    vars_replaced = []
    values_replaced = []

    for key, value in args.__dict__.items():
        if value != None:
            r = Replacer(
                var=key,
                value=str(value),
                matcher=re.compile(VAR_REGEX_TEMPLATE % key),
                replacement="const {} int = {}\n".format(key, value),
            )
            replacers.append(r)

    buffer = ""
    with open(go_file, 'r') as f:
        for line in f:
            try:
                for r in replacers:
                    if r.matcher.match(line):
                        # print(line)
                        # print(r.replacement)
                        buffer += r.replacement
                        vars_replaced.append(r.var)
                        values_replaced.append(r.value)
                        raise FoundReplacement()
            except FoundReplacement:
                continue
            buffer += line
    with open(go_file, 'w') as f:
        f.write(buffer)
        print("  Wrote %s with replaced variables" % go_file)

    if not os.path.exists(output_stats_dir):
        os.mkdir(output_stats_dir)

    print("  Running 'go test' for performance stats")
    output = subprocess.getoutput("go test").split()
    assert(len(output) == 4 and output[0] == "PASS")

    run_time = output[3]

    flattened = []
    for var, val in zip(vars_replaced, values_replaced):
        flattened += [var, val]

    stats_filename = "_".join(flattened) + ".csv"
    csv_filename = os.path.join(output_stats_dir, stats_filename)

    with open(csv_filename, 'w') as csvfile:
        writer = csv.writer(csvfile)
        fieldnames = vars_replaced[:]
        fieldnames.append("time")
        writer.writerows([fieldnames])
        csv_values = values_replaced[:]
        csv_values.append(run_time)
        writer.writerows([csv_values])

    print("  Wrote", csv_filename)

if __name__ == "__main__":
    main()
