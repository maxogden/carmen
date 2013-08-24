// v8
#include <v8.h>

// node
#include <node.h>
#include <node_version.h>
#include <node_object_wrap.h>
#include <node_buffer.h>

// stl
#include <iostream>
#include <exception>
#include <string>

#include "pbf.hpp"
#include "index.capnp.h"
#include <capnp/message.h>
#include <capnp/serialize-packed.h>

// https://github.com/jasondelponte/go-v8/blob/master/src/v8context.cc#L41
// http://v8.googlecode.com/svn/trunk/test/cctest/test-threads.cc

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h> 

namespace node_mem {

using namespace v8;

class Engine: public node::ObjectWrap {
public:
    static Persistent<FunctionTemplate> constructor;
    static void Initialize(Handle<Object> target);
    static Handle<Value> New(Arguments const& args);
    //static Handle<Value> add(Arguments const& args);
    static Handle<Value> parseProto(Arguments const& args);
    static Handle<Value> parseCapnProto(Arguments const& args);
    static void AsyncRun(uv_work_t* req);
    static void AfterRun(uv_work_t* req);
    Engine();
    void _ref() { Ref(); }
    void _unref() { Unref(); }
private:
    ~Engine();
};

Persistent<FunctionTemplate> Engine::constructor;

void Engine::Initialize(Handle<Object> target) {
    HandleScope scope;
    constructor = Persistent<FunctionTemplate>::New(FunctionTemplate::New(Engine::New));
    constructor->InstanceTemplate()->SetInternalFieldCount(1);
    constructor->SetClassName(String::NewSymbol("Engine"));
    //NODE_SET_PROTOTYPE_METHOD(constructor, "add", add);
    NODE_SET_PROTOTYPE_METHOD(constructor, "parseProto", parseProto);
    NODE_SET_PROTOTYPE_METHOD(constructor, "parseCapnProto", parseCapnProto);
    target->Set(String::NewSymbol("Engine"),constructor->GetFunction());
}

Engine::Engine()
  : ObjectWrap()
    { }

Engine::~Engine() { }

Handle<Value> Engine::New(Arguments const& args)
{
    HandleScope scope;
    if (!args.IsConstructCall()) {
        return ThrowException(String::New("Cannot call constructor as function, you need to use 'new' keyword"));
    }
    try {
        Engine* im = new Engine();
        im->Wrap(args.This());
        return args.This();
    } catch (std::exception const& ex) {
        return ThrowException(String::New(ex.what()));
    }
    return Undefined();
}

namespace capnp {
class TestPipe: public kj::BufferedInputStream, public kj::OutputStream {
public:
  TestPipe()
      : preferredReadSize(std::numeric_limits<size_t>::max()), readPos(0) {}
  explicit TestPipe(size_t preferredReadSize)
      : preferredReadSize(preferredReadSize), readPos(0) {}
  ~TestPipe() {}

  const std::string& getData() { return data; }
  void resetRead(size_t preferredReadSize = std::numeric_limits<size_t>::max()) {
    readPos = 0;
    this->preferredReadSize = preferredReadSize;
  }

  bool allRead() {
    return readPos == data.size();
  }

  void clear(size_t preferredReadSize = std::numeric_limits<size_t>::max()) {
    resetRead(preferredReadSize);
    data.clear();
  }

  void write(const void* buffer, size_t size) override {
    data.append(reinterpret_cast<const char*>(buffer), size);
  }

  size_t tryRead(void* buffer, size_t minBytes, size_t maxBytes) override {
    //KJ_ASSERT(maxBytes <= data.size() - readPos, "Overran end of stream.");
    size_t amount = std::min(maxBytes, std::max(minBytes, preferredReadSize));
    memcpy(buffer, data.data() + readPos, amount);
    readPos += amount;
    return amount;
  }

  void skip(size_t bytes) override {
    //KJ_ASSERT(bytes <= data.size() - readPos, "Overran end of stream.");
    readPos += bytes;
  }

