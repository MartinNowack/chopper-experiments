## Framework-wide configuration
##
## NOTE:  this file will be included by the specific makefiles
##
## The only thing that we assume here is that the specific makefile
## defines the ROOT directory of the experimentation framework, which
## is the directory where this file resides.


##
## ROOT PATHS
##
TOOLS=$(ROOT)/tools


##
## CONFIGURATIONS
##
default: all


##
## OTHER COMMANDS
##
UNAME:=$(shell uname)
SHELL:=/bin/bash
GIT:=git


##
## LLVM
##
LLVM_CONFIG:=llvm-config
CLANG:=clang
CLANGXX:=clang++
LLVM_COMPILER:=$(CLANG)
OPT:=opt
LINK=llvm-link
DIS=llvm-dis


##
## WLLVM
##
WLLVMROOT=$(TOOLS)/whole-program-llvm
WLLVM=$(WLLVMROOT)/wllvm
EXTRACTBC=$(WLLVMROOT)/extract-bc

$(WLLVMROOT):
	$(GIT) clone https://github.com/travitch/whole-program-llvm $(WLLVMROOT)
	cd $(WLLVMROOT); git checkout 3da8960dff43554ecf86e6b970d9862b1d3f9690

$(WLLVM): $(WLLVMROOT)
$(EXTRACTBC): $(WLLVMROOT)


##
## KLEE
##
KLEE_UCLIBC_DIR=$(TOOLS)/klee-uclibc

STP_DIR=$(TOOLS)/stp
STP=$(STP_DIR)/build/stp
MINISAT_DIR=$(TOOLS)/minisat
MINISAT=$(MINISAT_DIR)/build/libminisat.so

KLEE_DIR=~/tau/slicing/klee/
KLEE_BUILD_DIR=
KLEE_BIN=$(KLEE_BUILD_DIR)/bin
KLEE=$(KLEE_BIN)/klee

$(STP): $(STP_DIR) $(MINISAT)
	-test -d $(STP_DIR)/build || mkdir -p $(STP_DIR)/build; \
	cd $(STP_DIR)/build; \
	cmake -DMINISAT_LIBDIR=$(dir $(MINISAT)) -DBUILD_SHARED_LIBS:BOOL=OFF -DENABLE_PYTHON_INTERFACE:BOOL=OFF ..; \
	make

$(STP_DIR):
	-test -d $@ || git clone https://github.com/stp/stp.git $@
	cd $@; \
	git checkout tags/2.1.2

$(MINISAT): $(MINISAT_DIR)
	-test -d $(MINISAT_DIR)/build || mkdir -p $(MINISAT_DIR)/build; \
	cd $(MINISAT_DIR)/build; \
	cmake ..; \
	make

$(MINISAT_DIR):
	-test -d $@ || git clone https://github.com/stp/minisat.git $@


###
### EXPERIMENT CONFIGURATION
###
KTIMEOUT:=4000.
KINSTRTIMEOUT:=200.
KSLICE=
KFLAGS=--simplify-sym-indices \
--output-module \
--max-memory=4095 \
--allocate-determ=true \
--allocate-determ-size=4095 \
--allocate-determ-start-address=0x7ffef66f3000 \
--max-sym-array-size=4096 \
--disable-inlining \
--optimize \
--use-forked-solver \
--use-cex-cache \
--libc=klee \
--posix-runtime \
--allow-external-sym-calls \
--only-output-states-covering-new \
--watchdog \
--max-memory-inhibit=false \
--use-query-log=solver:kquery \
--max-static-fork-pct=1 \
--max-static-solve-pct=1 \
--max-static-cpfork-pct=1 \
--switch-type=internal \
--dump-states-on-halt=false \
--debug-print-instructions=$(KINSTRFORMAT) \
--debug-compress-instructions \
--compress-query-log \
--environ=/tmp/test.env \
--run-in=/tmp/sandbox \
--max-instruction-time=$(KINSTRTIMEOUT) \
--max-solver-time=$(KINSTRTIMEOUT) \
--max-time=$(KTIMEOUT) \
--search=$(KSEARCH) \
$(KSLICE)


###
### COMMON TARGETS
###
.PHONY: prepare
## Create both the enviroment file and the sandbox directory
prepare: $(ROOT)/case_studies/testing-env.sh $(ROOT)/case_studies/sandbox.tgz
	-rm -rf /tmp/* > /dev/null 2>&1
	cd $(ROOT)/case_studies; \
	env -i /bin/bash -c '(source testing-env.sh; env >test.env)'; \
	mv test.env /tmp/test.env; \
	tar xzf sandbox.tgz; \
	mv sandbox /tmp

$(ROOT)/case_studies/sandbox.tgz:
	cd  $(ROOT)/case_studies; wget -q http://www.doc.ic.ac.uk/~cristic/klee/sandbox.tgz
