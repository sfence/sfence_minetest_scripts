#!/bin/python3

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

import re
# scikit-learn pip package
from sklearn.cluster import KMeans
import numpy

import operator

# pillow pip package
from PIL import Image

if (len(sys.argv)<8):
	print("Usage: generate_moss_stages.py stage_name full_moss.png grow_stages mature_stages dying_stages stages.png group_file")
	print("")
	print("  stage_name -> 'stage_name_{}.png'")
	print("  full_moss.png -> full grown stage")
	print("  grow_stages -> stages before full grow, can be 0, use negative value to not generate but do naming offset")
	print("  mature_stages -> stages after full grow, can be 0")
	print("  dying_stages -> stages after full mature, can be 0, stages.png have to be defined")
	print("  stages.png -> .png files with typical stage colors, use no to generate, should have grow_stages + 1 + dying_stages pixels")
	print("  group_file -> .png file name or NO")
	exit();

stage_name = sys.argv[1]
full_file_name = sys.argv[2]
grow_stages = int(sys.argv[3])
mature_stages = int(sys.argv[4])
dying_stages = int(sys.argv[5])
stages_file_name = sys.argv[6]
group_file = sys.argv[7]

full_file = Image.open(full_file_name).convert("RGBA");

#randGen = random.Random(int(sys.argv[6]))

stage_offset = max(0, -grow_stages) + max(0, -mature_stages)

grow_stages = max(grow_stages, 0)
mature_stages = max(mature_stages, 0)

stages = [[0,0,0,0]]*(grow_stages + 1)
min_stages = grow_stages + 1 + mature_stages
max_stages = min_stages + dying_stages

if "." in stages_file_name:
	stages_file = Image.open(stages_file_name).convert("RGBA");
	index = 0
	file_stages = stages_file.height * stages_file.width
	if (file_stages < min_stages) or (file_stages > max_stages):
		print("Bad combinarion of grow_stages, mature_stages, dying_stages and stages.png file. {} - {} pixels are expected in '{}' file.".format(min_stages, max_stages, stages_file_name))
		exit(1)
	stages = [[0,0,0,0]]*file_stages
	for from_y in range(stages_file.height):
		for from_x in range(stages_file.width):
			stage_color = stages_file.getpixel((from_x,from_y))
			stages[index] = stage_color;
			index = index + 1
else:
	# this expect normal behaviors, light green for young stages, darker green for older one, dying stages is not supported
	if dying_stages > 0:
		print("Please use custom stages.png file defined from command line when dying_stages should be generated.")
		exit(1)
	greys = {}
	for from_y in range(full_file.height):
		for from_x in range(full_file.width):
			from_color = full_file.getpixel((from_x,from_y))
			if from_color[3] > 0:
				greys[int(from_color[0]*0.2126 + from_color[1]*0.7152 + from_color[2]*0.0722)] = from_color
	if len(greys) < (grow_stages + 1):
		print("No enought stages detected. Please provide stages.png file defined from command line.")
		exit(1)
	data = []
	for grey in greys:
		data.append([grey, 0])
	kmeans = KMeans(n_clusters=grow_stages+1).fit(numpy.array(data))
	for_sort = []
	for_avg = {}
	for index in range(len(kmeans.cluster_centers_)):
		for_sort.append([index, kmeans.cluster_centers_[index][0]])
		for_avg[index] = [[0, 0, 0, 0], 0]
	for grey in greys:
		cluster = kmeans.predict([[grey, 0]])[0]
		weight = 1/(1 + abs(grey - for_sort[cluster][1]))
		data = for_avg[cluster]
		data[0] = [data[0][i] + weight*greys[grey][i] for i in range(4)]
		data[1] = data[1] + weight
		for_avg[cluster] = data
	for_sort = sorted(for_sort, key=operator.itemgetter(1), reverse=True)
	for stage in range(len(stages)):
		cluster = for_sort[stage][0]
		stages[stage] = for_avg[cluster][0] / for_avg[cluster][1]
		stages[stage] = [ round(for_avg[cluster][0][i] / for_avg[cluster][1]) for i in range(4)]
	

