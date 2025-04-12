import argparse
import configparser
import sys
import time


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


def main():
	while True:
		if bus_get("input", "stop"): break
		time.sleep(0.05)


if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument("bus_path", type=str, help="Path to the data bus associated with this program instance.")
	parser.add_argument("source", type=str, help="All files in this folder will have normal created.")
	parser.add_argument("target", type=str, help="Destination for normal images.")
	args = parser.parse_args()
	parser.add_argument("island_size", type=int, help="Islands with an area smaller than this will be discarded.")
	parser.add_argument("island_opacity", type=int, help="Pixels with an opacity above this threshold will be considered part of a contiguous island.")
	args = parser.parse_args()

	bus_path = args.bus_path
	bus = configparser.ConfigParser()
	bus.read(bus_path)

	main()

	sys.exit(0)
