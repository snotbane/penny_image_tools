import sys
import os
import re
import subprocess
import argparse
import configparser
import time
from PIL import Image

progress_done = 0

def set_config(args, option: str, value, section: str = "output"):
	config.read(args.config_path)
	value = str(value)
	config.set(section, option, value)
	with open(args.config_path, 'w') as file:
		config.write(file, space_around_delimiters=False)


def get_config(args, option: str, section: str = "input"):
	config.read(args.config_path)
	return config.get(section, option)

class TargetImage:
	def __init__(self, root, file, src_root, src_file):
		self.root = root
		self.file = file
		self.full = os.path.join(root, file)
		self.name, self.ext = os.path.splitext(file)

		self.src_root = src_root
		self.src_file = src_file
		self.src_full = os.path.join(src_root, src_file)


	def __str__(self):
		return self.file


	def generate(self, args):
		global progress_done
		try:
			set_config(args, "source_preview", f"\"{self.src_full}\"")
			os.makedirs(os.path.dirname(self.full), exist_ok=True)

			sub_args = [args.laigter_path, "--no-gui", "-d", self.src_full, "-n"]
			if args.laigter_preset:
				sub_args.append("-r")
				sub_args.append(args.laigter_preset)

			process = subprocess.Popen(args=sub_args, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)

			while process.poll() is None:
				if get_config(args, "cancel") == "true":
					sys.exit(2)
				time.sleep(0.25)

			result_path = os.path.join(self.src_root, f"{self.name}{self.ext}")
			image = Image.open(result_path)

			source : Image = Image.open(self.src_full).convert("RGBA")
			image.putalpha(source.getchannel("A"))
			image.save(self.full)
			os.remove(result_path)
			set_config(args, "target_preview", f"\"{self.full}\"")
		except Exception as e:
			sys.stderr.write(f"Error processing {self.full}: {e}")

		progress_done += 1
		set_config(args, "progress_done", progress_done)
		# print(f"Saved image to {self.full}")



def assign_image_sources(args):
	result = []
	pattern = re.compile(args.regex_restrict)
	for _, _, files in os.walk(args.source):
		for file in files:
			if re.search(pattern, file) == None: continue
			result.append(file)
	return result


def assign_image_targets(sources, args):
	result = []
	for source in sources:
		name, ext = os.path.splitext(source)
		path = f"{name}_n{ext}"
		result.append(TargetImage(args.target, path, args.source, source))
	return result


if __name__ == "__main__":
	print("\n\n")

	parser = argparse.ArgumentParser(description="Something")
	parser.add_argument("laigter_path", type=str, help="Path to Laigter.")
	parser.add_argument("source", type=str, help="All files in this folder will have normal created.")
	parser.add_argument("target", type=str, help="Destination for normal images.")
	parser.add_argument("regex_restrict", type=str, required=False, default=r".+(?<!_n)\.png$", help="Only file paths that match this regex will be included (considers extensions).")
	parser.add_argument("laigter_preset", "-r", type=str, required=False, default=None, help="Path to laigter preset file")
	parser.add_argument("config_path", type=str)
	args = parser.parse_args()

	config = configparser.ConfigParser()
	config.read(args.config_path)

	set_config(args, 'cancel', "false", "input")
	set_config(args, 'source_preview', "\"\"")
	set_config(args, 'target_preview', "\"\"")
	set_config(args, 'progress_todo', 0)
	set_config(args, 'progress_done', 0)

	if os.path.isdir(args.source):
		source_paths = assign_image_sources(args)
		targets = assign_image_targets(source_paths, args)

		set_config(args, 'progress_todo', len(targets))
		i = 0
		for target in targets:
			i += 1
			target.generate(args)
	elif os.path.isfile(args.source):
		set_config(args, 'progress_todo', 1)

		source = assign_image_sources(args)[0]
		target = assign_image_targets(source, args)[0]
		target.generate(args)
	else:
		sys.stderr.write("Input path is not a valid file nor directory.")
		sys.exit(1)
	sys.exit(0)
