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

from PIL import Image

if (len(sys.argv)<3):
	print("Usage: generate_combine_texture.py combine_texture.png generated_texture.png source_texture.png")
	print("")
	print("	combine_texture.png")
	print("	generated_texture.png")
	print("	source_texture.png")
	exit()

generated_file = Image.open(sys.argv[2]).convert("RGBA")
source_file = Image.open(sys.argv[3]).convert("RGBA")

if (generated_file.width != source_file.width) or (generated_file.height != source_file.height):
	print("Size of {} and {} files do not match.".format(sys.argv[2], sys.argv[3]))
	exit(1)

new_png = Image.new(mode="RGBA",size=(generated_file.width,generated_file.height),color=(0,0,0,0));
new_data = []

for from_y in range(generated_file.height):
	for from_x in range(generated_file.width):
		gen_color = generated_file.getpixel((from_x,from_y))
		src_color = source_file.getpixel((from_x,from_y))
		combine_color = list(gen_color)
		# 
		# a1 = combine_color[3]/255.0
		# a2 = (src_color[3]/255.0)*(1-a1)
		# a0 = a1 + a2
		# gen_color[0..2] = (combine_color[0..2]*a1 + src_color[0..2]*a2) / a0
		#
		# gen_color[3] = int(a0*255)
		
		if gen_color == src_color:
			# pure copy of src to gen, no combination detected
			combine_color = [0, 0, 0, 0]
		elif src_color[3] < 255:
			# result code
			#
			# a0 = gen_color[3]/255.0
			# a1 = a0 - a2
			# a2 = (src_color[3]/255.0)*(1-a1)
			# a2 = (src_color[3]/255.0)*(1-a0+a2)
			# a2 - a2*src_color[3]/255.0 = (src_color[3]/255.0)*(1-a0)
			# 255*a2 - a2*src_color[3] = src_color[3]*(1-a0)
			# a2 * (255 - src_color[3]) = src+color[3]*(1-a0)
			# a2  = src_color[3]*(1-a0)/(255 - src_color[3])
			# combine_color[0..2] = (gen_color[0..2]*a0 - src_color[0..2]*a2) / a1

			a0 = gen_color[3]/255.0
			a2 = src_color[3]*(1-a0)/(255.0-src_color[3])
			a1 = a0 - a2
			for i in range(3):
				combine_color[i] = int((gen_color[i]*a0 - src_color[i]*a2) / a1)
			combine_color[3] = int(a1*255)
		else:
			# result code for src_color[3] = 255
			#
			# a0 = gen_color[3]/255.0
			# a1 = a0 - a2
			# a2 = (src_color[3]/255.0)*(1-a1)
			# a2 = (1)*(1-a0+a2)
			# a2 = 1 - a0 + a2
			# combine_color[0..2] = (gen_color[0..2]*a0 - src_color[0..2]*a2) / a1
			
			# so will will try to calculate the smallest possible alpha in ranges
			for alpha in range(1, 255):
				a0 = gen_color[3]/255.0
				a1 = alpha/255.0
				a2 = a0 - a1
				good = True
				for i in range(3):
					combine_color[i] = int((gen_color[i]*a0 - src_color[i]*a2) / a1)
				combine_color[3] = int(a1*255)
				for i in range(4):
					good = good and combine_color[i] >= 0 and combine_color[i] <= 255
				if good:
					break

		new_data.append(tuple(combine_color))

new_png.putdata(new_data)
new_png.save(sys.argv[1])

print("Generated texture has been saved into file: {}".format(sys.argv[1]))
