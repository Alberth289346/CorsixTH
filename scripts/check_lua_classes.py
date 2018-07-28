#!/usr/bin/env python3

import os
import re
import sys


# This regex can't find all class declaration mistakes and only checks the
# first few lines:
# Regex: ^class "(.+)".*\n\n(?!---@type \1\nlocal \1 = _G\["\1"])
CLASS_RE = re.compile(r"^class \"(.+)\".*\n\n(?!---@type \1\nlocal \1 = _G\[\"\1\"])")

PRINT_ROOT_REGEX = re.compile("Lua.*")

if len(sys.argv) > 2:
      sys.exit('Usage: ' + sys.argv[0] + ' [root]')

script_dir = os.getcwd()
if len(sys.argv) == 2:
    if not os.path.isdir(sys.argv[1]):
          sys.exit('Error: ' + sys.argv[0] + ' is not a directory')
    script_dir = os.path.abspath(sys.argv[1])

problems = []
found_files = False
for root, subdirs, files in os.walk(script_dir):
    # Drop 'languages' from the search
    for i, subdir in enumerate(subdirs):
        if subdir == 'languages':
            del subdirs[i]
            break

    m = PRINT_ROOT_REGEX.search(root)
    if  not m:
        continue

    path = m.group(0)
    for script in files:
        if script.endswith(".lua"):
            found_files = True

            script_file = os.path.join(root, script)
            script_string = open(script_file, 'r').read()
            for found_class in CLASS_RE.findall(script_string, re.MULTILINE):
                problems.append((path, script, found_class))

if not found_files:
    sys.exit("Did not find any .lua files, wrong start directory?")

if len(problems) > 0:
    print("Invalid/Improper Class Declarations Found:")
    for path, script, found_class in problems:
        print("*{}/{}: {}".format(path, script, found_class))

    sys.exit(1)
sys.exit(0)
