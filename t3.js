var fs = require('fs');
var mem = require('./lib/mem.node');
var type = 'grid';
var shard = 0;
var times = 10;

var engine = new mem.Engine();

var name = 'parse capnproto unpacked c++ sync x'
console.time(name + times);
for (var i = 0; i < times; i++) {
   var capnproto_packed = fs.readFileSync(__dirname + '/test/fixtures/big/' + type + '.' + shard + '.packed.singleseg');
   engine.parseCapnProto(capnproto_packed,{packed:true});
}
console.timeEnd(name + times);
