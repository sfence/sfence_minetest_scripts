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

from PIL import Image

if (len(sys.argv)<11):
	print("Usage: generate_flora_stages.py stage_name full_flora.png full_bloom.png algorithm grow_stages mature_stages dying_stages stages_file group_file seed")
	print("")
	print("  stage_name -> 'stage_name_{}.png'")
	print("  full_flora.png -> full grown stage picture file name")
	print("  full_bloom.png -> full bloom stage picture file name or NO")
	print("  algorithm -> grass|flower")
	print("  grow_stages -> stages before full grow, can be 0, use negative value to not generate but do naming offset")
	print("  mature_stages -> stages after full grow, can be 0")
	print("  dying_stages -> stages after full mature, can be 0, stages.png have to be defined")
	print("  stages.png -> picture files with typical stage colors, first column is for green part, second and others for bloom parts")
	print("  group_file -> picture file name or NO")
	print("  seed -> pseudorandom generator seed init value")
	exit();

# green part -> no more than 70% of other color then green
# bloom part -> bloom with no green color is expected
# can be defined by mask file also?

stage_name = sys.argv[1]
full_flower_name = sys.argv[2]
full_bloom_name = sys.argv[3]
algorithm = sys.argv[4]
grow_stages = int(sys.argv[5])
mature_stages = int(sys.argv[6])
dying_stages = int(sys.argv[7])
stages_file_name = sys.argv[8]
group_file = sys.argv[9]
seed = int(sys.argv[10])

full_flower = Image.open(full_flower_name).convert("RGBA");
green_row_only = -1
bloom_rows_only = -1
full_bloom = None
if "." in full_bloom_name:
	full_bloom = Image.open(full_bloom_name).convert("RGBA");
	if (full_bloom.width != full_flower.width) or (full_bloom.height != full_flower.height):
		raise Exception("Flower ({}) and bloom ({}) picture size mismatch.".format(full_flower_name, full_bloom_name))
	green_row_only = 0
	bloom_rows_only = -2
else:
	full_bloom = full_flower

#randGen = random.Random(int(sys.argv[6]))

stage_offset = max(0, -grow_stages) + max(0, -mature_stages)

grow_stages = max(grow_stages, 0)
mature_stages = max(mature_stages, 0)

min_stages = grow_stages + mature_stages
max_stages = min_stages + dying_stages

stages_file = Image.open(stages_file_name).convert("RGBA")
if (stages_file.width < 2):
	print("At least two columns of pixels are expected in stages '{}' file.".format(stages_file_name))
	exit(1)
if (stages_file.height < min_stages) and (stages_file.height > max_stages):
	print("{} - {} rows of pixels are expected in stages '{}' file.".format(min_stages, max_stages, stages_file_name))
	exit(1)


random.seed(seed)

def color_nearness(clr1, clr2):
	base = (clr1[0] - clr2[0])**2	
	base = base + (clr1[1] - clr2[1])**2
	base = base + (clr1[2] - clr2[2])**2
	#return pow(base, 0.5)
	return base

def color_move(stage_color, clr):
	cmove = [1, 1, 1, 1]
	for i in range(4):
		if stage_color[i] > 0:
			cmove[i] = (clr[i] - stage_color[i])/stage_color[i]
	return cmove

def clamp_color(value):
	return max(min(255, value), 0)	

def get_stage(clr, from_row):
	row = -1
	stage = -1
	diff = 1000000
	for from_x in range(stages_file.width):
		# check only selected row
		if (from_row >= 0) and (from_row != from_x):
			continue
		# check only bloom rows
		if (from_row == -2) and (from_x > 0):
			continue
		for grow_stage in range(grow_stages + mature_stages):
			check_color = stages_file.getpixel((from_x, grow_stage))
			near = color_nearness(check_color, clr)
			if near < diff:
				diff = near
				row = from_x
				stage = grow_stage
	return (row, stage)

def get_stage_color(row, stage):
	return stages_file.getpixel((row, stage))

if "." in group_file:
	print("Saving group file: {}".format(group_file))
	new_png = Image.new(mode="RGBA",size=(full_flower.width,full_flower.height),color=(0,0,0,255));
	new_data = []

	for from_y in range(full_flower.height):
		for from_x in range(full_flower.width):
			from_color = full_flower.getpixel((from_x,from_y))
			if from_color[3] == 0:
				new_data.append(tuple([255,255,255,255]))
				continue
			row = get_stage(from_color, -1)[0]
			if row == 0:
				new_data.append(get_stage_color(0, grow_stages))
			else:
				new_data.append(get_stage_color(row, grow_stages + mature_stages - 1))

	new_png.putdata(new_data)
	new_png.save(group_file)

