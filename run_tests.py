#!/usr/bin/env python3
import glob
import json
import os
import subprocess
import sys
from sys import stderr
from random import randint

def eprint(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)

if __name__ == "__main__":
	with open("cases/cases.json") as file:
		json = json.load(file)

	# statistics
	number_of_tests = 0
	expected_tests = 0
	unexpected_tests = 0

	for module in json:
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

			case_filename_stub = module["name"] + "/" + case["number"]
			# VHDL ieee.math_real.uniform seed allowed values
			random_ints = [(str(randint(1, 2147483562)), str(randint(1, 2147483398))) for i in range(0, 2)]
			args = ["./testbench",
			        "--wave=waveforms/" + case_filename_stub + ".ghw",
			        "-gg_module=" + module["name"],

			        "-gg_in_tdata_width=" + str(module["g_in_tdata_width"]),
			        "-gg_out_tdata_width=" + str(module["g_out_tdata_width"]),

			        "-gg_in_filename=cases/" + case_filename_stub + "_in.dat",
			        "-gg_out_filename=cases/" + case_filename_stub + "_out.dat",
			        "-gg_emu_filename=cases/" + case_filename_stub + ".emu",

			        "-gg_random_tvalid_seed_0=" + random_ints[0][0],
			        "-gg_random_tvalid_seed_1=" + random_ints[0][1],
			        "-gg_random_tready_seed_0=" + random_ints[1][0],
			        "-gg_random_tready_seed_1=" + random_ints[1][1]
			       ]
			# start subprocess
			exit = subprocess.call(args, stderr=sys.stdout.buffer)

			eprint(module["name"] + " " + case["number"], end="")
			eprint(" succeeded" if exit == 0 else " failed", end="")
			# != is xor
			expected = (exit == 0) != inverted
			eprint(" as expected" if expected else " unexpectedly")
			if not expected:
				eprint("seeds were (" + random_ints[0][0] + ", " + random_ints[0][1] + ", " + random_ints[1][0] + ", " + random_ints[1][1] + ")")

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
