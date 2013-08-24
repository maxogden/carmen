PROTOBUF_CXXFLAGS=$(shell pkg-config protobuf --cflags)
PROTOBUF_LDFLAGS=$(shell pkg-config protobuf --libs-only-L) -lprotobuf-lite
CXXFLAGS := $(CXXFLAGS) # inherit from env
LDFLAGS := $(LDFLAGS) # inherit from env

all: mem.node index_pb2.py src/index.pb.cc src/index.capnp.c++ convert

src/index.capnp.c++: index.capnp Makefile
	capnp compile -oc++:src index.capnp

convert: convert.c++ Makefile
	$(HOME)/clang-3.2/bin/clang++ -I/Users/dane/projects/node/deps/v8/include \
	  /Users/dane/projects/node/out/Release/libv8_base.x64.a \
	  /Users/dane/projects/node/out/Release/libv8_nosnapshot.x64.a \
	  -std=gnu++11 -stdlib=libc++ -Wall -O3 -DDEBUG convert.c++ src/index.capnp.c++ -lkj -lcapnp -o convert
	./convert write | ./convert read

index_pb2.py: index.proto Makefile
	protoc -I./ --python_out=. ./index.proto

src/index.pb.cc: index.proto Makefile
	protoc -I./ --cpp_out=./src ./index.proto

mem.node:
	export CXX=$(HOME)/clang-3.2/bin/clang++ && `npm explore npm -g -- pwd`/bin/node-gyp-bin/node-gyp build

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
	export NODE_PATH=./lib && npm test

check: test

.PHONY: test