def pos_id(x, y):
	return y*full_flower.width + x

growing_map = {}

def look_for_parents(x, y):
	checks = [[x, y+1], [x-1, y+1], [x+1, y+1],
		[x-1, y], [x+1, y],
		[x, y-1], [x-1, y-1], [x+1, y-1]]
	for check in checks:
		if check[0] > 0 and check[0] < full_flower.width and check[1] > 0 and check[1] < full_flower.height:
			check_id = pos_id(check[0], check[1])
			if check_id in growing_map:
				return check_id
	return -1

def look_for_bloom_parents(x, y, row):
	checks = [[x, y+1], [x-1, y+1], [x+1, y+1],
		[x-1, y], [x+1, y],
		[x, y-1], [x-1, y-1], [x+1, y-1]]
	candidate_id = -1
	for check in checks:
		if check[0] > 0 and check[0] < full_flower.width and check[1] > 0 and check[1] < full_flower.height:
			check_id = pos_id(check[0], check[1])
			if check_id in bloom_map:
				if bloom_map[check_id]["row"] == row:
					if candidate_id == -1:
						candidate_id = check_id
				elif bloom_map[check_id]["row"] == (row - 1):
					return check_id
	return candidate_id

def look_for_bloom_neighboors(x, y):
	checks = [[x, y+1], [x-1, y+1], [x+1, y+1],
		[x-1, y], [x+1, y],
		[x, y-1], [x-1, y-1], [x+1, y-1]]
	found = []
	for check in checks:
		if check[0] > 0 and check[0] < full_flower.width and check[1] > 0 and check[1] < full_flower.height:
			check_id = pos_id(check[0], check[1])
			if check_id in bloom_map:
				found.append(check_id)
	return found

# cycle only for ground part of flora
from_y = full_flower.height - 1
for from_x in range(full_flower.width):
	from_color = full_flower.getpixel((from_x,from_y))
	if from_color[3] > 0:
		stage = get_stage(from_color, green_row_only)
		if stage[0] == 0:
			from_id = pos_id(from_x, from_y)
			growing_map[from_id] = {
				"x": from_x,
				"y": from_y,
				"length": 0,
				"row": 0,
				"stage": stage[1],
				"color_move": color_move(get_stage_color(0, stage[1]), from_color),
				"parent": -1,
				"children": []}

# add other green parts of flora
found = True
while found:
	found = False
	print("Go throught")

	for from_y in range(full_flower.height):
		from_y = full_flower.height - 1 - from_y
		for from_x in range(full_flower.width):
			check_id = pos_id(from_x, from_y)
			if check_id in growing_map:
				continue
			from_color = full_flower.getpixel((from_x,from_y))
			if from_color[3] == 0:
				continue
			print("Check {}x{}".format(from_x, from_y))
			parent_id = look_for_parents(from_x, from_y)
			if parent_id == -1:
				continue
			stage = get_stage(from_color, green_row_only)
			if stage[0] != 0:
				continue
			print("Add {} from {}x{}.".format(check_id, from_x, from_y))
			growing_map[check_id] = {
				"x": from_x,
				"y": from_y,
				"length": growing_map[parent_id]["length"] + 1,
				"row": 0,
				"stage": stage[1],
				"color_move": color_move(get_stage_color(0, stage[1]), from_color),
				"parent": parent_id,
				"children": []}
			growing_map[parent_id]["children"].append(check_id)
			found = True

print(growing_map)

bloom_map = {}
group = 0

# found bloom centers
for from_y in range(full_bloom.height):
	from_y = full_flower.height - 1 - from_y
	for from_x in range(full_bloom.width):
		from_color = full_bloom.getpixel((from_x,from_y))
		if from_color[3] == 0:
			continue
		stage = get_stage(from_color, bloom_rows_only)
		if stage[0] != 0:
			print("x: {}; y: {}; stage: {}".format(from_x, from_y, stage))
		if stage[0] == 1:
			check_id = pos_id(from_x, from_y)
			bloom_map[check_id] = {
				"x": from_x,
				"y": from_y,
				"length": 0,
				"row": 1,
				"stage": stage[1],
				"color_move": color_move(get_stage_color(1, stage[1]), from_color),
				"parent": -1,
				"group": group}
			group = group + 1

