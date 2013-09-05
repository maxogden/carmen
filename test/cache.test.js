var Cache;
var file_ext;
var encoding;
var cxx = true;

if (!cxx) {
    Cache = require('../cache');
    file_ext = '.json';
    encoding = 'json';
} else {
    Cache = require('../lib/mem.js');
    //file_ext = '.packed';
    //encoding = 'capnproto'
    file_ext = '.pbf';
    encoding = 'protobuf'
}

var assert = require('assert');
var fs = require('fs');

describe('cache unit', function() {
    it('Cache.shard', function() {
        assert.equal(0, Cache.shard(0, 0));
        assert.equal(0, Cache.shard(0, 1), 'level0 => 0 shard for all ids');

        assert.equal(0, Cache.shard(1, 0));
        assert.equal(1, Cache.shard(1, 1));
        assert.equal(0, Cache.shard(1, 16));
    });
    it('Cache.shardsort', function() {
        var arr;

        arr = [0,1,2,3,4,5];
        Cache.shardsort(0, arr);
        assert.deepEqual([0,1,2,3,4,5], arr);

        arr = [0,1,16,2,17,3];
        Cache.shardsort(1, arr);
        assert.deepEqual([0,16,1,17,2,3], arr);
    });
    it('Cache.uniq', function() {
        assert.deepEqual([1,2,3,4,5], Cache.uniq([5,3,1,2,5,4,3,1,4,2]));
    });

    it('cache sync', function() {
        var cache = new Cache('a', 1);
        assert.equal('a', cache.id);
        assert.equal(1, cache.shardlevel);

        assert.equal(undefined, cache.get('term', 5));
        assert.deepEqual([], cache.list('term'));
        cache.set('term', 5, [0,1,2]);
        assert.deepEqual([0,1,2], cache.get('term', 5));
        assert.deepEqual([5], cache.list('term'));
        cache.set('term', 21, [5,6]);
        assert.deepEqual([5,6], cache.get('term', 21));
        assert.deepEqual([5], cache.list('term'), 'single shard');
        assert.deepEqual([5, 21], cache.list('term', 5), 'keys in shard');
        // cache A serializes data, cache B loads serialized data.
        var pack = cache.pack('term', 5, 'protobuf');
        var loader = new Cache('b', 1);
        loader.load(pack, 'term', 5, 'protobuf');
        assert.deepEqual([5,6], loader.get('term', 21));
        assert.deepEqual([5], loader.list('term'), 'single shard');
        assert.deepEqual([5, 21], loader.list('term', 5), 'keys in shard');

        var pack2 = cache.pack('term', 5, 'capnproto');
        var loader2 = new Cache('b', 1);
        loader2.load(pack2, 'term', 5, 'capnproto');
        assert.deepEqual([5,6], loader2.get('term', 21));
        assert.deepEqual([5], loader2.list('term'), 'single shard');
        assert.deepEqual([5, 21], loader2.list('term', 5), 'keys in shard');

    });

    it('cache set overrides existing', function() {
        var cache = new Cache('a', 1);
        cache.set('term', 5, [0,1,2]);
        assert.deepEqual([0,1,2], cache.get('term', 5));
        cache.set('term', 5, [0,1,2,3]);
        assert.deepEqual([0,1,2,3], cache.get('term', 5));
    });

    it('cache load/pack/load round trip', function() {
        // test all
        ['grid','term'].forEach(function(type) {
            for (var shard=0;shard<=2;++shard) {
                var cache = new Cache('a', 1);
                assert.deepEqual([], cache.list(type));
                var filename = __dirname + '/fixtures/' + type + '.' + shard + file_ext;
                cache.load(fs.readFileSync(filename), type, shard, encoding);
                assert.deepEqual([shard], cache.list(type));
                var ids = cache.list(type,shard);
                assert.ok(ids.length > 0);
                var packed = cache.pack(type,shard,encoding);
                assert.ok(packed);
                var cache2 = new Cache('a', 1);
                cache2.load(packed,type,shard,encoding);
                assert.deepEqual(ids,cache2.list(type,shard));
                assert.ok(cache2.get(type,ids[0]).length > 0);
            }
        });
        // test one focusing on get() results
        var type = 'grid';
        var shard = 0;
        var cache = new Cache('a', 1);
        assert.deepEqual([], cache.list(type));
        var filename = __dirname + '/fixtures/' + type + '.' + shard + file_ext;
        cache.load(fs.readFileSync(filename), type, shard, encoding);
        assert.deepEqual([shard], cache.list(type));
        var ids = cache.list(type,shard);
        assert.deepEqual(489,ids.length);
        var packed = cache.pack(type,shard,encoding);
        assert.ok(packed);
        var cache2 = new Cache('a', 1);
        cache2.load(packed,type,shard,encoding);
        assert.deepEqual(ids,cache2.list(type,shard));
        assert.deepEqual([[100303,1100011150000704],[169059,1100011150000704]],cache2.get(type,100737132572928));

    });

});

