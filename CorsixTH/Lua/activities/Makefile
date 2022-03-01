.phony: build view run check

build:
	asciidoctor -b html -d book commands.asciidoc

view: build
	firefox commands.html

run:
	../run

check:
	cd ../../.. ; ./run_lua_check.sh
