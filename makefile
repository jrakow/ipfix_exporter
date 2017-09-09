GHDL := ghdl
GHDLFLAGS := --std=08 -g

.SUFFIXES:

TESTBENCH_SRCS := \
                  axis_checker.vhdl          \
                  axis_generator.vhdl        \
                  cpu_emulator.vhdl          \
                  module_wrapper.vhdl        \
                  pkg_axis_testbench_io.vhdl \
                  testbench.vhdl             \
                  testbench_test_dummy.vhdl

.PHONY: all

all: testbench

testbench: ${TESTBENCH_SRCS}
	${GHDL} -i ${GHDLFLAGS} --work=axis_testbench ${TESTBENCH_SRCS}
	${GHDL} -m ${GHDLFLAGS} --work=axis_testbench -Wc,-fprofile-arcs -Wc,-ftest-coverage -Wc,-fprofile-dir=. -Wl,-lgcov -o testbench testbench
# gcno are generated as side effect of compiling
# empty rule
%.gcno: testbench ;

.PHONY: clean
clean:
	rm -rf \
	       ${TESTBENCH_SRCS:.vhdl=.o} \
	       ${TESTBENCH_SRCS:.vhdl=.vhdl.gcov} \
	       ${TESTBENCH_SRCS:.vhdl=.gcno} \
	       ${TESTBENCH_SRCS:.vhdl=.gcda} \
	       coverage \
	       coverage.info \
	       testbench.o \
	       e~testbench.o \
	       e~testbench.gcno \
	       e~testbench.gcda \
	       axis_testbench-obj08.cf \
	       testbench \
	       waveforms/*/*.ghw \
	       html

# use testbench.gcda as dummy for all run results
# empty rule
%.gcda : testbench.gcda ;

.PHONY: run
junit.xml testbench.gcda run: testbench cases/*
	./run_tests.py all

html:
	doxygen 2>&1 | sed '/.*Elaborating.*/d' | sed '/^$$/d'

%.vhdl.gcov: %.gcda %.gcno testbench.gcda
	gcov $<

report.html: junit.xml
	xsltproc junit2html.xsl junit.xml > report.html

.PHONY: report
report: junit.xml
	xsltproc junit2txt.xsl junit.xml

# removing needed because e~testbench is not a source file
coverage.info: ${TESTBENCH_SRCS:.vhdl=.vhdl.gcov}
	rm -f e~testbench.gcno e~testbench.gcda
	lcov -d . --capture --output-file $@

coverage: coverage.info
	genhtml $< -o $@