# separate blooms if there is more blooms
print("separate")
found = True
while found:
	found = False
	for from_y in range(full_bloom.height):
		from_y = full_bloom.height - 1 - from_y
		for from_x in range(full_bloom.width):
			from_color = full_bloom.getpixel((from_x,from_y))
			if from_color[3] == 0:
				continue
			check_id = pos_id(from_x, from_y)
			if check_id in bloom_map:
				group = bloom_map[check_id]["group"]
				for found_id in look_for_bloom_neighboors(from_x, from_y):
					if bloom_map[found_id]["group"] > group:
						#print("Replace group {} by {} in {}".format(bloom_map[found_id]["group"], group, found_id))
						bloom_map[found_id]["group"] = group
						found = True

# get bloom groups
groups = []
for bloom in bloom_map.values():
	if bloom["group"] not in groups:
		groups.append(bloom["group"])

centers = []

print("centers")
# keep only bloom center points
for group in groups:
	sum_x = 0
	sum_y = 0
	blooms = 0
	for bloom in bloom_map.values():
		if bloom["group"] == group:
			print("For avarage {}x{}".format(bloom["x"], bloom["y"]))
			sum_x = sum_x + bloom["x"]
			sum_y = sum_y + bloom["y"]
			blooms = blooms + 1

	sum_x = sum_x/blooms
	sum_y = sum_y/blooms

	print("Avarage {}x{}".format(sum_x, sum_y))
	diff = 1000000
	center_id = -1

	for bloom_id, bloom in bloom_map.items():
		if bloom["group"] == group:
			check = (bloom["x"]-sum_x)**2 + (bloom["y"]-sum_y)**2
			if check < diff:
				diff = check
				center_id = bloom_id

	centers.append(center_id)
	print("Center {}x{}".format(bloom_map[center_id]["x"], bloom_map[center_id]["y"]))

# remove non center bloom parts
blooms = {}
for bloom_id, bloom in bloom_map.items():
	if bloom_id in centers:
		blooms[bloom_id] = bloom

bloom_map = blooms

# for each center, check and possibly add a growing way to green part
if green_row_only == -1:
	# connection of green part to bloom centers have to be generated
	print("Generating connection between bloom centers and green parts")
	print(centers)
	def get_distance(part1, part2):
		dx = part1["x"] - part2["x"]
		dy = part1["y"] - part2["y"]
		return pow(dx*dx + dy*dy, 0.5)

	# get list of green color moves
	gmoves = []
	for part in growing_map.values():
		gmoves.append(part["color_move"])

	mingrow = 1000000000
	mindist = 1000000000
	grow_id = None
	for center_id in centers:
		center = bloom_map[center_id]
		for part_id in growing_map.keys():
			part = growing_map[part_id]
			if len(part["children"])>0:
				continue
			dist = get_distance(center, part)
			grow = part["length"] + dist
			print(part)
			print("grow: {}, mingrow: {}".format(grow, mingrow))
			if grow < mingrow or (grow == mingrow and dist < mindist):
				mingrow = grow
				mindist = dist
				grow_id = part_id
		# update path
		part = growing_map[grow_id]
		print(part)
		print(center)
		dx = center["x"] - part["x"]
		dy = center["y"] - part["y"]
		print("dx: {}; dy: {}".format(dx, dy))
		gens = []
		if abs(dx) >= abs(dy):
			for rx in range(1, abs(dx)):
				ry = int(round((rx/abs(dx))*dy))
				rx = int(round((rx/abs(dx))*dx))
				gens.append([rx, ry])
		else:
			for ry in range(1, abs(dy)):
				rx = int(round((ry/abs(dy))*dx))
				ry = int(round((ry/abs(dy))*dy))
				gens.append([rx, ry])
		parent_id = grow_id
		for pos in gens:
			# just add grow stage
			rx = pos[0] + part["x"]
			ry = pos[1] + part["y"]
			gen_id = pos_id(rx, ry)
			print("Add connection {} [{},{}] from parent {}".format(gen_id, rx, ry, parent_id))
			cm1 = gmoves[random.randint(0, len(gmoves)-1)]
			cm2 = gmoves[random.randint(0, len(gmoves)-1)]
			cmf1 = random.random()
			cmf2 = 1.0 - cmf1
			cm = [cm1[i]*cmf1 + cm2[i]*cmf2 for i in range(4)]
			growing_map[gen_id] = {
				"x": rx,
				"y": ry,
				"length": growing_map[parent_id]["length"] + 1,
				"row": 0,
				"stage": 0,
				"color_move": cm,
				"parent": parent_id,
				"children": []}
			growing_map[parent_id]["children"].append(gen_id)
			parent_id = gen_id
			print(growing_map[gen_id])
		bloom_map[center_id]["parent"] = parent_id
		bloom_map[center_id]["length"] = growing_map[parent_id]["length"] + 1
		print(bloom_map[center_id])
	
