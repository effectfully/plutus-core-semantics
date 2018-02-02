#!/usr/bin/env python

import sys
import re
import xml.etree.ElementTree as ET

def get_value(key):
    root  = ET.parse(sys.argv[1]).getroot()
    genv  = root.findall("genv")
    reg   = re.compile(re.escape(key) + " \|->\ ([^\ ]*)")
    result = reg.search(genv[0].text).group(1)
    if not result:
        print(key + " not found")
        return None
    else:
        return result

def main():
    expr = sys.argv[2]
    re_has_value = re.compile("has\_value\((.*), (.*)\)")
    if re_has_value.match(expr):
        key = re_has_value.search(expr).group(1)
        val = re_has_value.search(expr).group(2)
        print(get_value(key) == val)
    else:
        print("Unrecognized expression")

if __name__ == "__main__":
    main()
