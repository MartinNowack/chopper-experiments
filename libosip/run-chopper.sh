#!/bin/bash

KLEE=autoklee -use-pta-mode=static

ulimit -s unlimited

$KLEE \
    -max-time=3600 \
    -max-memory=4096 \
    -simplify-sym-indices \
    -libc=uclibc \
    -search=nurs:covnew \
    -skip-functions=osip_util_replace_all_lws,osip_clrncpy:81  \
    -split-search \
    -inline=memmove \
    ./test-driver.bc 10
