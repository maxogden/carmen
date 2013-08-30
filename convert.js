var CXXCache = require('./lib/mem.js');
var JSCache = require('./cache');
var fs = require('fs');
var assert = require('assert');

function getter(type, shard, file_ext) {
    return fs.readFileSync(__dirname + '/test/fixtures/' + type + '.' + shard + file_ext);
};

for (var i=0;i<=2;++i) {
	var shard = i;
	['grid','term'].forEach(function(type){
	    var jscache = new JSCache('a', shard);
	    var cxxcache = new CXXCache('a', shard);
        jscache.load(getter(type, shard,'.json'), type, shard);
        cxxcache.loadJSON(jscache[type][shard],type,shard);
        var cxxsorted = cxxcache.list(type,shard).sort();
        var jssorted = jscache.list(type,shard).sort();
        assert.deepEqual(jssorted,cxxsorted);
        var filename = __dirname + '/test/fixtures/' + type + '.' + shard;
        fs.writeFileSync(filename + '.pbf',cxxcache.pack(type,shard,'protobuf'));
        fs.writeFileSync(filename + '.packed',cxxcache.pack(type,shard,'capnproto'));
	});
}


function getter2(type, shard, file_ext) {
    return fs.readFileSync(__dirname + '/test/fixtures/big/' + type + '.' + shard + file_ext);
};

for (var i=0;i<1;++i) {
    var shard = i;
    ['grid','term'].forEach(function(type){
        var jscache = new JSCache('a', shard);
        var cxxcache = new CXXCache('a', shard);
        jscache.load(getter2(type, shard,'.json'), type, shard);
        cxxcache.loadJSON(jscache[type][shard],type,shard);
        var cxxsorted = cxxcache.list(type,shard).sort();
        var jssorted = jscache.list(type,shard).sort();
        assert.deepEqual(jssorted,cxxsorted);
        var filename = __dirname + '/test/fixtures/big/' + type + '.' + shard;
        fs.writeFileSync(filename + '.pbf',cxxcache.pack(type,shard,'protobuf'));
        fs.writeFileSync(filename + '.packed',cxxcache.pack(type,shard,'capnproto'));
    });
}
