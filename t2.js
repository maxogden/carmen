var fs = require('fs');
var mem = require('./lib/mem.node');
var type = 'grid';
var shard = 0;
var times = 100;

var json = fs.readFileSync(__dirname + '/test/fixtures/' + type + '.' + shard + '.json');
var proto = fs.readFileSync(__dirname + '/test/fixtures/' + type + '.' + shard + '.pbf');
var capnproto = fs.readFileSync(__dirname + '/test/fixtures/' + type + '.' + shard + '.cpbf');

console.time('parse json x' + times);
for (var i = 0; i < times; i++) JSON.parse(json);
console.timeEnd('parse json x' + times);

var engine = new mem.Engine();

var name = 'parse proto c++ sync x'
console.time(name + times);
for (var i = 0; i < times; i++) {
   engine.parseProto(proto)
   //console.log(engine.parseProto(proto));
}
console.timeEnd(name + times);

var name = 'parse capnproto c++ sync x'
console.time(name + times);
for (var i = 0; i < times; i++) {
   engine.parseCapnProto(capnproto)
   //console.log(engine.parseCapnProto(capnproto));
}
console.timeEnd(name + times);
