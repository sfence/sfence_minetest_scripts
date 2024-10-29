#!/usr/bin/python3

# Copyright 2024 SFENCE <sfence.software@gmail.com>
#
# Redistribution and use in source and binary forms,
# with or without modification, are permitted provided 
# that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import sys
import subprocess
import os.path
import pathlib
import random
import json

from PIL import Image

if (len(sys.argv)<7):
	print("Usage: generate_sculpture_texture.py sculpture_texture.png source_texture.png select.png mask.png data")
	print("")
	print("	sculpture_texture.png")
	print("	source_texture.png")
	print("	select.png")
	print("	mask.png")
	print("	data - json format") 
	print("	seed")
	exit()

source_file = Image.open(sys.argv[2]).convert("RGBA")
select_file = None
mask_file = None
data = json.loads(sys.argv[5])

random.seed(int(sys.argv[6]))

if sys.argv[3] != "NO":
	select_file = Image.open(sys.argv[3]).convert("RGBA")

	if (select_file.width != source_file.width) or (select_file.height != source_file.height):
		print("Size of {} and {} files do not match.".format(sys.argv[2], sys.argv[3]))
		exit(1)

if sys.argv[4] != "NO":
	mask_file = Image.open(sys.argv[4]).convert("RGBA")

	if (mask_file.width != source_file.width) or (mask_file.height != source_file.height):
		print("Size of {} and {} files do not match.".format(sys.argv[2], sys.argv[4]))
		exit(1)

new_png = Image.new(mode="RGBA",size=(source_file.width*4,source_file.height*4),color=(0,0,0,0));
new_data = []

def getRandomColor():
	while True:
		x = random.randint(0,source_file.width-1)
		y = random.randint(0,source_file.height-1)
		if select_file:
			select_color = select_file.getpixel((x,y))
			if select_color[3] < 255:
				continue
		color = source_file.getpixel((x,y))
		rand_color = [color[c] for c in range(3)]
		for c in range(3):
			if c in data:
				rmin = data[c].min
				rmax = data[c].max
				if rmin != rmax:
					r = 0
					if n in data[c]:
						for n in range(data[c].n):
							r = r + random.random()
						r = r/data[c].n
					else:
						r = random.random()
					r = rmin + (rmax - rmin)*r
					if True:
						rand_color[c] = color[c] + r
					else:
						rand_color[c] = color[c] * r
		return rand_color

s_height = source_file.height*4
s_width = source_file.width*4

for from_y in range(s_height):
	for from_x in range(s_width):
		mask_color = [0, 0, 0, 255]
		if mask_file:
			mask_color = mask_file.getpixel((from_x % source_file.width, from_y % source_file.height))

		sculpture_color = [0, 0, 0, 0]
		if mask_color[3] != 0:
			sculpture_color = getRandomColor()

		new_data.append(tuple(sculpture_color))

new_png.putdata(new_data)
new_png.save(sys.argv[1])

print("Generated texture has been saved into file: {}".format(sys.argv[1]))
