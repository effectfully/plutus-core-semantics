#!/usr/bin/env python

import sys
import re
import xml.etree.ElementTree as ET
import subprocess            as SP

def get_value(key, result):
    root  = ET.fromstring(result)
    genv  = root.findall("genv")
    reg   = re.compile(re.escape(key) + " \|->\ ([^\ ]*)")
    result = reg.search(genv[0].text).group(1)
    if not result:
        print(key + " not found")
        return None
    else:
        return result

def main():
    result = SP.check_output(["./run-pretty.sh", sys.argv[1]])

    fname = sys.argv[1]
    expr = sys.argv[2]

    re_has_value = re.compile("has\_value\((.*), (.*)\)")
    if re_has_value.match(expr):
        key = re_has_value.search(expr).group(1)
        val = re_has_value.search(expr).group(2)
        if get_value(key, result) == val:
            tmp = "{} has value {}, after running {}."
            print(tmp.format(key, val, fname))
    else:
        print("Unrecognized expression")

if __name__ == "__main__":
    main()
