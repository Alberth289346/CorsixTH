#!/usr/bin/env python3

"""
  Usage: check_language_files_not_BOM.py [root]
  This script will check the presence of language files encoded in UTF-8 with
  BOM. It will return 0 if none is found. Otherwise, it will print the path of
  the violating files and return an error code.
  If root is not specified, it will use the current directory.
"""

import codecs
import os
import sys


def is_BOM_encoded_file(path):
    """ Returns whether |path| is a file that is encoded in UTF-8 with BOM. """
    if os.path.isfile(path):
        with open(path, 'rb') as f:
            raw = f.read(4)
            return raw.startswith(codecs.BOM_UTF8)
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
        if f.endswith('.lua'):
            found_files = True
            path = os.path.join(root, f)
            if is_BOM_encoded_file(path):
                offending_files.append(f)

if not found_files:
    sys.exit("Did not find any .lua files, wrong start directory?")

if len(offending_files) > 0:
  sys.exit('Found files with UTF-8 with BOM encoding:\n' + "\n".join(offending_files))

sys.exit(0)
