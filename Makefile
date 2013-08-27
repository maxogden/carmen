PROTOBUF_CXXFLAGS=$(shell pkg-config protobuf --cflags)
PROTOBUF_LDFLAGS=$(shell pkg-config protobuf --libs-only-L) -lprotobuf-lite
CXXFLAGS := $(CXXFLAGS) # inherit from env
LDFLAGS := $(LDFLAGS) # inherit from env

all: index_pb2.py src/index.pb.cc src/index.capnp.c++ src/flat-array.capnp.c++ mem.node convert vector 

src/index.capnp.c++: index.capnp Makefile
	capnp compile -oc++:src index.capnp

src/flat-array.capnp.c++: flat-array.capnp Makefile
	capnp compile -oc++:src flat-array.capnp

convert: convert.c++ Makefile
	$(HOME)/clang-3.2/bin/clang++ -I/Users/dane/projects/node/deps/v8/include \
	  /Users/dane/projects/node/out/Release/libv8_base.x64.a \
	  /Users/dane/projects/node/out/Release/libv8_nosnapshot.x64.a \
	  -std=gnu++11 -stdlib=libc++ -Wall -O3 -DDEBUG convert.c++ src/index.capnp.c++ -lkj -lcapnp -o convert

index_pb2.py: index.proto Makefile
	protoc -I./ --python_out=. ./index.proto

dump:
	cat test/fixtures/grid.0.packed | capnp decode index.capnp Message -p > test/fixtures/grid.0.packed.dump
	cat test/fixtures/grid.1.packed | capnp decode index.capnp Message -p > test/fixtures/grid.1.packed.dump
	cat test/fixtures/grid.2.packed | capnp decode index.capnp Message -p > test/fixtures/grid.2.packed.dump

src/index.pb.cc: index.proto Makefile
	protoc -I./ --cpp_out=./src ./index.proto

vector: vector.c++ Makefile
	$(HOME)/clang-3.2/bin/clang++ -std=gnu++11 -stdlib=libc++ -Wall -O3 -DDEBUG vector.c++ src/flat-array.capnp.c++ -lkj -lcapnp -o vector

mem.node:
	export CXX=$(HOME)/clang-3.2/bin/clang++ && `npm explore npm -g -- pwd`/bin/node-gyp-bin/node-gyp build --verbose

clean:
	@rm -f ./index_pb2.py
	@rm -f src/index.capnp.c++
	@rm -f src/index.capnp.h
	@rm -f src/index.pb.cc
	@rm -f src/index.pb.h
	@rm -rf ./build
	@rm -f lib/mem.node

rebuild:
	@make clean
	@./configure
	@make

test:
	./node_modules/.bin/mocha test/cache.test.js

check: test

.PHONY: test