if "." in group_file:
	print("Saving group file: {}".format(group_file))
	new_png = Image.new(mode="RGBA",size=(1,len(stages)),color=(0,0,0,255));
	new_data = []

	for index in range(len(stages)):
		new_data.append(tuple(stages[index]))

	new_png.putdata(new_data)
	new_png.save(group_file)

def color_nearness(clr1, clr2):
	base = (clr1[0] - clr2[0])**2	
	base = base + (clr1[1] - clr2[1])**2
	base = base + (clr1[2] - clr2[2])**2
	#return pow(base, 0.5)
	return base

def stage_index(color):
	stage = 0
	min_diff = color_nearness(stages[stage], color)
	for index in range(1, len(stages)):
		diff = color_nearness(stages[index], color)
		if diff < min_diff:
			stage = index
			min_diff = diff
	return stage

def color_move(stage_color, clr):
	cmove = [1, 1, 1, 1]
	for i in range(4):
		if stage_color[i] > 0:
			cmove[i] = (clr[i] - stage_color[i])/stage_color[i]
	return cmove

def clamp_color(value):
	return max(min(255, value), 0)	

# generate stages
new_png = Image.new(mode="RGBA",size=(full_file.width,full_file.height),color=(0,0,0,0));
for stage in range(grow_stages + 1 + mature_stages):
	file_name = stage_name.format(stage_offset + stage)
	if stage < grow_stages:
		new_data = []
		for from_y in range(full_file.height):
			for from_x in range(full_file.width):
				from_color = full_file.getpixel((from_x,from_y))
				new_color = [0,0,0,0]
				if from_color[3] > 0:
					si = stage_index(from_color)
					us = si - grow_stages + stage
					if us >= 0:
						mclr = color_move(stages[si], from_color)
						sclr = stages[us]
						new_color = [clamp_color(round(sclr[i] + mclr[i] * from_color[i])) for i in range(4)]
				new_data.append(tuple(new_color))
		new_png.putdata(new_data)
		new_png.save(file_name)
		print("Saving growing stage file: {}".format(file_name))
	if stage == grow_stages:
		new_data = []
		for from_y in range(full_file.height):
			for from_x in range(full_file.width):
				new_data.append(full_file.getpixel((from_x,from_y)))
		new_png.putdata(new_data)
		new_png.save(file_name)
		print("Saving full grown stage file: {}".format(file_name))
	if stage > grow_stages:
		new_data = []
		for from_y in range(full_file.height):
			for from_x in range(full_file.width):
				from_color = full_file.getpixel((from_x,from_y))
				new_color = [0,0,0,0]
				if from_color[3] > 0:
					si = stage_index(from_color)
					us = min(si + stage - grow_stages, len(stages)-1)
					mclr = color_move(stages[si], from_color)
					sclr = stages[us]
					new_color = [clamp_color(round(sclr[i] + mclr[i] * from_color[i])) for i in range(4)]
				new_data.append(tuple(new_color))
		new_png.putdata(new_data)
		new_png.save(file_name)
		print("Saving maturing stage file: {}".format(file_name))

stage_offset = stage_offset + grow_stages + 1 + mature_stages

for stage in range(dying_stages):
	file_name = stage_name.format(stage_offset + stage)
	new_data = []
	for from_y in range(full_file.height):
		for from_x in range(full_file.width):
			from_color = full_file.getpixel((from_x,from_y))
			new_color = [0,0,0,0]
			if from_color[3] > 0:
				si = stage_index(from_color)
				us = si + stage + grow_stages + 1 + mature_stages
				if us < len(stages):
					mclr = color_move(stages[si], from_color)
					sclr = stages[us]
					new_color = [clamp_color(round(sclr[i] + mclr[i] * from_color[i])) for i in range(4)]
			new_data.append(tuple(new_color))
	new_png.putdata(new_data)
	new_png.save(file_name)
	print("Saving dying stage file: {}".format(file_name))

#new_png.putdata(new_data)

# most common color is leaves

#new_png = Image.new(mode="RGBA",size=(full_file.width,full_file.height),color=(0,0,0,255));
#new_data = []

#new_png.putdata(new_data)
#new_png.save(sys.argv[1])

#print("Generated texture has been saved into file: {}".format(sys.argv[1]))

