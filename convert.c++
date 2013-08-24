#include "src/index.capnp.h"
#include <capnp/message.h>
#include <capnp/serialize-packed.h>
#include <iostream>
#include <fstream>
#include <v8.h>

// https://groups.google.com/forum/#!msg/v8-users/X1Dtpkgm6eA/cIYLvZBWiOAJ

//using namespace v8;

// Reads a file into a v8 string.
v8::Handle<v8::String> ReadFile(const std::string& name) {
  FILE* file = fopen(name.c_str(), "rb");
  if (file == NULL) return v8::Handle<v8::String>();
  fseek(file, 0, SEEK_END);
  int size = ftell(file);
  if (size < 1) return v8::Handle<v8::String>();
  rewind(file);
  char* chars = new char[size + 1];
  chars[size] = '\0';
  for (int i = 0; i < size;) {
    int read = static_cast<int>(fread(&chars[i], 1, size - i, file));
    i += read;
  }
  fclose(file);
  v8::Handle<v8::String> result = v8::String::New(chars, size);
  delete[] chars;
  return result;
}

// Extracts a C string from a V8 Utf8Value.
const char* ToCString(const v8::String::Utf8Value& value) {
  return *value ? *value : "<string conversion failed>";
}

void ReportException(v8::Isolate* isolate, v8::TryCatch* try_catch) {
  v8::HandleScope handle_scope(isolate);
  v8::String::Utf8Value exception(try_catch->Exception());
  const char* exception_string = ToCString(exception);
  v8::Handle<v8::Message> message = try_catch->Message();
  if (message.IsEmpty()) {
    // V8 didn't provide any extra information about this error; just
    // print the exception.
    fprintf(stderr, "%s\n", exception_string);
  } else {
    // Print (filename):(line number): (message).
    v8::String::Utf8Value filename(message->GetScriptResourceName());
    const char* filename_string = ToCString(filename);
    int linenum = message->GetLineNumber();
    fprintf(stderr, "%s:%i: %s\n", filename_string, linenum, exception_string);
    // Print line of source code.
    v8::String::Utf8Value sourceline(message->GetSourceLine());
    const char* sourceline_string = ToCString(sourceline);
    fprintf(stderr, "%s\n", sourceline_string);
    // Print wavy underline (GetUnderline is deprecated).
    int start = message->GetStartColumn();
    for (int i = 0; i < start; i++) {
      fprintf(stderr, " ");
    }
    int end = message->GetEndColumn();
    for (int i = start; i < end; i++) {
      fprintf(stderr, "^");
    }
    fprintf(stderr, "\n");
    v8::String::Utf8Value stack_trace(try_catch->StackTrace());
    if (stack_trace.length() > 0) {
      const char* stack_trace_string = ToCString(stack_trace);
      fprintf(stderr, "%s\n", stack_trace_string);
    }
  }
}

int writeJSON(v8::Isolate* isolate,const char * json_file) {
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
            ::capnp::MallocMessageBuilder message;
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
            writePackedMessageToFd(1, message);
        }
    }
    if (try_catch.HasCaught()) {
      ReportException(isolate, &try_catch);
    }
    context->Exit();
    return 0;
  }

void writeMessage(int fd) {
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
  writePackedMessageToFd(fd, message);
}

void printMessage(int fd) {
  ::capnp::PackedFdMessageReader message(fd);
  carmen::Message::Reader msg = message.getRoot<carmen::Message>();
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
    writeMessage(1);
  } else if (strcmp(argv[1], "read") == 0) {
    printMessage(0);
  } else {
    v8::V8::InitializeICU();
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    int ret = writeJSON(isolate,argv[1]);
    v8::V8::Dispose();
    return ret;
  }
	return 0;
}
