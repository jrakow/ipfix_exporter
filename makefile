GHDL := ghdl
GHDLFLAGS := --std=08 -g

.SUFFIXES:

TESTBENCH_SRCS := \
                  pkg_axis_testbench_io.vhdl \
                  axis_checker.vhdl \
                  axis_generator.vhdl \
                  cpu_emulator.vhdl \
                  module_wrapper.vhdl \
                  testbench.vhdl \
                  testbench_test_dummy.vhdl

.PHONY: all

all: testbench

testbench: ${TESTBENCH_SRCS}
	${GHDL} -i ${GHDLFLAGS} --work=axis_testbench ${TESTBENCH_SRCS}
	${GHDL} -m ${GHDLFLAGS} --work=axis_testbench -o testbench testbench

.PHONY: clean
clean:
	rm -rf \
	       ${TESTBENCH_SRCS:.vhdl=.o} \
	       testbench.o \
	       e~testbench.o \
	       axis_testbench-obj08.cf \
	       testbench \
	       waveforms \
	       html

.PHONY: run
run: testbench cases/*
	./run_tests.py

.PHONY: html
html:
	doxygen 2>&1 | sed '/.*Elaborating.*/d' | sed '/^$$/d'
