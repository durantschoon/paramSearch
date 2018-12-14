#! /usr/bin/env python

"""
Return the latest trial in data/stats or trial001 if none found
"""

import glob
import os

def latest_trial():
    os.chdir("data/stats")
    files = glob.glob("trial*")
    if not files:
        return "trial001"
    return sorted(files)[-1]

if __name__ == "__main__":
    print(latest_trial())