print("parents")
# look for bloom parents
found = True
while found:
	found = False
	for from_y in range(full_bloom.height):
		from_y = full_bloom.height - 1 - from_y
		for from_x in range(full_bloom.width):
			from_color = full_flower.getpixel((from_x,from_y))
			if from_color[3] == 0:
				continue
			stage = get_stage(from_color, bloom_rows_only)
			if stage[0] == 0:
				continue
			print("Check {}x{} row {}".format(from_x, from_y, stage[0]))
			check_id = pos_id(from_x, from_y)
			if check_id in bloom_map:
				continue
			parent_id = look_for_bloom_parents(from_x, from_y, stage[0])
			if parent_id == -1:
				continue
			print("Add {} from {}x{}.".format(check_id, from_x, from_y))
			bloom_map[check_id] = {
				"x": from_x,
				"y": from_y,
				"length": bloom_map[parent_id]["length"] + 1,
				"row": stage[0],
				"stage": stage[1],
				"color_move": color_move(get_stage_color(stage[0], stage[1]), from_color),
				"parent": parent_id}
			found = True
print(bloom_map)

# check if every flora part is added to map

for from_y in range(full_flower.height):
	for from_x in range(full_flower.width):
		from_color = full_flower.getpixel((from_x,from_y))
		if from_color[3] > 0:
			from_id = pos_id(from_x, from_y)
			if from_id not in growing_map and ((from_id not in bloom_map) and (green_row_only != -1)):
				raise Exception("Find flower part not growing from other flower part or ground at {}x{}.".format(from_x, from_y))

if green_row_only != -1:
	for from_y in range(full_bloom.height):
		for from_x in range(full_bloom.width):
			from_color = full_bloom.getpixel((from_x,from_y))
			if from_color[3] > 0:
				from_id = pos_id(from_x, from_y)
				if from_id not in bloom_map:
					raise Exception("Find flower part not growing from other flower part or ground at {}x{}.".format(from_x, from_y))

print("All flora part has been detected")

# find max green growing length
max_green_length = 0
for part in growing_map.values():
	if part["length"] > max_green_length:
		max_green_length = part["length"]

# find max bloom growing length
max_bloom_length = 0
for part in bloom_map.values():
	if part["length"] > max_bloom_length:
		max_bloom_length = part["length"]

# generate stages
# growing without bloom
# maturing with bloom
new_png = Image.new(mode="RGBA",size=(full_flower.width,full_flower.height),color=(0,0,0,0));
next_green_stage = {}
next_bloom_stage = {}
dying_from_color_green = {}
dying_from_color_bloom = {}
for stage in range(grow_stages + mature_stages):
	file_name = stage_name.format(stage_offset + stage)
	new_data = []
	green_length = min((stage+1)/grow_stages * max_green_length, max_green_length)
	print("green_len: {}/{}".format(green_length, max_green_length))
	bloom_length = 0 if stage < grow_stages else (stage - grow_stages + 1)/mature_stages * (max_bloom_length - max_green_length)
	print("bloom_len: {}/{}".format(max(0, bloom_length), max_bloom_length - max_green_length))
	for from_y in range(full_flower.height):
		for from_x in range(full_flower.width):
			part_id = pos_id(from_x, from_y)
			new_color = [0,0,0,0]
			if part_id in growing_map:
				part = growing_map[part_id]
				if part["length"] <= green_length:
					from_color = full_flower.getpixel((from_x, from_y))
					mclr = part["color_move"]
					si = next_green_stage[part_id] if part_id in next_green_stage else 0
					sclr = get_stage_color(0, si)
					new_color = [clamp_color(round(sclr[i] + mclr[i] * from_color[i])) for i in range(4)]
					next_green_stage[part_id] = si + 1
					dying_from_color_green[part_id] = new_color
			if stage >= grow_stages:
				if part_id in bloom_map:
					part = bloom_map[part_id]
					if part["length"] <= (bloom_length * 2 + max_green_length):
						from_color = full_bloom.getpixel((from_x, from_y))
						mclr = part["color_move"]
						si = next_bloom_stage[part_id] if part_id in next_bloom_stage else 0 
						sclr = get_stage_color(part["row"], si + grow_stages)
						new_color = [clamp_color(round(sclr[i] + mclr[i] * from_color[i])) for i in range(4)]
						next_bloom_stage[part_id] = min(si + 2, mature_stages - 1)
						dying_from_color_bloom[part_id] = new_color
			new_data.append(tuple(new_color))
	new_png.putdata(new_data)
	new_png.save(file_name)
	if stage < grow_stages:
		print("Saving growing stage file: {}".format(file_name))
	else:
		print("Saving maturing stage file: {}".format(file_name))

