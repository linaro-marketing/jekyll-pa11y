#!/usr/bin/python3
import os
import glob
import platform
print(platform.python_version())
print("Working")
os.chdir("/srv")
for file in glob.glob("index.html"):
    print(file)
