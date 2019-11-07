#!/usr/bin/python3
import os
import glob
import platform
import subprocess

print("Checking /srv for a11y issues...")

def get_all_files_with_ext(directory, extension):
    files_list = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(extension):
                files_list.append(os.path.join(root, file))
    return files_list


if __name__ == "__main__":
    html_files = get_all_files_with_ext("/srv", ".html")
    for html_file in html_files:
        subprocess.call(["pa11y", "--config", "/tmp/pa11y.config.json", html_file])