describe('cache getall', function() {
    function getter(type, shard, callback) {
        this.encoding = encoding;
        stats[type]++;
        fs.readFile(__dirname + '/fixtures/' + type + '.' + shard + file_ext, callback);
    };
    var stats = { term:0, grid:0 };
    var cache = new Cache('a', 2);

    it('cache getall term', function(done) {
        var ids = [
            872807937, // shard1
            462467840, // shard0
            283479809, // shard1
            986137856, // shard0
            450992896, // shard0
            556780290, // shard2
        ];
        var check = function(err, result) {
            assert.ifError(err);

            // Returns ids mapped to input ids.
            assert.deepEqual([
                126117647032898,
                18578132799233,
                2245607251996,
                247567914995457,
                251957525165442,
                30308292408064,
                57200341024257,
                64627530548480
            ], result);

            // Has loaded shards into cache -- other ids in same shards
            // can be retrieved without additional IO.
            assert.deepEqual([105151062623251,38786692070144], cache.get('term', 591837952), 'shard 0 in memory');
            assert.deepEqual([44433332596993], cache.get('term', 677998849), 'shard 1 in memory');

            // Check IO counter.
            assert.equal(3, stats.term);
        };
        // x2 runs and check ensures that
        // - IO does not occur beyond first run.
        // - result is identical with/without IO.
        cache.getall(getter, 'term', ids, function(err, result) {
            check(err, result);
            cache.getall(getter, 'term', ids, function(err, result) {
                check(err, result);
                done();
            });
        });
    });

    it('cache getall term err', function(done) {
        cache.getall(getter, 'term', [556780291], function(err, result) {
            assert.ok(err);
            assert.equal('ENOENT', err.code);
            done();
        });
    });

    it('cache getall grid', function(done) {
        var ids = [
            52712469173248, // 0
            3504240518402, // 2,
            98071753006080, // 0
            141956873251072, // 0
            35554947385346, // 2
        ];
        var check = function(err, result) {
            assert.ifError(err);
            //console.log(result)

            // Returns ids mapped to input ids.
            assert.deepEqual([
                [ 10229, 1100005020000756, 1100005100000758 ],
                [ 104101, 1100010900000591 ],
                [ 107471, 1100011070000617 ],
                [ 1089, 1100006250000742, 1100006260000742, 1100006260000741 ],
                [ 109619, 1100010400000685 ],
                [ 10996, 1100005350000776, 1100005350000775 ],
                [ 15680, 1100004870000740 ],
                [ 19630, 1100005980000738 ],
                [ 29670, 1100003400000707 ],
                [ 5488, 1100004870000819 ]
            ], result);

            // Has loaded shards into cache -- other ids in same shards
            // can be retrieved without additional IO.
            assert.deepEqual([[102901,1100010800000596,1100010800000595]], cache.get('grid', 229811356881664), 'shard 0 in memory');
            assert.deepEqual([[100453,1100011350000712]], cache.get('grid', 67003285138178), 'shard 2 in memory');

            // Check IO counter.
            assert.equal(2, stats.grid);
        };
        // x2 runs and check ensures that
        // - IO does not occur beyond first run.
        // - result is identical with/without IO.
        cache.getall(getter, 'grid', ids, function(err, result) {
            check(err, result);
            cache.getall(getter, 'grid', ids, function(err, result) {
                check(err, result);
                done();
            });
        });
    });
});
