@0xb84281b5233a2458;

using Cxx = import "/capnp/c++.capnp";
$Cxx.namespace("flat_array");

struct FlatMessage {
  val @0 :List(UInt64);
}