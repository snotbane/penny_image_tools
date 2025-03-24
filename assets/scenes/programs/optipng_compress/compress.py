import os
import sys
import subprocess
import argparse
import configparser
import time

progress_done = 0
difference_total = 0

def set_config(args, option: str, value, section: str = "output"):
	config.read(args.config_path)
	value = str(value)
	config.set(section, option, value)
	with open(args.config_path, 'w') as file:
		config.write(file, space_around_delimiters=False)


def get_config(args, option: str, section: str = "input"):
	config.read(args.config_path)
	return config.get(section, option)


def get_files_todo(args, folder):
	result = 0
	for file in os.listdir(folder):
		if os.path.isdir(os.path.join(folder, file)):
			result += get_files_todo(args, os.path.join(folder, file))
		elif file.lower().endswith(".png"):
			result += 1
	return result


def compress_folder(args, folder):
	for file in os.listdir(folder):
		if get_config(args, "cancel") == "true":
			sys.exit(2)
		if os.path.isdir(os.path.join(folder, file)):
			compress_folder(args, os.path.join(folder, file))
		elif file.lower().endswith(".png"):
			input_file = os.path.join(folder, file)
			compress_png_lossless(args, input_file)


def compress_png_lossless(args, source):
	global progress_done
	global difference_total
	try:
		set_config(args, "progress_path", f"\"{source}\"")

		file_size_before = os.path.getsize(source)

		# subprocess.run([args.optipng, "-o7", "-out", source, source], check=True)
		process = subprocess.Popen([args.optipng, "-o7", "-out", source, source], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)

		while process.poll() is None:
			if get_config(args, "cancel") == "true":
				sys.exit(2)
			time.sleep(0.25)

		file_size_after = os.path.getsize(source)

		set_config(args, "bytes_previous", file_size_before - file_size_after)
		progress_done += 1
		set_config(args, "progress_done", progress_done)
	except Exception as e:
		sys.stderr.write(f"Error compressing {source}: {e}")



if __name__ == "__main__":

	parser = argparse.ArgumentParser(description="Something")
	parser.add_argument("optipng", type=str, help="Path to optipng executable")
	parser.add_argument("source", type=str, help="PNG image file path, or a folder to compress in bulk.")
	parser.add_argument("config_path", type=str)
	args = parser.parse_args()

	config = configparser.ConfigParser()
	config.read(args.config_path)

	set_config(args, 'cancel', "false", "input")
	set_config(args, 'progress_path', "\"\"")
	set_config(args, 'progress_todo', 0)
	set_config(args, 'progress_done', 0)
	set_config(args, 'bytes_previous', 0)

	if os.path.exists(args.source):
		if os.path.isdir(args.source):
			set_config(args, 'progress_todo', get_files_todo(args, args.source))
			compress_folder(args, args.source)
			progress_done += 1
			set_config(args, "progress_done", progress_done)
		elif os.path.isfile(args.source):
			set_config(args, 'progress_todo', 1)
			compress_png_lossless(args, args.source)
		else: sys.stderr.write("Input path is not a file nor directory.")
		sys.exit(0)
	else:
		sys.stderr.write("Input path does not exist.")
		sys.exit(1)
