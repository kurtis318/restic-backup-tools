#!/usr/bin/env python3

"""
Test converting time to seconds
"""

import argparse
import os

TIME1='time1'
TIME2='time2'

THIS_SCRIPT = os.path.basename(os.path.realpath(__file__))
THIS_SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

g_args: argparse.Namespace = None


def _str_to_sec(hhmmss: str) -> int:
    """Returns "hh:mm:ss" converted to seconds
    """
    array = hhmmss.split(":")
    if len(array) != 3:
        print(f">>> ERROR: cannot convert '{hhmmss}'")
    hh = array[0]
    mm = array[1]
    ss = array[2]
    sum = (int(hh) * 3600) + (int(mm) * 60) + int(ss)
    return sum

def main() -> None:
    """
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(TIME1,
                        type=str,
                        help='time of day in form hh:mm:ss')
    parser.add_argument(TIME2,
                        type=str,
                        help='time of day in form hh:mm:ss')
    global g_args
    args = parser.parse_args()
    g_args = vars(args)

    time1 = g_args[TIME1]
    time2 = g_args[TIME2]
    sec1 = _str_to_sec(time1)
    sec2 = _str_to_sec(time2)
    secs = sec2 - sec1
    mins = secs / 60
    # print(f"time1='{time1}' time2='{time2}'")
    # print(f"sec1='{sec1}' sec2='{sec2}'")
    print(f"{time2} - {time1} = {sec2}ms - {sec1}ms = {secs}s / {mins:.2f}m")


if __name__ == "__main__":
    main()
