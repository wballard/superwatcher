DIFF ?= git --no-pager diff --ignore-all-space --color-words --no-index
CURL ?= curl --silent

.PHONY: test

test: 
	$(MAKE)	works_with_sockets

works_with_sockets:
	echo "test('localhost', 8080, '/echo', {'a': 'b'}, ['arg1', 'arg2'])" \
	| ./bin/poke \
	| tee /tmp/$@
	$(DIFF) /tmp/$@ test/expected/$@

environment:
	./bin/superforker init environment "git://github.com/wballard/superforker.environment.git"
	./bin/superforker init handlers "git://github.com/wballard/superforker.handlers.git"

start:
	./bin/superforker init
	./bin/superforker start

stop:
	./bin/superforker stop

