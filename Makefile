# File:   Makefile
# Author: breno
# Email:  breno@Manjaro
# Date:   Thu 18 Feb 2021 05:15:42 PM WET

EXECUTABLES = pip virtualenv python3
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),,$(error "No $(exec) in PATH")))

MAKEFGLAGS     += --no-builtin-rules
MAKEFGLAGS     += --print-directory
.SHELL         := /bin/bash
.SHELLFLAGS    := -eu -o pipefail -o posix -c
.ONESHELL:
.PHONY:        doc clean help
.DEFAULT_GOAL: doc

doc: | vimdoc/env/bin/vimdoc
	source ./vimdoc/env/bin/activate
	vimdoc ./

vimdoc/env/bin/vimdoc: | vimdoc/env
	cd vimdoc
	source ./env/bin/activate
	python setup.py config
	python setup.py build
	python setup.py install

vimdoc/env: | vimdoc
	virtualenv vimdoc/env

vimdoc:
	git clone https://github.com/google/vimdoc

clean:
	rm -rf vimdoc

help:
	@echo "make doc"
	@echo "	generate the docs for the plugin"
	@echo "make clean"
	@echo "	remove vimdoc & virtualenv"
