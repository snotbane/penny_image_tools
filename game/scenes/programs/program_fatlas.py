import argparse
import configparser
import json
import os
import re
import sys
import time
from PIL import Image, ImageOps

progress_display = 0


def str2bool(value: str) -> bool:
    if isinstance(value, bool):
        return value
    val = value.lower()
    if val in ('yes', 'true', 't', '1'):
        return True
    elif val in ('no', 'false', 'f', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')


def bus_get(section: str, key: str):
	bus.read(bus_path)
	if not (bus.has_section(section) and bus.has_option(section, key)): return None

	result = bus.get(section, key)
	try:
		b = str2bool(result)
		return b
	except:	pass
	return result


def bus_set(section: str, key: str, value):
	bus.read(bus_path)
	value = str(value)
	if not bus.has_section(section): bus.add_section(section)
	bus.set(section, key, value)
	with open(bus_path, 'w') as file:
		bus.write(file, space_around_delimiters=False)


# class Point:
# 	def __init__(self, x: int, y: int):
# 		self.x = x
# 		self.y = y


class Rect:
	def __init__(self, *args):
		if len(args) == 4 and all(isinstance(arg, int) for arg in args):
			self.x, self.y, self.w, self.h = args
		elif len(args) == 2 and all(isinstance(arg, tuple) and len(arg) == 2 for arg in args):
			(self.x, self.y), (self.w, self.h) = args
		else:
			raise TypeError("Expected 4 integers or 2 (x, y) tuples")


	def __repr__(self):
		return f"Rect({self.x}, {self.y} ... {self.w}, {self.h})"


	@property
	def xy(self) -> tuple[int, int]:
		return (self.x, self.y)
	@xy.setter
	def xy(self, value: tuple[int, int]):
		self.x = value[0]
		self.y = value[1]


	@property
	def size(self) -> tuple[int, int]:
		return (self.w, self.h)
	@size.setter
	def size(self, value: tuple[int, int]):
		self.w = value[0]
		self.h = value[1]


	@property
	def r(self) -> int:
		return self.x + self.w
	@r.setter
	def r(self, value):
		self.w = value - self.x


	@property
	def b(self) -> int:
		return self.y + self.h
	@b.setter
	def b(self, value):
		self.h = value - self.y


	@property
	def rb(self) -> tuple[int, int]:
		return (self.r, self.b)
	@rb.setter
	def rb(self, value: tuple[int, int]):
		self.r = value[0]
		self.b = value[1]


	@property
	def area(self) -> int:
		return self.w * self.h


	## Returns true if the other Rect is completely inside self
	def contains(self, other) -> bool:
		if not isinstance(other, Rect):
			raise TypeError("Expected a Rect instance")
		return (
			self.x <= other.x and self.y <= other.y and
			self.r >= other.r and self.b >= other.b
		)

	## Returns true if the Rects touch at all
	def overlaps(self, other) -> bool:
		if not isinstance(other, Rect):
			raise TypeError("Expected a Rect instance")
		return not (
			self.r <= other.x or self.x >= other.r or
			self.b <= other.y or self.y >= other.b
		)

	def union(self, other):
		result = Rect(min(self.x, other.x), min(self.y, other.y), max(self.r, other.r), max(self.b, other.b))
		result.r = result.w
		result.b = result.h
		return result


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
		return os.path.join(self.root, self.name + ".json")


class SourceImage(PathedImage):
	def __init__(self, root: str, file: str, region: Rect = None, bitmap: Image = None):
		super().__init__(root, file)
		self.image : Image = Image.open(self.full).convert("RGBA")
		self.bitmap : Image = bitmap

		self.source_region = region if region != None else \
			Rect(0, 0, self.image.width, self.image.height)
		self.target_offset = (0, 0)
		self.target_match = None

	@property
	def image_cropped(self) -> Image:
		return self.image.crop((self.source_region.x, self.source_region.y, self.source_region.r, self.source_region.b))

	@property
	def json_data(self) -> dict:
		return {
			"name": self.name,
			"source_region": [self.source_region.x, self.source_region.y, self.source_region.w, self.source_region.h],
			"target_offset": self.target_offset,
		}


	@property
	def target_region(self) -> Rect:
		return Rect(self.target_offset, self.source_region.size)


	def add_to_target(self):
		self.target.add(self)


	def crop_visible(self):
		_, _, _, a = self.image.split()
		a_pixels = a.load()
		w, h = self.image.size

		rx, ry, rw, rh = [-1, -1, -1, -1]
		for x in range(w):
			for y in range(h):
				if a_pixels[x, y] == 0: continue
				rx = x
				break
			if rx != -1: break
		for y in range(h):
			for x in range(w):
				if a_pixels[x, y] == 0: continue
				ry = y
				break
			if ry != -1: break
		for x in range(w):
			for y in range(h):
				if a_pixels[w-x-1, h-y-1] == 0: continue
				rw = w - rx - x
				break
			if rw != -1: break
		for y in range(h):
			for x in range(w):
				if a_pixels[w-x-1, h-y-1] == 0: continue
				rh = h - ry - y
				break
			if rh != -1: break

		self.source_region = Rect(rx, ry, rw, rh)


class TargetImage(PathedImage):
	def __init__(self, root, file, format, margin):
		super().__init__(root, file)

		self.sources = []
		self.margin = margin
		self.snaps = [ [ self.margin, self.margin ] ]

		self.image : Image = Image.new(format, [1, 1])
		self.full_rect : Rect = Rect(0, 0, 1, 1)


	def expand(self, size):
		new_size = (size[0] + self.margin, size[1] + self.margin)
		delta = (0, 0, new_size[0] - self.full_rect.w, new_size[1] - self.full_rect.h)
		self.full_rect.size = new_size
		self.image = ImageOps.expand(self.image, delta)


	def add(self, source: SourceImage):
		rect = Rect(self.get_snap_for(source.source_region.size), source.source_region.size)

		if not self.full_rect.contains(rect):
			self.expand(self.full_rect.union(rect).size)

		self.image.paste(source.image_cropped, (rect.x, rect.y))
		source.target_offset = (rect.x, rect.y)

		self.sources.append(source)

		# Remove the existing snap point
		try:
			self.snaps.remove(source.target_offset)
		except ValueError: pass

		## Add new snap points at the top right and bottom left corners, if they don't exist
		snap1 = (source.target_offset[0] + source.source_region.w + self.margin, source.target_offset[1])
		try:
			_ = self.snaps.index(snap1)
		except ValueError:
			self.snaps.append(snap1)
		snap2 = (source.target_offset[0], source.target_offset[1] + source.source_region.h + self.margin)
		try:
			_ = self.snaps.index(snap2)
		except ValueError:
			self.snaps.append(snap2)


	def get_snap_for(self, size: tuple[int, int]) -> tuple[int, int]:
		candidates = []
		for snap in self.snaps:
			query = Rect(snap[0], snap[1], size[0], size[1])
			overlaps = False
			for source in self.sources:
				if source.target_region.overlaps(query):
					overlaps = True
					break
			if not overlaps:
				candidates.append(query)

		if len(candidates) == 0: return self.snaps[0]
		candidates.sort(key=lambda rect: not self.full_rect.contains(rect))
		return (candidates[0].x, candidates[0].y)


	def save(self):
		os.makedirs(os.path.dirname(self.full), exist_ok=True)
		self.image.save(self.full)


def assign_image_sources():
	result = []
	include = re.compile(args.filter_include)
	exclude = re.compile(args.filter_exclude)
	for root, _, files, in os.walk(args.source):
		for file in files:
			if args.filter_include != "" and re.search(include, file) == None: continue
			if args.filter_exclude != "" and re.search(exclude, file) != None: continue
			try:
				source = SourceImage(root, file)
			except: continue
			result.append(source)
	return result


def assign_image_targets(sources):
	pattern = re.compile(args.filter_separate)
	targets_dict = dict()
	for source in sources:
		match_string = re.search(pattern, source.name).group()
		if targets_dict.get(match_string) == None:
			path = f"{args.project_name}{match_string}.png"
			targets_dict[match_string] = TargetImage(args.target, path, args.image_format, args.island_margin)
		source.target_match = match_string
	return (sources, targets_dict)


class AtlasEntry:
	def __init__(self, match):
		self.full = match.group(0)
		self.name = match.group(1)
		self.mirror = match.group(2)
		self.component = match.group(3)

	@property
	def is_valid(self) -> bool:
		return self.name != None


def assign_compo_data(atlas: dict) -> dict:
	result = dict()

	## Initialize data

	magics = dict()
	name_pattern = re.compile(r"(.+?)(?:_(.))?(?:_(.))?$")
	for k in atlas.keys():
		for image in atlas[k]:
			entry = AtlasEntry(re.search(name_pattern, image["name"]))

			if not entry.name in magics:
				magics[entry.name] = dict()
				magics[entry.name]["components"] = set()
				magics[entry.name]["mirror"] = False

			if entry.component and not entry.component in magics[entry.name]["components"]:
				magics[entry.name]["components"].add(entry.component)

			if not magics[entry.name]["mirror"] and entry.mirror:
				magics[entry.name]["mirror"] = True

	## Assign available sprites

	for name in magics.keys():
		result[name] = dict()
		for i_mirror in range(2 if magics[name]["mirror"] else 1):
			mirror = "" if not magics[name]["mirror"] else f"_{"l" if i_mirror == 1 else "r"}"
			for component in magics[name]["components"]:
				suffix = mirror + f"_{component}"
				prospect = name + suffix

				prospect_in_image = False
				for k in atlas.keys():
					for entry in atlas[k]:
						if prospect != entry["name"]: continue
						prospect_in_image = True
						break
				result[name][suffix] = prospect if prospect_in_image else None

	## Substitute missing mirrors

	for name in result.keys():
		for suffix in result[name]:
			if result[name][suffix] == None:
				r_suffix = "_r" + suffix[2:4]
				result[name][suffix] = result[name][r_suffix]

	return result


def main():
	global progress_display

	if not (
		args.project_name != "" and
		os.path.exists(args.source) and
		os.path.exists(args.target)
	):
		sys.exit(1)

	bus_set("output", "progress_display", 0)
	bus_set("output", "progress_display_max", 0)

	sources = assign_image_sources()
	sources, targets = assign_image_targets(sources)
	bus_set("output", "progress_display_max", len(sources))

	project_json_path = os.path.join(args.target, args.project_name + ".json")

	atlas_data = dict()

	for source in sources:
		if bus_get("input", "stop"):
			sys.exit(1)

		bus_set("output", "source_preview", f"\"{source.full}\"")
		if args.island_crop:
			source.crop_visible()
		target = targets[source.target_match]
		target.add(source)
		bus_set("output", "target_updated", f"\"{target.full}\"")

		if atlas_data.get(target.file) == None:
			atlas_data[target.file] = []
		atlas_data[target.file].append(source.json_data)

		progress_display += 1
		bus_set("output", "progress_display", progress_display)

	json_data = {"atlas": atlas_data, "compo": assign_compo_data(atlas_data)}

	os.makedirs(os.path.dirname(project_json_path), exist_ok=True)
	with open(project_json_path, "w") as file:
		json.dump(json_data, file)

	for k in targets.keys():
		targets[k].save()

if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument("bus_path", type=str)
	parser.add_argument("project_name", type=str)
	parser.add_argument("source", type=str)
	parser.add_argument("target", type=str)
	parser.add_argument("filter_include", type=str)
	parser.add_argument("filter_exclude", type=str)
	parser.add_argument("filter_separate", type=str)
	parser.add_argument("filter_composite", type=str)
	parser.add_argument("image_format", type=str)
	parser.add_argument("image_size_limit", type=int)
	parser.add_argument("island_crop", type=str2bool)
	parser.add_argument("island_margin", type=int)
	args = parser.parse_args()

	bus_path = args.bus_path
	bus = configparser.ConfigParser()
	bus.read(bus_path)

	main()

	sys.exit(0)
