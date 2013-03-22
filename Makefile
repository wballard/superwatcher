DIFF ?= git --no-pager diff --ignore-all-space --color-words --no-index
CURL ?= curl --silent

.PHONY: test

test: 
	$(MAKE)	works_at_all works_with_switches works_with_sockets

works_at_all:
	$(CURL) "http://localhost:8080/test/handlers/echo" > test/$@.tmp
	$(DIFF) test/$@.tmp test/$@.expected

works_with_switches:
	$(CURL) "http://localhost:8080/test/handlers/echo?pantalones=conqueso&smurfs=hat&pantalones=diablo" > test/$@.tmp
	$(DIFF) test/$@.tmp test/$@.expected

works_with_sockets:
	echo "test('localhost', 8080, '/test/handlers/echo', {'a': 'b'})" \
	| ./bin/superforker.coffee poke \
	> test/$@.tmp
	$(DIFF) test/$@.tmp test/$@.expected

start:
	./bin/start

stop:
	./bin/stop

