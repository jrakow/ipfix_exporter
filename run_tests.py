#!/usr/bin/env python3
import glob
import json
import os
import subprocess
import sys
from sys import stderr

def eprint(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)

if __name__ == "__main__":
	with open("cases/cases.json") as file:
		json = json.load(file)

	# statistics
	number_of_tests = 0
	expected_tests = 0
	unexpected_tests = 0

	for module in json["modules"]:
		eprint("starting " + module["name"] + " test")

		for case in module["cases"]:
			# default value is not False
			inverted = case.get("invert", False)

			# print header line
			eprint("starting " + module["name"] + " test case: " + case["number"], end="")
			if "title" in case:
				eprint(" \"" + case["title"] + "\"", end="")
			if inverted:
				eprint(" expecting failure", end="")
			eprint()

			args = ["./testbench",
			        "-gg_in_filename=cases/" + module["name"] + "_" + case["number"] + "_in.dat",
			        "-gg_out_filename=cases/" + module["name"] + "_" + case["number"] + "_out.dat"
			       ]
			eprint(args)
			# start subprocess
			exit = subprocess.call(args, stderr=sys.stdout.buffer)

			eprint(module["name"] + " " + case["number"], end="")
			eprint(" succeeded" if exit == 0 else " failed", end="")
			# != is xor
			expected = (exit == 0) != inverted
			eprint(" as expected" if expected else " unexpectedly")

			number_of_tests += 1
			if expected:
				expected_tests += 1
			else:
				unexpected_tests += 1

		eprint("all tests run for module " + module["name"])

	eprint("all tests run")
	eprint("number of tests:  ", number_of_tests)
	eprint("expected tests:   ", expected_tests)
	eprint("unexpected tests: ", unexpected_tests)

	if unexpected_tests != 0:
		sys.exit(1)
