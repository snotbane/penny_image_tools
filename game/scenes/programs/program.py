import argparse
import configparser
import sys
import time

def bus_get(section: str, key: str):
	bus.read(bus_path)
	if not (bus.has_section(section) and bus.has_option(section, key)): return None
	return bus.get(section, key)


def bus_set(section: str, key: str, value):
	bus.read(bus_path)
	value = str(value)
	bus.set(section, key, value)
	with open(bus_path, 'w') as file:
		bus.write(file, space_around_delimiters=False)


def main():
	while bus_get("input", "stop") != "true":
		time.sleep(0.05)


if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument("bus_path", type=str, help="Path to the data bus associated with this program instance.")
	args = parser.parse_args()

	bus_path = args.bus_path
	bus = configparser.ConfigParser()
	bus.read(bus_path)

	main()

	sys.exit(0)
