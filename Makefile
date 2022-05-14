
VCPKG_ROOT := ./vcpkg

vcpkg.init:
	git clone https://github.com/Microsoft/vcpkg.git $(VCPKG_ROOT)
	$(VCPKG_ROOT)/bootstrap-vcpkg.sh

vcpkg.install:
	$(VCPKG_ROOT)/vcpkg install sqlite3

test:
	# koka doesn't sqlite-inline.c change
	# https://github.com/koka-lang/koka/issues/268
	# for workaround, touch sqlite3.kk and always recompile sqlite3.kk and sqlite3-inline.c
	touch src/db/sqlite3.kk
	koka --vcpkg=$(VCPKG_ROOT) --outputdir=./.out --include=./src -e test/main.kk

.PHONY: test