  kj::ArrayPtr<const kj::byte> tryGetReadBuffer() override {
    size_t amount = std::min(data.size() - readPos, preferredReadSize);
    return kj::arrayPtr(reinterpret_cast<const kj::byte*>(data.data() + readPos), amount);
  }

private:
  size_t preferredReadSize;
  std::string data;
  std::string::size_type readPos;
};
}

Handle<Value> Engine::parseCapnProto(Arguments const& args)
{
    HandleScope scope;
    if (args.Length() < 1) {
        ThrowException(String::New("first argument must be a buffer"));
    }

    if (!args[0]->IsObject()) {
        return ThrowException(String::New("first argument must be a buffer"));
    }

    Local<Object> obj = args[0]->ToObject();
    if (obj->IsNull() || obj->IsUndefined()) {
        ThrowException(Exception::TypeError(String::New("a buffer expected for first argument")));
    }
    if (!node::Buffer::HasInstance(obj)) {
        return ThrowException(Exception::TypeError(String::New(
                                                       "first argument must be a buffer")));
    }
    Local<Object> json = Object::New();
    try {
        const char * cdata = node::Buffer::Data(obj);
        size_t size = node::Buffer::Length(obj);
/*
        ::kj::ArrayPtr<const ::kj::byte> arr_ptr(&cdata[0],size);
        ::kj::ArrayInputStream in(arr_ptr);
        ::capnp::ReaderOptions options;
        ::capnp::PackedMessageReader reader(in,options,nullptr);
*/
        ::node_mem::capnp::TestPipe pipe;
        pipe.write(cdata,size);
        ::capnp::PackedMessageReader reader(pipe);
        carmen::Message::Reader msg = reader.getRoot<carmen::Message>();
        auto items = msg.getItems();
        unsigned items_size = items.size();
        for (unsigned i=0;i<items_size;++i) {
            auto item = items[i];
            auto array = item.getArrays();
            unsigned array_size = array.size();
            Local<Array> arr_obj = Array::New(array_size);
            for (unsigned j=0;j<array_size;++j) {
                auto arr = array[0];
                auto vals = arr.getVal();
                unsigned vals_size = vals.size();
                Local<Array> vals_obj = Array::New(vals_size);
                for (unsigned k=0;k<vals_size;++k) {
                    vals_obj->Set(k,Number::New(vals[k]));
                }
                arr_obj->Set(j,vals_obj);
            }
            json->Set(String::New(item.getKey().cStr()),arr_obj);
        }
    } catch (std::exception const& ex) {
        return ThrowException(Exception::TypeError(String::New(ex.what())));
    }
    return scope.Close(json);
}

Handle<Value> Engine::parseProto(Arguments const& args)
{
    HandleScope scope;
    if (args.Length() < 1) {
        ThrowException(String::New("first argument must be a buffer"));
    }

    if (!args[0]->IsObject()) {
        return ThrowException(String::New("first argument must be a buffer"));
    }

    Local<Object> obj = args[0]->ToObject();
    if (obj->IsNull() || obj->IsUndefined()) {
        ThrowException(Exception::TypeError(String::New("a buffer expected for first argument")));
    }
    if (!node::Buffer::HasInstance(obj)) {
        return ThrowException(Exception::TypeError(String::New(
                                                       "first argument must be a buffer")));
    }
    Local<Object> json = Object::New();
    try {
        const char * cdata = node::Buffer::Data(obj);
        size_t size = node::Buffer::Length(obj);
        // @TODO - prevent crash on invalid data
        llmr::pbf message(cdata,size);
        while (message.next()) {
            if (message.tag == 1) {
                uint32_t bytes = message.varint();
                llmr::pbf item(message.data, bytes);
                Local<Array> val_array = Array::New();
                while (item.next()) {
                    if (item.tag == 1) {
                        uint32_t arrays_length = item.varint();
                        llmr::pbf array(item.data,arrays_length);
                        unsigned idx = 0;
                        while (array.next()) {
                            if (array.tag == 1) {
                                uint32_t vals_length = array.varint();
                                llmr::pbf val(array.data,vals_length);
                                unsigned vidx = 0;
                                Local<Array> v2 = Array::New();
                                while (val.next()) {
                                    v2->Set(vidx++,Number::New(val.value));
                                }
                                val_array->Set(idx++,v2);
                                array.skipBytes(vals_length);
                            } else {
                                throw std::runtime_error("skipping when shouldnt");
                                array.skip();
                            }
                        }
                        item.skipBytes(arrays_length);
                    } else if (item.tag == 2) {
                        int64_t val = item.varint();
                        json->Set(Number::New(val),val_array);
                    } else {
                        throw std::runtime_error("hit unknown type");
                    }
                }
                message.skipBytes(bytes);
            } else {
                throw std::runtime_error("skipping when shouldnt");
                message.skip();
            }    
        }
    } catch (std::exception const& ex) {
        return ThrowException(Exception::TypeError(String::New(ex.what())));
    }
    return scope.Close(json);
}

/*
typedef struct {
    uv_work_t request;
    Engine * machine;
    char *data;
    size_t dataLength;
    bool error;
    std::string result;
    Persistent<Function> cb;
} add_baton_t;

Handle<Value> Engine::add(Arguments const& args)
{
    HandleScope scope;

    return addSync(args);
    if (args.Length() == 1) {
        return addSync(args);
    }

    if (args.Length() < 1) {
        ThrowException(String::New("first argument must be a buffer"));
    }

    if (!args[0]->IsObject()) {
        return ThrowException(String::New("first argument must be a buffer"));
    }

    Local<Object> obj = args[0]->ToObject();
    if (obj->IsNull() || obj->IsUndefined()) {
        ThrowException(Exception::TypeError(String::New("a buffer expected for first argument")));
    }
    if (!node::Buffer::HasInstance(obj)) {
        return ThrowException(Exception::TypeError(String::New(
                                                       "first argument must be a buffer")));
    }

    // ensure callback is a function
    Local<Value> callback = args[args.Length()-1];
    if (!args[args.Length()-1]->IsFunction()) {
        return ThrowException(Exception::TypeError(
                                  String::New("last argument must be a callback function")));
    }

    Engine * machine = ObjectWrap::Unwrap<Engine>(args.This());
    add_baton_t *closure = new add_baton_t();
    closure->request.data = closure;
    closure->machine = machine;
    closure->data = node::Buffer::Data(obj);
    closure->dataLength = node::Buffer::Length(obj);
    closure->error = false;
    closure->cb = Persistent<Function>::New(Handle<Function>::Cast(callback));
    uv_queue_work(uv_default_loop(), &closure->request, AsyncRun, (uv_after_work_cb)AfterRun);
    closure->machine->_ref();
    return Undefined();
}


void Engine::AsyncRun(uv_work_t* req) {
    add_baton_t *closure = static_cast<add_baton_t *>(req->data);
    try {
        //closure->machine->this_->RunQuery(*(closure->query->get()), osrm_reply);
        //closure->result = osrm_reply.content;
    } catch(std::exception const& ex) {
        closure->error = true;
        closure->result = ex.what();
    }
}

void Engine::AfterRun(uv_work_t* req) {
    HandleScope scope;
    add_baton_t *closure = static_cast<add_baton_t *>(req->data);
    TryCatch try_catch;
    if (closure->error) {
        Local<Value> argv[1] = { Exception::Error(String::New(closure->result.c_str())) };
        closure->cb->Call(Context::GetCurrent()->Global(), 1, argv);
    } else {
        Local<Value> argv[2] = { Local<Value>::New(Null()),
                                 String::New(closure->result.c_str()) };
        closure->cb->Call(Context::GetCurrent()->Global(), 2, argv);
    }
    if (try_catch.HasCaught()) {
        node::FatalException(try_catch);
    }
    closure->machine->_unref();
    closure->cb.Dispose();
    delete closure;
}
*/

extern "C" {
    static void start(Handle<Object> target) {
        Engine::Initialize(target);
    }
}

} // namespace node_mem

NODE_MODULE(mem, node_mem::start)
