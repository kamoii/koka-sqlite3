
VCPKG_ROOT := ./vcpkg

vcpkg.init:
	git clone https://github.com/Microsoft/vcpkg.git $(VCPKG_ROOT)
	$(VCPKG_ROOT)/bootstrap-vcpkg.sh

vcpkg.install:
	$(VCPKG_ROOT)/vcpkg install sqlite3

test:
	koka --vcpkg=$(VCPKG_ROOT) --outputdir=./.out --include=./src -e test/main.kk

.PHONY: test
