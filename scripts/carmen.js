#!/usr/bin/env node

if (!process.argv[2]) {
    console.log('Usage: carmen.js [file|dir] --query="<query>"');
    process.exit(1);
}

var fs = require('fs');
var path = require('path');
var Carmen = require('../index');
var argv = require('minimist')(process.argv, {
    string: 'query',
    boolean: 'geojson',
    boolean: 'stats'
});

if (!argv.query) throw new Error('--query argument required');

var opts = {};
if (argv._.length > 2) {
    var src = path.resolve(argv._[argv._.length-1]);
    var stat = fs.statSync(src);
    if (stat.isDirectory()) {
        opts = Carmen.autodir(src);
    } else {
        opts[path.basename(src)] = Carmen.auto(src);
    }
} else {
    opts = Carmen.autodir(path.resolve(__dirname + '/../tiles'));
}

var carmen = new Carmen(opts);

var load = +new Date();
carmen.geocode(argv.query, {}, function(err, data) {
    if (err) throw err;
    load = +new Date() - load;
    carmen.geocode(argv.query, { stats:true }, function(err, data) {
        if (err) throw err;
        if (data.features.length && !argv.geojson) {
            console.log('Tokens');
            console.log('------');
            console.log(data.query.join(', '));
            console.log('');
            console.log('Features');
            console.log('--------');
            data.features.forEach(function(f) {
                console.log('- %s %s', f.relevance.toFixed(2), f.place_name);
            });
            console.log('');
        }
        if (data.features.length && argv.geojson) {
            console.log(JSON.stringify(data, null, 2));
        }
        if (!argv.stats) return;
        console.log('Stats');
        console.log('-----');
        console.log('- warmup:    %sms', load);
        console.log('- search:    %s @ %sms', data.stats.searchCount||0, data.stats.searchTime||0);
        console.log('- relev:     %s @ %sms', data.stats.relevCount||0, data.stats.relevTime||0);
        console.log('- results:   %s @ %sms', data.stats.contextCount||0, data.stats.contextTime||0);
        console.log('- totaltime: %sms', data.stats.totalTime||0);

        console.log('Cache');
        console.log('-----');
        var cachestats = {term:0,phrase:0,grid:0,degen:0,total:0};
        carmen.indexes.forEach(function(source, name) {
            cachestats.forEach(function(sum, key) {
                var count = source._geocoder.list(key).length;
                cachestats[key] += count;
                cachestats.total += count;
            });
        });
        console.log('- degen:     %s', cachestats.degen);
        console.log('- term:      %s', cachestats.term);
        console.log('- phrase:    %s', cachestats.phrase);
        console.log('- grid:      %s', cachestats.grid);
        console.log('- total:     %s', cachestats.total);
        if (process.env.DEBUG) Object.keys(opts).forEach(function(dbname) {
            var stats = data.stats['search.'+dbname];
            if (!stats) return;
            console.log('- search.%s', dbname);
            for (var phase in stats) {
                console.log('  - %s %s => %s @ %s ms', rpad(phase,8), stats[phase][0], stats[phase][1], stats[phase][2]);
            }
        });
    });
});

function rpad(str, len) {
    if (typeof str !== 'string') str = str.toString();
    while (str.length < len) str = str + ' ';
    return str;
}
