var fs = require('fs');
var mem = require('./lib/mem.node');
var type = 'grid';
var shard = 0;
var times = 10;

/*
preload for fast case
not moving data but computation
*/

var json = fs.readFileSync(__dirname + '/test/fixtures/big/' + type + '.' + shard + '.json');
var proto = fs.readFileSync(__dirname + '/test/fixtures/big/' + type + '.' + shard + '.pbf');
var capnproto_packed = fs.readFileSync(__dirname + '/test/fixtures/big/' + type + '.' + shard + '.packed.singleseg');
var capnproto_unpacked = fs.readFileSync(__dirname + '/test/fixtures/big/' + type + '.' + shard + '.unpacked.singleseg');

console.time('parse json x' + times);
for (var i = 0; i < times; i++) {
    JSON.parse(json);
    //console.log(Object.keys(JSON.parse(json)).length);
}
console.timeEnd('parse json x' + times);

var engine = new mem.Engine();

var name = 'parse proto c++ sync x'
console.time(name + times);
for (var i = 0; i < times; i++) {
   engine.parseProto(proto)
   //console.log(Object.keys(engine.parseProto(proto)).length);
}
console.timeEnd(name + times);

var name = 'parse capnproto packed c++ sync x'
console.time(name + times);
for (var i = 0; i < times; i++) {
   engine.parseCapnProto(capnproto_packed,{packed:true})
   //console.log(Object.keys(engine.parseCapnProto(capnproto_packed,{packed:true})).length);
}
console.timeEnd(name + times);


var name = 'parse capnproto unpacked c++ sync x'
console.time(name + times);
for (var i = 0; i < times; i++) {
   engine.parseCapnProto(capnproto_unpacked,{packed:false})
   //console.log(Object.keys(engine.parseCapnProto(capnproto_unpacked,{packed:false})).length);
}
console.timeEnd(name + times);

/*

no js / unpacked and one segment: parse capnproto c++ sync x100: 969ms (1057ms on later run with -O3)

no js / protobuf: parse proto c++ sync x100: 1039ms (1059ms) (1077 not inlined / 1598ms forced not inlined / 718ms forced inline)

no js / unpacked: parse capnproto c++ sync x100: 1363ms

no js / packed and one segment: parse capnproto c++ sync x100: 1907ms

no js / packed: parse capnproto c++ sync x100: 2378ms


unpacked vs json with js objects:
	parse json x10: 2624ms
	parse capnproto c++ sync x10: 2940ms
	parse proto c++ sync x10: 4764ms

parse json x10: 2139ms
parse proto c++ sync x10: 4660ms
parse capnproto packed c++ sync x10: 3375ms
parse capnproto unpacked c++ sync x10: 3409ms

*/