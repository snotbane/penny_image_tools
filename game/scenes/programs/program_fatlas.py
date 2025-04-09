import argparse
import configparser
import json
import os
import re
import sys
import time
from PIL import Image, ImageOps

progress_display = 0

def bus_get(section: str, key: str):
	bus.read(bus_path)
	if not (bus.has_section(section) and bus.has_option(section, key)): return None
	return bus.get(section, key)


def bus_set(section: str, key: str, value):
	bus.read(bus_path)
	value = str(value)
	if not bus.has_section(section): bus.add_section(section)
	bus.set(section, key, value)
	with open(bus_path, 'w') as file:
		bus.write(file, space_around_delimiters=False)


class Rect:
	def __init__(self, x, y, w, h):
		self.x : int = x
		self.y : int = y
		self.w : int = w
		self.h : int = h

	def contains(other) -> bool:
		return False

	def union(self, other):
		return self

	def colliderect(self, other):
		return False


class PathedImage:
	def __init__(self, root, file):
		self.root = root
		self.file = file
		self.full = os.path.join(root, file)
		self.name, self.ext = os.path.splitext(file)


	def __str__(self):
		return self.file


	@property
	def json_path(self) -> str:
		return f"{self.root}\\{self.name}.json"


class SourceImage(PathedImage):
	def __init__(self, root: str, file: str, region: Rect = None, bitmap: Image = None):
		super().__init__(root, file)
		self.image : Image = Image.open(self.full).convert("RGBA")
		self.bitmap : Image = bitmap

		if region == None:
			region = Rect(0, 0, self.image.width, self.image.height)

		self.source_region = region
		self.target_offset = (0, 0)
		self.target_match = None

	@property
	def image_cropped(self) -> Image:
		if self.bitmap == None: return self.image

		result : Image = self.image.crop((self.source_region.x, self.source_region.y, self.source_region.w, self.source_region.h))
		r, g, b, a = result.split()
		mask = self.bitmap.convert("L")
		mask_pixels = mask.load()
		alpha_pixels = a.load()

		for x in range(result.width):
			for y in range(result.height):
				alpha_pixels[x, y] = min(mask_pixels[x, y], alpha_pixels[x, y])

		result = Image.merge("RGBA", (r, g, b, a))
		# self.bitmap.show()
		return result


	@property
	def json_data(self) -> dict:
		return {
			"name": self.name,
			"source_offset": {
				"x": self.source_region.x,
				"y": self.source_region.y,
			},
			"target_region": {
				"x": int(self.target_offset[0]),
				"y": int(self.target_offset[1]),
				"w": self.source_region.w,
				"h": self.source_region.h,
			},
		}


	@property
	def target_region(self) -> Rect:
		return Rect(self.target_offset, self.source_region.size)


	def add_to_target(self):
		print(f"Added {self.name} to '{self.target}'")
		self.target.add(self)


	def crop_islands(self):
		bitmap = self.get_opacity_bitmap(args.island_opacity)
		pixels = bitmap.load()
		w, h = self.image.size
		visited = set()
		news = []

		def flood_fill(x, y):
			stack = [(x, y)]
			island_pixels = []

			while stack:
				px, py = stack.pop()
				if (px, py) in visited or px < 0 or py < 0 or px >= w or py >= h:
					continue
				if pixels[px, py] == 0:
					continue

				visited.add((px, py))
				island_pixels.append((px, py))

				stack.extend([(px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)])
			return island_pixels

		def crop_islands_accumulate():
			rects = None
			bitms = set()
			for x in range(w):
				for y in range(h):
					if (x, y) not in visited and pixels[x, y] == 1:
						island_pixels = flood_fill(x, y)
						if island_pixels:
							min_x = min(p[0] for p in island_pixels)
							max_x = max(p[0] for p in island_pixels)
							min_y = min(p[1] for p in island_pixels)
							max_y = max(p[1] for p in island_pixels)
							island_rect = Rect(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

							if island_rect.w * island_rect.h < args.island_size: continue

							if rects == None:
								rects = island_rect
							else:
								rects = rects.union(island_rect)
							bitms = bitms.union(island_pixels)

			full_rect = rects
			full_bitmap = Image.new("1", full_rect.size, color=0)
			full_bitmap_pixels = full_bitmap.load()

			for px, py in bitms:
				full_bitmap_pixels[px - full_rect.left, py - full_rect.top] = 1
			return SourceImage(self.root, self.file, full_rect, full_bitmap)

		return crop_islands_accumulate()


	def get_opacity_bitmap(self, threshold: int = 1):
		bitmap = Image.new("1", self.image.size)
		pixels = bitmap.load()

		for x in range(bitmap.width):
			for y in range(bitmap.height):
				_, _, _, a = self.image.getpixel((x, y))
				pixels[x, y] = 0 if a < threshold else 1

		return bitmap


class TargetImage(PathedImage):
	def __init__(self, root, file, format, margin):
		super().__init__(root, file)

		self.sources = []
		self.margin = (margin, margin)
		self.snaps = [ self.margin ]

		self.image : Image = Image.new(format, [1, 1])
		self.full_rect : Rect = Rect(0, 0, 1, 1)


	def expand(self, size):
		new_size = (size[0] + self.margin[0], size[1] + self.margin[1])
		delta = (0, 0, new_size[0] - self.full_rect.size[0], new_size[1] - self.full_rect.size[1])
		self.full_rect.size = new_size
		self.image = ImageOps.expand(self.image, delta)


	def add(self, source: SourceImage):
		size = source.source_region.size
		snap = self.get_snap_for(size)
		rect = Rect(snap[0], snap[1], size[0], size[1])

		if not self.full_rect.contains(rect):
			self.expand(self.full_rect.union(rect).size)

		self.image.paste(source.image_cropped, (rect.x, rect.y))
		source.target_offset = (rect.x, rect.y)

		self.sources.append(source)

		try:
			self.snaps.remove(source.target_offset)
		except ValueError: pass
		snap1 = (source.target_offset[0] + source.source_region.width + self.margin[0], source.target_offset[1])
		try:
			_ = self.snaps.index(snap1)
		except ValueError:
			self.snaps.append(snap1)
		snap2 = (source.target_offset[0], source.target_offset[1] + source.source_region.height + self.margin[1])
		try:
			_ = self.snaps.index(snap2)
		except ValueError:
			self.snaps.append(snap2)


	def get_snap_for(self, size: tuple[int, int]) -> tuple[int, int]:
		candidates = []
		for snap in self.snaps:
			query = Rect(snap[0], snap[1], size[0], size[1])
			intersects = False
			for source in self.sources:
				if source.target_region.colliderect(query):
					intersects = True
					break
			if not intersects:
				candidates.append(query)

		if len(candidates) == 0: return self.snaps[0]
		candidates.sort(key=lambda rect: not self.full_rect.contains(rect))
		return (candidates[0][0], candidates[0][1])


	def save(self):
		os.makedirs(os.path.dirname(self.full), exist_ok=True)
		print(f"Saving image to {self.full} ...")
		self.image.save(self.full)
		print(f"Saved image!")


def assign_image_sources():
	result = []
	pattern = re.compile(args.filter_include)
	for root, dirs, files, in os.walk(args.source):
		for file in files:
			if re.search(pattern, file) == None: continue
			source = SourceImage(root, file)
			result.append(source)
	return result


def assign_image_targets(sources):
	result = []
	pattern = re.compile(args.filter_separate)
	targets_dict = dict()
	for source in sources:
		print(f"Pattern: {pattern}, source.name: {source.name}")
		match_string = re.search(pattern, source.name).group()
		if targets_dict.get(match_string) == None:
			name, ext = os.path.splitext(args.project_name)
			path = f"{name}{match_string}{ext}"
			targets_dict[match_string] = TargetImage(args.target, path, args.target_format, args.island_margin)
		source.target_match = match_string
	return (sources, targets_dict)


def assign_comp_data(maps : dict) -> dict:
	result = dict()
	available = list()
	components = set()
	pattern = re.compile(r"((.+?)(?:_(\d+))?)_([lr])_(.)")
	for k in maps.keys():
		for entry in maps[k]:
			available.append(entry["name"])
			match = re.search(pattern, entry["name"])

			if not match:
				print("One or more matches were not found in the regex; double check your pattern!")
				return dict()

			components.add(match.group(5))
			if result.get(match.group(1)) == None:
				is_latter_index = match.group(3) != None and int(match.group(3)) != 0

				if is_latter_index: result[match.group(1)] = f"{match.group(2)}_{"0".zfill(len(match.group(3)))}"
				else: result[match.group(1)] = None

	for k in result.keys():
		comp = dict()
		index_base_entry = result[k]

		for c in components:
			r_suffix = f"_r_{c}"
			r_name = k + r_suffix
			l_suffix = f"_l_{c}"
			l_name = k + l_suffix

			i = 0
			for m in maps.keys():
				if i == 2: break
				for entry in maps[m]:
					if i == 2: break
					if entry["name"] == r_name:
						comp[r_suffix] = r_name
						i += 1
					elif entry["name"] == l_name:
						comp[l_suffix] = l_name
						i += 1

			if index_base_entry != None and comp.get(r_suffix) == None and result[index_base_entry].get(r_suffix) != None:
				comp[r_suffix] = result[index_base_entry][r_suffix]

			if comp.get(l_suffix) == None and comp.get(r_suffix) != None:
				comp[l_suffix] = comp[r_suffix]


		result[k] = comp
	return result


def main():
	global progress_display

	sources = assign_image_sources()
	sources, targets = assign_image_targets(sources)
	bus_set("output", "progress_display_max", len(sources))

	target = TargetImage(args.target, args.project_name, args.image_format, args.island_margin)

	maps_data = dict()

	for source in sources:
		# if args.test_limit > -1 and i > args.test_limit: break
		if args.island_crop:
			print(f"Cropping image '{source.name}' ({progress_display + 1}/{len(sources)}) ...")
			source = source.crop_islands()
		target_file = targets[source.target_match].file
		print(f"Appending image '{source.name}' to '{target_file}'...")
		targets[source.target_match].add(source)

		if maps_data.get(target_file) == None:
			maps_data[target_file] = []
		maps_data[target_file].append(source.json_data)

		progress_display += 1
		bus_set("output", "progress_display", progress_display)

	print(f"Conglomeration complete.")

	comp_data = assign_comp_data(maps_data)

	json_data = {"maps": maps_data, "composites": comp_data}

	os.makedirs(os.path.dirname(target.json_path), exist_ok=True)
	with open(target.json_path, "w") as file:
		json.dump(json_data, file)

	for k in targets.keys():
		target = targets[k]
		target.save()


if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument("bus_path", type=str, help="Path to the data bus associated with this program instance.")
	parser.add_argument("project_name", type=str, help="Target template path for each atlas.")
	parser.add_argument("source", type=str, help="Source folder to compile images from.")
	parser.add_argument("target", type=str, help="Target folder to export atlases to.")
	parser.add_argument("image_size_limit", help="The max pixel dimensions a target image can be. If an island cannot be placed within one image, a new one will be created. Use to limit the size of target images.")
	parser.add_argument("image_format", type=str, help="Image format.")
	parser.add_argument("filter_include", type=str, help="Only file paths that match this regex will be included (considers extensions)." )
	parser.add_argument("filter_separate", type=str, help="File names (not including extension) that match this regex will be separated into different images.")
	parser.add_argument("island_margin", help="Islands above this threshold will have their regions expanded by this margin to include any surrounding pixels.")
	parser.add_argument("island_crop")
	parser.add_argument("island_opacity", help="Pixels with an opacity above this threshold will be considered part of a contiguous island.")
	parser.add_argument("island_size", help="Islands with an area smaller than this will be discarded.")
	args = parser.parse_args()

	bus_path = args.bus_path
	bus = configparser.ConfigParser()
	bus.read(bus_path)

	main()

	sys.exit(0)
