#!/usr/bin/env python3

"""
  Usage: check_trailing_whitespaces.py [root]
  This script will check the presence of trailing whitespaces in any file
  below |root|. It will return 0 if none is found. Otherwise, it will print the
  path of the violating file and return an error code.
  If root is not specified, it will use the current directory.
"""

import re
import os
import sys

TRAILING_SEQUENCE = re.compile(r'[ \t][\r\n]')

def has_trailing_whitespace(path):
    """ Returns whether |path| has trailing whitespace. """
    if os.path.isfile(path):
        with open(path, 'r') as handle:
            for line in handle:
                m = TRAILING_SEQUENCE.search(line)
                if m:
                    return True

    return False


SOURCE_EXTENSIONS = ['.py', '.lua', '.h', '.cpp', '.cc', '.c']

def is_sourcefile(path):
    if not os.path.isfile(path):
        return True
    for ext in SOURCE_EXTENSIONS:
        if path.endswith(ext):
            return True

    return False


if len(sys.argv) > 2:
     sys.exit('Usage: ' + sys.argv[0] + ' [root]')

top = os.getcwd()
if len(sys.argv) == 2:
    if not os.path.isdir(sys.argv[1]):
          sys.exit('Error: ' + sys.argv[0] + ' is not a directory')
    top = os.path.abspath(sys.argv[1])

offending_files = []
found_files = False
for root, dirs, files in os.walk(top):
  for f in files:
    path = os.path.join(root, f)
    if is_sourcefile(path):
        found_files = True
        if has_trailing_whitespace(path):
            offending_files.append(path)

if not found_files:
    sys.exit("Did not find any source file, wrong start directory?")

if len(offending_files) > 0:
  sys.exit('Found files with trailing whitespace:\n' + "\n".join(offending_files))

sys.exit(0)
