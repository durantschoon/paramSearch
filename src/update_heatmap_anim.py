#! /usr/bin/env python

"""Combine all the heatmap png files from data images dir into an
animated gif file in the results images dir with output name from
-out.
"""

import argparse
import os
import subprocess

def main():
    "main"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('-data_images_dir')
    parser.add_argument('-results_images_dir')
    parser.add_argument('-out', default="animated.gif")
    args = parser.parse_args()
    output_file = args.out

    top_dir = os.getcwd()

    os.chdir(args.data_images_dir)
    cmd = "convert -delay 120 -loop 0 heatmap*.png " + output_file
    subprocess.run(cmd, shell=True, check=True)

    os.chdir(top_dir)

    move_from = os.path.join(args.data_images_dir, output_file)
    move_to = os.path.join(args.results_images_dir, output_file)

    if os.path.exists(move_to):
        os.remove(move_to)
    os.rename(move_from, move_to)

    print("new animated heatmap {}".format(move_to))

if __name__ == "__main__":
    main()
