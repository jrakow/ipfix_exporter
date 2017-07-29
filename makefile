GHDL := ghdl
GHDLFLAGS := --std=08 -g

.SUFFIXES:

TESTBENCH_SRCS := pkg_axis_testbench_io.vhdl \
                  axis_checker.vhdl \
                  axis_generator.vhdl \
                  testbench.vhdl \
                  testbench_test_dummy.vhdl

.PHONY: all

all: testbench

testbench: ${TESTBENCH_SRCS}
	${GHDL} -i ${GHDLFLAGS} --work=axis_testbench ${TESTBENCH_SRCS}
	${GHDL} -m ${GHDLFLAGS} --work=axis_testbench -o testbench testbench

.PHONY: clean
clean:
	rm -f ${TESTBENCH_SRCS:.vhdl=.o} testbench.o e~testbench.o axis_testbench-obj08.cf testbench testbench.ghw html

.PHONY: run
run testbench.ghw: testbench cases/*
	./run_tests.py

.PHONY: wave
wave: testbench.ghw
	gtkwave testbench.ghw --save waveform.gtkw

.PHONY: html
html:
	doxygen
