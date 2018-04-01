GHDL ?= ghdl
GHDLFLAGS ?= --std=08 -g

.SUFFIXES:

AXIS_TESTBENCH_SRCS := \
	axis_testbench/src/axis_checker.vhdl \
	axis_testbench/src/axis_generator.vhdl \
	axis_testbench/src/cpu_emulator.vhdl \
	axis_testbench/src/module_wrapper.vhdl \
	axis_testbench/src/pkg_axis_testbench_io.vhdl \
	axis_testbench/src/testbench.vhdl \
	axis_testbench/src/testbench_test_dummy.vhdl

.PHONY: all
all: build/axis_testbench

.PHONY: clean
clean:
	rm -rf build/ coverage/ waveforms report.html
	make -C axis_testbench clean

## directories
build:
	mkdir $@
waveforms:
	mkdir $@

## compilation
.ONESHELL:
build/axis_testbench-obj08.cf: ${AXIS_TESTBENCH_SRCS} | build
	cd build
	${GHDL} -i ${GHDLFLAGS} --work=axis_testbench $(addprefix ../,${AXIS_TESTBENCH_SRCS})

.ONESHELL:
build/axis_testbench: build/axis_testbench-obj08.cf ${AXIS_TESTBENCH_SRCS} | build
	cd build
	${GHDL} -m ${GHDLFLAGS} --work=axis_testbench \
		-Wc,-fprofile-arcs -Wc,-ftest-coverage -Wl,-lgcov \
		-o axis_testbench testbench

## execution
.PHONY: run
.ONESHELL:
build/junit.xml run: build/axis_testbench tests/* | build waveforms
	cd build/
	../axis_testbench/src/run_tests.py all

## test reports
.PHONY: report
report: build/junit.xml
	xsltproc axis_testbench/src/junit2txt.xsl build/junit.xml

report.html: build/junit.xml
	xsltproc axis_testbench/src/junit2html.xsl build/junit.xml > report.html

## coverage
# gcno are generated as side effect of compiling
build/%.gcno: build/axis_testbench ;

# gcda are generated as side effect of running
# use junit.xml as dummy for all run results
build/%.gcda : build/junit.xml ;

.ONESHELL:
build/%.vhdl.gcov: build/%.gcda build/%.gcno build/junit.xml
	cd build
	gcov $<

# removing needed because e~testbench is not a source file
.ONESHELL:
build/coverage.info: $(addprefix build/,$(notdir ${AXIS_TESTBENCH_SRCS:.vhdl=.vhdl.gcov}))
	cd build/
	rm -f e~testbench.gcno e~axis_testbench.gcda
	lcov -d . --capture --output-file $(notdir $@)

coverage: build/coverage.info
	genhtml $< -o $@
