#!/usr/bin/env python3
import glob
import json
import junitparser as junit
import os
import subprocess
import sys
from multiprocessing.pool import ThreadPool
from sys import stderr
from random import randint
from _ast import mod

def eprint(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)

def make_args(module, case):
	case_filename_stub = "cases/" + module["name"] + "/" + case["number"]
	# VHDL ieee.math_real.uniform seed allowed values
	random_ints = [(str(randint(1, 2147483562)), str(randint(1, 2147483398))) for i in range(0, 2)]
	return ["./testbench",
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

def end_line(test_case_name, exit, expected):
	end_line = "  " + test_case_name
	if exit == 0:
		end_line += " succeeded"
	else:
		end_line += " failed"
	if expected:
		end_line += " as expected"
	else:
		end_line += " unexpectedly"
	return end_line

def run_tests(module):
	eprint(" starting " + module["name"] + " test")

	test_cases = []
	for case in module["cases"]:
		# default value is False
		is_inverted = case.get("invert", False)

		# print header line
		test_case_name = case["number"]
		if "title" in case:
			test_case_name += " " + case["title"]

		# start line
		start_line = "  starting " + test_case_name
		if is_inverted:
			start_line += " expecting failure"
		eprint(start_line)

		args = make_args(module, case)

		# start subprocess
		completed = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		expected = (completed.returncode == 0) != is_inverted # != is xor

		print(end_line(test_case_name, completed.returncode, expected))

		# fill test case data
		test_case = junit.TestCase(test_case_name)
		test_case.system_err = '\n'.join(completed.stderr.decode("utf-8").split('\0'))
		test_case.system_out = '\n'.join(completed.stdout.decode("utf-8").split('\0'))
		if not expected:
			test_case.result = junit.Failure("succeeded" if exit == 0 else "failed" + " unexpectedly")

		test_cases.append(test_case)

	eprint(" all tests run for module " + module["name"])
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

	test_suites  = {}
	arg_vector = []
	module_names = []
	for module in json:
		if module["name"] not in modules:
			# skip if not requested
			continue

		# add module test suite in global list if it does not exist
		if module["name"] not in test_suites:
			test_suites[module["name"]] = junit.TestSuite(module["name"])
		arg_vector.append(module)
		module_names.append(module["name"])

	pool = ThreadPool()
	results = pool.map(run_tests, arg_vector)

	for test_cases, module_name in zip(results, module_names):
		for test_case in test_cases:
			test_suites[module_name].add_testcase(test_case)

	eprint("all tests run")

	# use junit XML as output format
	junit_xml = junit.JUnitXml()

	for name in test_suites:
		junit_xml.add_testsuite(test_suites[name])
	eprint("writing JUnit XML")
	junit_xml.write("junit.xml")
