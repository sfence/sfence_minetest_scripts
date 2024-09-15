#!/bin/python3

import os
import glob

def list_files_by_ext(directory, ext):
	# Use glob to find all wanted files in the directory and subdirectories
	ext_files = glob.glob(os.path.join(directory, "**", "*{}".format(ext)), recursive=True)
	return ext_files

def symbols_(files):
	for file in files:
		with open(file_path, 'r') as file:
			lines = file.readlines()

			symbols = []
			for line in lines:
			if line.startswith('symbols:'):