stage_offset = stage_offset + grow_stages + mature_stages

green_part_maturing = True
green_dying_from = {}
bloom_dying_from = {}
for stage in range(dying_stages):
	file_name = stage_name.format(stage_offset + stage)
	new_data = []
	dying_length = (1 - (2*stage+1)/dying_stages)*(max_bloom_length)
	print("dying_length: {}/{}".format(dying_length, max_bloom_length))
	print("green maturing: {}".format(green_part_maturing))
	for from_y in range(full_flower.height):
		for from_x in range(full_flower.width):
			part_id = pos_id(from_x, from_y)
			new_color = [0,0,0,0]
			if part_id in growing_map:
				from_color = full_flower.getpixel((from_x, from_y))
				part = growing_map[part_id]
				mclr = part["color_move"]
				if part["length"] >= dying_length:
					green_part_maturing = False
					si = next_green_stage[part_id]
					if (si <= (grow_stages + mature_stages)):
						si = stage_offset + round((stage/dying_stages) * (dying_stages - stage))
						green_dying_from[part_id] = stage
					sclr = get_stage_color(0, si)
					new_color = [clamp_color(round(sclr[i] + mclr[i] * from_color[i])) for i in range(4)]
					grow_color = dying_from_color_green[part_id]
					dpf = green_dying_from[part_id]
					pn = (stage - dpf)/(dying_stages - dpf)
					pg = 1 - pn
					#new_color = [clamp_color(round(pn*new_color[i] + pg*grow_color[i])) for i in range(4)]
					next_green_stage[part_id] = min(round(si + dying_stages/(dying_stages - dpf)), max_stages - 1)
				elif green_part_maturing:
					si = next_green_stage[part_id]
					sclr = get_stage_color(0, si)
					new_color = [clamp_color(round(sclr[i] + mclr[i] * from_color[i])) for i in range(4)]
					next_green_stage[part_id] = min(si + 1, min_stages - 1)
					dying_from_color_green[part_id] = new_color
				else:
					new_color = dying_from_color_green[part_id]

			if part_id in bloom_map:
				part = bloom_map[part_id]
				if part["length"] >= dying_length:
					si = next_bloom_stage[part_id]
					if (si <= (grow_stages + mature_stages)):
						si = stage_offset + round((stage/dying_stages) * (dying_stages - stage))
						bloom_dying_from[part_id] = stage
					sclr = get_stage_color(part["row"], si)
					if sclr[3] > 0:
						from_color = full_bloom.getpixel((from_x, from_y))
						mclr = part["color_move"]
						new_color = [clamp_color(round(sclr[i] + mclr[i] * from_color[i])) for i in range(4)]
						bloom_color = dying_from_color_bloom[part_id]
						dpf = bloom_dying_from[part_id]
						pn = (stage - dpf)/(dying_stages - dpf)
						pb = 1 - pn
						#new_color = [clamp_color(round(pn*new_color[i] + pb*bloom_color[i])) for i in range(4)]
						next_bloom_stage[part_id] = min(round(si + dying_stages/(dying_stages - dpf)), max_stages - 1)
				else:
					new_color = dying_from_color_bloom[part_id]
			new_data.append(tuple(new_color))
	new_png.putdata(new_data)
	new_png.save(file_name)
	print("Saving dying stage file: {}".format(file_name))

