var JSCache = require('../cache');
var CXXCache = require('../lib/mem.js');
var fs = require('fs');
var assert = require('assert');

var times = 5000;
var max_shard = 0;

function getter(type, shard, file_ext) {
    return fs.readFileSync(__dirname + '/../test/fixtures/big/' + type + '.' + shard + file_ext);
};

console.time('protobuf load');
var cache = new CXXCache('a', 2);
['grid','term'].forEach(function(type) {
    for (var shard=0;shard<=max_shard;++shard) {
        cache.load(getter(type,shard,'.pbf'), type, shard, 'protobuf');
    }
});
console.timeEnd('protobuf load');

console.time('protobuf get x'+times);
for (var i=0;i<times;++i) {
    assert.deepEqual(cache.get('grid',52712469173248),[[104101,1100010900000591]]);
}
console.timeEnd('protobuf get x'+times);

