PROTOBUF_CXXFLAGS=$(shell pkg-config protobuf --cflags)
PROTOBUF_LDFLAGS=$(shell pkg-config protobuf --libs-only-L) -lprotobuf-lite
CXXFLAGS := $(CXXFLAGS) # inherit from env
LDFLAGS := $(LDFLAGS) # inherit from env

all: mem.node index_pb2.py src/index.pb.cc

index_pb2.py: index.proto
	protoc -I./ --python_out=. ./index.proto

src/index.pb.cc: index.proto
	protoc -I./ --cpp_out=./src ./index.proto

mem.node:
	`npm explore npm -g -- pwd`/bin/node-gyp-bin/node-gyp build

clean:
	@rm -f ./index_pb2.py
	@rm -rf ./build
	rm -f lib/mem.node

rebuild:
	@make clean
	@./configure
	@make

test:
	export NODE_PATH=./lib && npm test

check: test

.PHONY: test
