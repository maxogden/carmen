#!/usr/bin/env node

require('http').request({
    host: 'www.broofa.com',
    path: '/Toys/NPRStations/npr.php',
    query: 'format=csv'
}, function(res) {
    var data = [];
    var geojson = {};
    res.on('data', function(d) { data.push(d.toString()); });
    res.on('end', function() {
        var grouped = data.join('').split('\n')
            .slice(1)
            .filter(function(l) { return !!l })
            .map(function(l) {
                var fields = l.split(',');
                return fields;
            })
            .reduce(function(memo, l) {
                var key = l[5] + ',' + l[6];
                memo[key] = memo[key] || {
                    stations: [],
                    search: [],
                    kw: 0
                };
                memo[key].stations.push(l[2] + " - " + l[4]);
                memo[key].search.push(l[2]);
                memo[key].kw = Math.max(parseFloat(l[3]), memo[key].kw);
                memo[key].city = l[0];
                memo[key].state = l[1];
                memo[key].lon = parseFloat(l[6]);
                memo[key].lat = parseFloat(l[5]);
                return memo;
            }, {});
        var geojson = { 'type': 'FeatureCollection', 'features': [] };
        for (var k in grouped) {
            geojson.features.push({
                'type': 'Feature',
                'geometry': {
                    'type': 'point',
                    'coordinates': [ grouped[k].lon, grouped[k].lat ]
                },
                'properties': {
                    'name': grouped[k].stations.join(', '),
                    'search': grouped[k].search.join(', '),
                    'city': grouped[k].city,
                    'state': grouped[k].state,
                    'kw': grouped[k].kw,
                    'lon': grouped[k].lon,
                    'lat': grouped[k].lat
                }
            });
        }
        // Sort stations by kw.
        geojson.features.sort(function(a, b) {
            return a.properties.kw > b.properties.kw ? -1 : 1;
        });
        require('fs').writeFileSync('./layers/stations.geojson', JSON.stringify(geojson, null, 2));
        console.log('./layers/stations.geojson written.');
    });
}).end();
