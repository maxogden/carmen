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
#include "nan.h"
#include "index.capnp.h"
#include <capnp/message.h>
#include <capnp/serialize-packed.h>
#include "capnproto_helper.hpp"

// https://github.com/jasondelponte/go-v8/blob/master/src/v8context.cc#L41
// http://v8.googlecode.com/svn/trunk/test/cctest/test-threads.cc

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <map>
#include <vector>

namespace node_mem {

using namespace v8;

typedef std::vector<std::vector<uint64_t>> varray;
typedef std::map<uint64_t,varray> arraycache;
typedef arraycache::const_iterator arr_iterator;
typedef std::map<std::string,arraycache> memcache;
typedef memcache::const_iterator mem_iterator_type;

class Cache: public node::ObjectWrap {
public:
    static Persistent<FunctionTemplate> constructor;
    static void Initialize(Handle<Object> target);
    static NAN_METHOD(New);
    static NAN_METHOD(parseProto);
    static NAN_METHOD(parseCapnProto);
    static NAN_METHOD(has);
    static NAN_METHOD(load);
    static NAN_METHOD(loadJSON);
    static NAN_METHOD(search);
    static NAN_METHOD(pack);
    static NAN_METHOD(list);
    static NAN_METHOD(set);
    static void AsyncRun(uv_work_t* req);
    static void AfterRun(uv_work_t* req);
    Cache(std::string const& id,int shardlevel);
    void _ref() { Ref(); }
    void _unref() { Unref(); }
private:
    ~Cache();
    std::string id_;
    int shardlevel_;
    memcache cache_;
};

Persistent<FunctionTemplate> Cache::constructor;

void Cache::Initialize(Handle<Object> target) {
    NanScope();
    Local<FunctionTemplate> t = FunctionTemplate::New(Cache::New);
    t->InstanceTemplate()->SetInternalFieldCount(1);
    t->SetClassName(String::NewSymbol("Cache"));
    NODE_SET_PROTOTYPE_METHOD(t, "parseProto", parseProto);
    NODE_SET_PROTOTYPE_METHOD(t, "parseCapnProto", parseCapnProto);
    NODE_SET_PROTOTYPE_METHOD(t, "has", has);
    NODE_SET_PROTOTYPE_METHOD(t, "load", load);
    NODE_SET_PROTOTYPE_METHOD(t, "loadJSON", loadJSON);
    NODE_SET_PROTOTYPE_METHOD(t, "search", search);
    NODE_SET_PROTOTYPE_METHOD(t, "pack", pack);
    NODE_SET_PROTOTYPE_METHOD(t, "list", list);
    NODE_SET_PROTOTYPE_METHOD(t, "_set", set);
    target->Set(String::NewSymbol("Cache"),t->GetFunction());
    NanAssignPersistent(FunctionTemplate, constructor, t);
}

Cache::Cache(std::string const& id, int shardlevel)
  : ObjectWrap(),
    id_(id),
    shardlevel_(shardlevel),
    cache_()
    { }

Cache::~Cache() { }

NAN_METHOD(Cache::pack)
{
    NanScope();
    if (args.Length() < 2) {
        return NanThrowTypeError("expected three args: 'type','shard','encoding'");
    }
    if (!args[0]->IsString()) {
        return NanThrowTypeError("first argument must be a string");
    }
    if (!args[1]->IsNumber()) {
        return NanThrowTypeError("second arg must be an integer");
    }
    std::string encoding("protobuf");
    if (args.Length() > 2) {
        if (!args[2]->IsString()) {
            return NanThrowTypeError("third arg must be a string");
        }
        encoding = *String::Utf8Value(args[2]->ToString());
    }
    NanReturnValue(Undefined());
}

NAN_METHOD(Cache::list)
{
    NanScope();
    if (args.Length() < 1) {
        return NanThrowTypeError("expected at least one arg: 'type' + optional 'shard'");
    }
    if (!args[0]->IsString()) {
        return NanThrowTypeError("first argument must be a string");
    }
    try {
        std::string type = *String::Utf8Value(args[0]->ToString());
        Cache* c = node::ObjectWrap::Unwrap<Cache>(args.This());
        memcache & mem = c->cache_;
        Local<Array> ids = Array::New();
        if (args.Length() == 1) {
            mem_iterator_type itr = mem.begin();
            mem_iterator_type end = mem.end();
            unsigned idx = 0;
            while (itr != end) {
                if (itr->first.size() > type.size() && itr->first.substr(0,type.size()) == type) {
                    std::string shard = itr->first.substr(type.size()+1,itr->first.size());
                    ids->Set(idx++,Number::New(String::New(shard.c_str())->NumberValue()));
                }
                ++itr;
            }
            NanReturnValue(ids);
        } else if (args.Length() == 2) {
            std::string shard = *String::Utf8Value(args[1]->ToString());
            std::string key = type + "-" + shard;
            mem_iterator_type itr = mem.find(key);
            if (itr != mem.end()) {
                arr_iterator aitr = itr->second.begin();
                arr_iterator aend = itr->second.end();
                unsigned idx = 0;
                while (aitr != aend) {
                    ids->Set(idx++,Number::New(aitr->first)->ToString());
                    ++aitr;
                }
                NanReturnValue(ids);
            }
        }
    } catch (std::exception const& ex) {
        return NanThrowTypeError(ex.what());
    }
    NanReturnValue(Undefined());
}

NAN_METHOD(Cache::set)
{
    NanScope();
    if (args.Length() < 3) {
        return NanThrowTypeError("expected three args: 'type','shard','id','data'");
    }
    if (!args[0]->IsString()) {
        return NanThrowTypeError("first argument must be a string");
    }
    if (!args[1]->IsNumber()) {
        return NanThrowTypeError("second arg must be an integer");
    }
    if (!args[2]->IsNumber()) {
        return NanThrowTypeError("third arg must be an integer");
    }
    if (!args[3]->IsArray()) {
        return NanThrowTypeError("fourth arg must be an array");
    }
    Local<Array> data = Local<Array>::Cast(args[3]);
    if (data->IsNull() || data->IsUndefined()) {
        return NanThrowTypeError("an array expected for third argument");
    }
    try {
        std::string type = *String::Utf8Value(args[0]->ToString());
        std::string shard = *String::Utf8Value(args[1]->ToString());
        std::string key = type + "-" + shard;
        Cache* c = node::ObjectWrap::Unwrap<Cache>(args.This());
        memcache & mem = c->cache_;
        // TODO - what if already exists?
        c->cache_.emplace(key,arraycache());
        arraycache & arrc = c->cache_[key];
        uint64_t key_id = args[2]->NumberValue();
        // TODO - what if already exists?
        arrc.emplace(key_id,varray());
        varray & vv = arrc[key_id];
        unsigned array_size = data->Length();
        if (type == "grid") {
            vv.reserve(array_size);
            for (unsigned i=0;i<array_size;++i) {
                vv.emplace_back(std::vector<uint64_t>());
                std::vector<uint64_t> & vvals = vv.back();
                Local<Array> subarray = Local<Array>::Cast(data->Get(i));
                unsigned vals_size = subarray->Length();
                vvals.reserve(vals_size);
                for (unsigned k=0;k<vals_size;++k) {
                    vvals.emplace_back(subarray->Get(k)->NumberValue());
                }
            }
        } else {
            vv.reserve(1);
            vv.emplace_back(std::vector<uint64_t>());
            std::vector<uint64_t> & vvals = vv.back();
            for (unsigned i=0;i<array_size;++i) {
                vvals.emplace_back(data->Get(i)->NumberValue());
            }
        }
    } catch (std::exception const& ex) {
        return NanThrowTypeError(ex.what());
    }
    NanReturnValue(Undefined());
}

NAN_METHOD(Cache::loadJSON)
{
    NanScope();
    if (args.Length() < 3) {
        return NanThrowTypeError("expected four args: 'object','type','shard'");
    }
    if (!args[0]->IsObject()) {
        return NanThrowTypeError("first argument must be an object");
    }
    Local<Object> obj = args[0]->ToObject();
    if (obj->IsNull() || obj->IsUndefined()) {
        return NanThrowTypeError("a valid object expected for first argument");
    }
    if (!args[1]->IsString()) {
        return NanThrowTypeError("second arg 'type' must be a string");
    }
    if (!args[2]->IsNumber()) {
        return NanThrowTypeError("third arg 'shard' must be an Integer");
    }
    try {
        Cache* c = node::ObjectWrap::Unwrap<Cache>(args.This());
        memcache & mem = c->cache_;
        std::string type = *String::Utf8Value(args[1]->ToString());
        std::string shard = *String::Utf8Value(args[2]->ToString());
        std::string key = type + "-" + shard;
        c->cache_.emplace(key,arraycache());
        arraycache & arrc = c->cache_[key];
        v8::Local<v8::Array> propertyNames = obj->GetPropertyNames();
        uint32_t prop_len = propertyNames->Length();
        for (int i=0;i < prop_len;++i) {
            v8::Local<v8::Value> key = propertyNames->Get(i);
            v8::Local<v8::Value> prop = obj->Get(key);
            if (prop->IsArray()) {
                uint64_t key_id = key->NumberValue();
                arrc.emplace(key_id,varray());
                varray & vv = arrc[key_id];
                v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast(prop);
                if (type == "grid") {
                    uint32_t arr_len = arr->Length();
                    vv.reserve(arr_len);
                    for (int j=0;j < arr_len;++j) {
                        v8::Local<v8::Value> val_array = arr->Get(j);
                        if (val_array->IsArray()) {
                            vv.emplace_back(std::vector<uint64_t>());
                            std::vector<uint64_t> & vvals = vv.back();
                            v8::Local<v8::Array> vals = v8::Local<v8::Array>::Cast(val_array);
                            uint32_t val_len = vals->Length();
                            vvals.reserve(val_len);
                            for (int k=0;k < val_len;++k) {
                                vvals.emplace_back(vals->Get(k)->NumberValue());
                            }
                        }
                    }
                } else {
                    uint32_t arr_len = arr->Length();
                    vv.reserve(1);
                    vv.emplace_back(std::vector<uint64_t>());
                    std::vector<uint64_t> & vvals = vv.back();
                    vvals.reserve(arr_len);
                    for (int j=0;j < arr_len;++j) {
                        v8::Local<v8::Value> val = arr->Get(j);
                        if (val->IsNumber()) {
                            vvals.emplace_back(val->NumberValue());
                        }
                    }
                }
            }
        }
    } catch (std::exception const& ex) {
        return NanThrowTypeError(ex.what());
    }
    NanReturnValue(Undefined());
}

NAN_METHOD(Cache::load)
{
    NanScope();
    if (args.Length() < 3) {
        return NanThrowTypeError("expected four args: 'buffer','type','shard','encoding'");
    }
    if (!args[0]->IsObject()) {
        return NanThrowTypeError("first argument must be a buffer");
    }
    Local<Object> obj = args[0]->ToObject();
    if (obj->IsNull() || obj->IsUndefined()) {
        return NanThrowTypeError("a buffer expected for first argument");
    }
    if (!node::Buffer::HasInstance(obj)) {
        return NanThrowTypeError("first argument must be a buffer");
    }
    if (!args[1]->IsString()) {
        return NanThrowTypeError("second arg 'type' must be a string");
    }
    if (!args[2]->IsNumber()) {
        return NanThrowTypeError("third arg 'shard' must be an Integer");
    }
    try {
        std::string encoding("capnp");
        if (args.Length() > 3) {
            if (!args[3]->IsString()) {
                return NanThrowTypeError("third arg must be a string");
            }
            encoding = *String::Utf8Value(args[2]->ToString());
        }
        Cache* c = node::ObjectWrap::Unwrap<Cache>(args.This());
        memcache & mem = c->cache_;
        const char * cdata = node::Buffer::Data(obj);
        size_t size = node::Buffer::Length(obj);
        std::string type = *String::Utf8Value(args[1]->ToString());
        std::string shard = *String::Utf8Value(args[2]->ToString());
        std::string key = type + "-" + shard;
        c->cache_.emplace(key,arraycache());
        arraycache & arrc = c->cache_[key];
        if (encoding == "capnp") {
            BufferStream pipe(cdata,size);
            ::capnp::PackedMessageReader reader(pipe);
            auto msg = reader.getRoot<carmen::Message>();
            auto items = msg.getItems();
            unsigned items_size = items.size();
            for (unsigned i=0;i<items_size;++i) {
                auto item = items[i];
                uint64_t key_id = item.getKey();
                arrc.emplace(key_id,varray());
                varray & vv = arrc[key_id];
                auto array = item.getArrays();
                unsigned array_size = array.size();
                vv.reserve(array_size);
                for (unsigned j=0;j<array_size;++j) {
                    auto arr = array[j];
                    auto vals = arr.getVal();
                    unsigned vals_size = vals.size();
                    vv.emplace_back(std::vector<uint64_t>());
                    std::vector<uint64_t> & vvals = vv.back();
                    vvals.reserve(vals_size);
                    for (unsigned k=0;k<vals_size;++k) {
                        vvals.emplace_back(vals[k]);
                    }
                }
            }
        } else {

        }
    /*
        if (!args[args.Length()-1]->IsFunction())
            return NanThrowTypeError("last argument must be a callback function");
        auto cb = Handle<Function>::Cast(args[args.Length()-1]);
        Local<Value> argv[1] = { Local<Value>::New(Null()) };
        cb->Call(Context::GetCurrent()->Global(), 1, argv);
    */
    } catch (std::exception const& ex) {
        return NanThrowTypeError(ex.what());
    }
    NanReturnValue(Undefined());
}


NAN_METHOD(Cache::has)
{
    NanScope();
    if (args.Length() < 2) {
        return NanThrowTypeError("expected two args: type and shard");
    }
    if (!args[0]->IsString()) {
        return NanThrowTypeError("first arg must be a string");
    }
    if (!args[1]->IsNumber()) {
        return NanThrowTypeError("second arg must be an integer");
    }
    try {
        std::string type = *String::Utf8Value(args[0]->ToString());
        std::string shard = *String::Utf8Value(args[1]->ToString());
        std::string key = type + "-" + shard;
        Cache* c = node::ObjectWrap::Unwrap<Cache>(args.This());
        memcache const& mem = c->cache_;
        mem_iterator_type itr = mem.find(key);
        if (itr != mem.end()) {
            NanReturnValue(True());
        } else {
            NanReturnValue(False());
        }
    } catch (std::exception const& ex) {
        return NanThrowTypeError(ex.what());
    }
}

NAN_METHOD(Cache::search)
{
    NanScope();
    if (args.Length() < 3) {
        return NanThrowTypeError("expected two args: type, shard, and id");
    }
    if (!args[0]->IsString()) {
        return NanThrowTypeError("first arg must be a string");
    }
    if (!args[1]->IsNumber()) {
        return NanThrowTypeError("second arg must be an integer");
    }
    if (!args[2]->IsNumber()) {
        return NanThrowTypeError("third arg must be an integer");
    }
    try {
        std::string type = *String::Utf8Value(args[0]->ToString());
        std::string shard = *String::Utf8Value(args[1]->ToString());
        uint64_t id = args[2]->NumberValue();
        std::string key = type + "-" + shard;
        Cache* c = node::ObjectWrap::Unwrap<Cache>(args.This());
        memcache const& mem = c->cache_;
        mem_iterator_type itr = mem.find(key);
        if (itr == mem.end()) {
            NanReturnValue(Undefined());
        } else {
            arr_iterator aitr = itr->second.find(id);
            if (aitr == itr->second.end()) {
                NanReturnValue(Undefined());
            } else {
                auto const& array = aitr->second;
                if (type == "grid") {
                    unsigned array_size = array.size();
                    Local<Array> arr_obj = Array::New(array_size);
                    for (unsigned j=0;j<array_size;++j) {
                        auto arr = array[j];
                        unsigned vals_size = arr.size();
                        Local<Array> vals_obj = Array::New(vals_size);
                        for (unsigned k=0;k<vals_size;++k) {
                            vals_obj->Set(k,Number::New(arr[k]));
                        }
                        arr_obj->Set(j,vals_obj);
                    }
                    NanReturnValue(arr_obj);
                } else {
                    auto arr = array[0];
                    unsigned vals_size = arr.size();
                    Local<Array> arr_obj = Array::New(vals_size);
                    for (unsigned k=0;k<vals_size;++k) {
                        arr_obj->Set(k,Number::New(arr[k]));
                    }
                    NanReturnValue(arr_obj);
                }
            }
        }
    } catch (std::exception const& ex) {
        return NanThrowTypeError(ex.what());
    }
}

NAN_METHOD(Cache::New)
{
    NanScope();
    if (!args.IsConstructCall()) {
        return NanThrowTypeError("Cannot call constructor as function, you need to use 'new' keyword");
    }
    try {
        if (args.Length() < 2) {
            return NanThrowTypeError("expected 'id' and 'shardlevel' arguments");
        }
        if (!args[0]->IsString()) {
            return NanThrowTypeError("first argument 'id' must be a string");
        }
        if (!args[1]->IsNumber()) {
            return NanThrowTypeError("first argument 'shardlevel' must be a number");
        }
        std::string id = *String::Utf8Value(args[0]->ToString());
        int shardlevel = args[1]->IntegerValue();
        Cache* im = new Cache(id,shardlevel);
        im->Wrap(args.This());
        args.This()->Set(String::NewSymbol("id"),args[0]);
        args.This()->Set(String::NewSymbol("shardlevel"),args[1]);
        NanReturnValue(args.This());
    } catch (std::exception const& ex) {
        return NanThrowTypeError(ex.what());
    }
    NanReturnValue(Undefined());
}


NAN_METHOD(Cache::parseCapnProto)
{
    NanScope();
    if (args.Length() < 1) {
        return NanThrowTypeError("first argument must be a buffer");
    }
    if (!args[0]->IsObject()) {
        return NanThrowTypeError("first argument must be a buffer");
    }
    Local<Object> obj = args[0]->ToObject();
    if (obj->IsNull() || obj->IsUndefined()) {
        return NanThrowTypeError("a buffer expected for first argument");
    }
    if (!node::Buffer::HasInstance(obj)) {
        return NanThrowTypeError("first argument must be a buffer");
    }
    bool packed = false;
    if (args.Length() == 2) {
        if (!args[1]->IsObject()) {
            return NanThrowTypeError("optional second argument must be an object");
        }
        Local<Object> options = args[1]->ToObject();
        if (options->IsNull() || options->IsUndefined()) {
            return NanThrowTypeError("a valid object expected for second argument");
        }
        if (options->Has(String::New("packed"))) {
            Local<Value> packed_opt = options->Get(String::New("packed"));
            if (!packed_opt->IsBoolean())
                return NanThrowTypeError("optional arg 'packed' must be a boolean");
            packed = packed_opt->BooleanValue();
        }
    }
    Local<Object> json = Object::New();
    try {
        const char * cdata = node::Buffer::Data(obj);
        size_t size = node::Buffer::Length(obj);

        ::capnp::ReaderOptions options;
        ScratchSpace scratch;
        //options.traversalLimitInWords = 8 * 1024 * 1024

        /*
        // slow since this allocates more memory
        ::kj::ArrayPtr<const ::kj::byte> arr_ptr(&cdata[0],size);
        ::kj::ArrayInputStream in(arr_ptr);
        ::capnp::PackedMessageReader reader(in,options,nullptr);
        */

        /*
        //todo - read from raw array unpacked
        ::kj::ArrayPtr<const ::capnp::word> arr_ptr(&cdata[0],size);
        FlatArrayMessageReader reader(arr_ptr);
        */

        // TODO - try readMessageUnchecked on single segment message
        //carmen::Message::Reader msg = ::capnp::readMessageUnchecked<carmen::Message>((const capnp::word *)&cdata[0]);
        
        // packed
        carmen::Message::Reader msg;
        if (packed) {
                BufferStream pipe(cdata,size);
                ::capnp::PackedMessageReader reader(pipe);
                // no faster...
                //::capnp::PackedMessageReader reader(pipe,options,kj::arrayPtr(scratchSpace, SCRATCH_SIZE));
                msg = reader.getRoot<carmen::Message>();
        } else {
                UnBufferedStream pipe(cdata,size,true);
                ::capnp::InputStreamMessageReader reader(pipe,options,kj::arrayPtr(scratchSpace, SCRATCH_SIZE));
                msg = reader.getRoot<carmen::Message>();
        }


        auto items = msg.getItems();
        unsigned items_size = items.size();
        for (unsigned i=0;i<items_size;++i) {
            auto item = items[i];
            auto array = item.getArrays();
            unsigned array_size = array.size();
            #ifdef CREATE_JS_OBJ
            Local<Array> arr_obj = Array::New(array_size);
            #endif
            for (unsigned j=0;j<array_size;++j) {
                auto arr = array[j];
                auto vals = arr.getVal();
                unsigned vals_size = vals.size();
                #ifdef CREATE_JS_OBJ
                Local<Array> vals_obj = Array::New(vals_size);
                #endif
                for (unsigned k=0;k<vals_size;++k) {
                    #ifdef CREATE_JS_OBJ
                    vals_obj->Set(k,Number::New(vals[k]));
                    #endif
                }
                #ifdef CREATE_JS_OBJ
                arr_obj->Set(j,vals_obj);
                #endif
            }
            #ifdef CREATE_JS_OBJ
            uint64_t num = item.getKey();
            if (num < max_32_int) {
                json->Set(num,arr_obj);
            } else {
                json->Set(Number::New(item.getKey()),arr_obj);
            }
            #endif
        }
    } catch (std::exception const& ex) {
        return NanThrowTypeError(ex.what());
    }
    NanReturnValue(json);
}

NAN_METHOD(Cache::parseProto)
{
    NanScope();
    if (args.Length() < 1) {
        return NanThrowTypeError("first argument must be a buffer");
    }

    if (!args[0]->IsObject()) {
        return NanThrowTypeError("first argument must be a buffer");
    }

    Local<Object> obj = args[0]->ToObject();
    if (obj->IsNull() || obj->IsUndefined()) {
        return NanThrowTypeError("a buffer expected for first argument");
    }
    if (!node::Buffer::HasInstance(obj)) {
        return NanThrowTypeError("first argument must be a buffer");
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
                #ifdef CREATE_JS_OBJ
                Local<Array> val_array = Array::New();
                #endif
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
                                #ifdef CREATE_JS_OBJ
                                Local<Array> v2 = Array::New();
                                #endif
                                while (val.next()) {
                                    #ifdef CREATE_JS_OBJ
                                    v2->Set(vidx++,Number::New(val.value));
                                    #endif
                                }
                                #ifdef CREATE_JS_OBJ
                                val_array->Set(idx++,v2);
                                #endif
                                array.skipBytes(vals_length);
                            } else {
                                throw std::runtime_error("skipping when shouldnt");
                                array.skip();
                            }
                        }
                        item.skipBytes(arrays_length);
                    } else if (item.tag == 2) {
                        int64_t val = item.varint();
                        #ifdef CREATE_JS_OBJ
                        json->Set(Number::New(val),val_array);
                        #endif
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
        return NanThrowTypeError(ex.what());
    }
    NanReturnValue(json);
}

extern "C" {
    static void start(Handle<Object> target) {
        Cache::Initialize(target);
    }
}

} // namespace node_mem

NODE_MODULE(mem, node_mem::start)
