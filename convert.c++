#include "src/index.capnp.h"
#include <capnp/message.h>
#include <capnp/serialize-packed.h>
#include <iostream>
#include <fstream>
#include <v8.h>
#include "v8_helper.hpp"

int writeJSON(v8::Isolate* isolate,const char * json_file, bool packed=false) {
    v8::HandleScope handle_scope(isolate);
    v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New();
    v8::Handle<v8::Context> context = v8::Context::New(isolate, NULL, global);
    if (context.IsEmpty()) {
      fprintf(stderr, "Error creating context\n");
      return 1;
    }
    context->Enter();
    v8::TryCatch try_catch;
    v8::Handle<v8::String> source = ReadFile(json_file);
    if (!source.IsEmpty()) {
        v8::Handle<v8::Object> global_obj = context->Global();
        v8::Handle<v8::Object> JSON = global_obj->Get(v8::String::New("JSON"))->ToObject();
        // https://groups.google.com/forum/#!msg/v8-users/X1Dtpkgm6eA/cIYLvZBWiOAJ
        v8::Handle<v8::Function> JSON_parse = v8::Handle<v8::Function>::Cast(JSON->Get(v8::String::New("parse")));
        v8::Handle<v8::Value> string_val(source);
        v8::Handle<v8::Value> json = JSON_parse->Call(JSON, 1, &string_val);
        if (!json.IsEmpty() && 
            !json->IsNull() && 
            !json->IsUndefined() &&
            json->IsObject()) {
            v8::Local<v8::Object> obj = json.As<v8::Object>();
            v8::Local<v8::Array> propertyNames = obj->GetPropertyNames();
            uint32_t prop_len = propertyNames->Length();
            // create message builder
            uint firstSegmentWords = 1024*1024*1024;
            ::capnp::AllocationStrategy allocationStrategy = ::capnp::SUGGESTED_ALLOCATION_STRATEGY;
            ::capnp::MallocMessageBuilder message(firstSegmentWords,allocationStrategy);
            carmen::Message::Builder msg = message.initRoot<carmen::Message>();
            ::capnp::List<carmen::Item>::Builder items = msg.initItems(prop_len);
            for (int i=0;i < prop_len;++i) {
                v8::Local<v8::Value> key = propertyNames->Get(i);
                v8::Local<v8::Value> prop = obj->Get(key);
                if (prop->IsArray()) {
                    carmen::Item::Builder item = items[i];
                    v8::String::Utf8Value name(key->ToString());
                    item.setKey(*name);
                    v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast(prop);
                    uint32_t arr_len = arr->Length();
                    auto arrays = item.initArrays(arr_len);
                    for (int j=0;j < arr_len;++j) {
                        v8::Local<v8::Value> val_array = arr->Get(j);
                        if (val_array->IsArray()) {
                            v8::Local<v8::Array> vals = v8::Local<v8::Array>::Cast(val_array);
                            uint32_t val_len = vals->Length();
                            carmen::Array::Builder arr2 = arrays[j];
                            auto val = arr2.initVal(val_len);
                            for (int k=0;k < val_len;++k) {
                                v8::Local<v8::Value> v = vals->Get(k);
                                uint64_t vv = v->NumberValue();
                                val.set(k,vv);
                            }
                        }
                    }
                }
            }
            // TODO: better, after message creation method of creating single segment message:
            // https://github.com/kentonv/capnproto/blob/2088715c3214dba4aa54abf95dacc227b3f34856/c%2B%2B/src/capnp/compiler/capnp.c%2B%2B#L644-L661
            kj::ArrayPtr<const kj::ArrayPtr<const ::capnp::word>> segs = message.getSegmentsForOutput();
            std::clog << "num segments: " << segs.size() << "\n";
            if (packed) {
              writePackedMessageToFd(1, message);
            } else {
              writeMessageToFd(1, message);
            }
        }
    }
    if (try_catch.HasCaught()) {
      ReportException(isolate, &try_catch);
    }
    context->Exit();
    return 0;
  }

void writeMessage(int fd, bool packed=false) {
  ::capnp::MallocMessageBuilder message;
  carmen::Message::Builder msg = message.initRoot<carmen::Message>();
  ::capnp::List<carmen::Item>::Builder items = msg.initItems(1);
  carmen::Item::Builder item = items[0];
  item.setKey("hello");
  // Type shown for explanation purposes; normally you'd use auto.
  ::capnp::List<carmen::Array>::Builder arrays = item.initArrays(1);
  carmen::Array::Builder arr = arrays[0];
  ::capnp::List<::uint64_t>::Builder vals = arr.initVal(1);
  vals.set(0,1);
  vals.set(1,2);
  vals.set(2,3);
  kj::ArrayPtr<const kj::ArrayPtr<const ::capnp::word>> segs = message.getSegmentsForOutput();
  std::clog << "num segments: " << segs.size() << "\n";
  if (packed) {
    writePackedMessageToFd(fd, message);
  } else {
    writeMessageToFd(fd, message);
  }
  // TODO - can messageToFlatArray ensure a single segment?
  //::kj::Array<::capnp::word> seg = messageToFlatArray(message);
}

void printMessage(int fd,bool packed=false) {
  carmen::Message::Reader msg;
  if (packed) {
      ::capnp::PackedFdMessageReader message(fd);
      msg = message.getRoot<carmen::Message>();
  } else {
      ::capnp::StreamFdMessageReader message(fd);
      msg = message.getRoot<carmen::Message>();
  }
  auto msg_size = msg.getItems().size();
  uint32_t msg_idx = 0;
  std::cout << "{";
  for (carmen::Item::Reader item : msg.getItems()) {
    std::cout << "\"" << item.getKey().cStr() << "\":[";
    auto item_size = item.getArrays().size();
    uint32_t item_idx = 0;
    for (carmen::Array::Reader array: item.getArrays()) {
      auto val_size = array.getVal().size();
      uint32_t val_idx = 0;
      std::cout << "[";
      for (::uint64_t vals: array.getVal()) {
      	std::cout << vals;
        if (val_idx < val_size-1) {
          std::cout << ",";
        }
        ++val_idx;
      }
      std::cout << "]";
      if (item_idx < item_size-1) {
        std::cout << ",";
      }
      ++item_idx;
    }
    std::cout << "]";
    if (msg_idx < msg_size-1) {
      std::cout << ",\n";
    }
    ++msg_idx;
  }
  std::cout << "}\n";
}


int main(int argc, char* argv[]) {
  if (argc != 2) {
    std::cerr << "Missing arg." << std::endl;
    return 1;
  } else if (strcmp(argv[1], "write") == 0) {
    writeMessage(1,false);
  } else if (strcmp(argv[1], "pwrite") == 0) {
    writeMessage(1,true);
  } else if (strcmp(argv[1], "read") == 0) {
    printMessage(0,false);
  } else if (strcmp(argv[1], "pread") == 0) {
    printMessage(0,true);
  } else {
    v8::V8::InitializeICU();
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    int ret = writeJSON(isolate,argv[1],true);
    v8::V8::Dispose();
    return ret;
  }
	return 0;
}
