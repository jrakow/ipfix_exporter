#!/usr/bin/env python3
import glob
import json
import junitparser as junit
import os
import subprocess
import sys
from sys import stderr
from random import randint
from _ast import mod

def eprint(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)

def run_tests(module):
	eprint(" starting " + module["name"] + " test")

	test_cases = []
	for case in module["cases"]:
		# default value is not False
		inverted = case.get("invert", False)

		# print header line
		eprint("  starting " + module["name"] + " test case: " + case["number"], end="")
		if "title" in case:
			eprint(" \"" + case["title"] + "\"", end="")
		if inverted:
			eprint(" expecting failure", end="")
		eprint()

		case_filename_stub = "cases/" + module["name"] + "/" + case["number"]
		# VHDL ieee.math_real.uniform seed allowed values
		random_ints = [(str(randint(1, 2147483562)), str(randint(1, 2147483398))) for i in range(0, 2)]
		args = ["./testbench",
		        "--wave=waveforms/" + module["name"] + "/" + case["number"] + ".ghw",
		        "-gg_module=" + module["name"],

		        "-gg_in_tdata_width=" + str(module["g_in_tdata_width"]),
		        "-gg_out_tdata_width=" + str(module["g_out_tdata_width"]),

		        "-gg_in_filename="  + (case_filename_stub + "_in.dat"  if os.path.isfile(case_filename_stub + "_in.dat")  else "/dev/null"),
		        "-gg_out_filename=" + (case_filename_stub + "_out.dat" if os.path.isfile(case_filename_stub + "_out.dat") else "/dev/null"),
		        "-gg_emu_filename=" + (case_filename_stub + ".emu"     if os.path.isfile(case_filename_stub + ".emu")     else "/dev/null"),

		        "-gg_random_tvalid_seed_0=" + random_ints[0][0],
		        "-gg_random_tvalid_seed_1=" + random_ints[0][1],
		        "-gg_random_tready_seed_0=" + random_ints[1][0],
		        "-gg_random_tready_seed_1=" + random_ints[1][1]
		       ]

		# start subprocess
		completed = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		exit = completed.returncode

		eprint("  " + module["name"] + " " + case["number"], end="")
		eprint(" succeeded" if exit == 0 else " failed", end="")
		# != is xor
		expected = (exit == 0) != inverted
		eprint(" as expected" if expected else " unexpectedly")

		seeds_were = "seeds were (" + random_ints[0][0] + ", " + random_ints[0][1] + ", " + random_ints[1][0] + ", " + random_ints[1][1] + ")"

		# fill test case data
		test_case = junit.TestCase(case["number"])
		if case["title"]:
			test_case.name += " " + case["title"]
		test_case.system_err = '\n'.join(completed.stderr.decode("utf-8").split('\0'))
		test_case.system_out = '\n'.join((completed.stdout.decode("utf-8") + '\0' + seeds_were).split('\0'))
		if not expected:
			test_case.result = junit.Failure("succeeded" if exit == 0 else "failed" + " unexpectedly")

		test_cases.append(test_case)
	return test_cases

if __name__ == "__main__":
	assert len(sys.argv) > 1, 'specify either module names or "all"'
	eprint("starting test run")
	with open("cases/cases.json") as file:
		json = json.load(file)

	modules = []
	if sys.argv[1] == "all":
		for module in json:
			if module not in modules:
				modules.append(module["name"])
	else:
		for name in sys.argv[1:]:
			assert name in [module["name"] for module in json], 'module "' + name + '" not found'
			modules.append(name)

	test_suites = {}
	for module in json:
		if module["name"] not in modules:
			# skip if not requested
			continue

		# add module test suite in global list if it does not exist
		if module["name"] not in test_suites:
			test_suites[module["name"]] = junit.TestSuite(module["name"])

		test_cases = run_tests(module)
		for test_case in test_cases:
			test_suites[module["name"]].add_testcase(test_case)

		eprint(" all tests run for module " + module["name"])

	eprint("all tests run")

	# use junit XML as output format
	junit_xml = junit.JUnitXml()

	for name in test_suites:
		junit_xml.add_testsuite(test_suites[name])
	eprint("writing JUnit XML")
	junit_xml.write("junit.xml")
