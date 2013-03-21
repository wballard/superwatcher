DIFF ?= git --no-pager diff --ignore-all-space --color-words --no-index
CURL ?= curl --silent

.PHONY: test

test: 
	$(MAKE)	works_at_all


works_at_all:
	$(CURL) http://localhost:8080/test/handlers/echo > test/$@.tmp
	$(DIFF) test/$@.tmp test/$@.expected


