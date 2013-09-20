#!/usr/bin/env bash
set -e -u

for country in $(sqlite3 $1 "select name from data order by name limit 10" | sed 's/\ /-/g')
do
	# let i=0
	# if [ -e json/${country}.geojson ]; then
	# 	i=$(i + 1)
	# 	echo $i
	# 	country=${country}_${i}
	# 	echo $country
	# fi
	j=$(echo $country | sed 's/-/ /g')
	ogr2ogr -f GeoJSON -t_srs EPSG:4326 -sql "select * from data where name = '$j'" json/${country}.geojson $1
	topojson --no-quantization json/${country}.geojson -o json/${country}.json
	rm -rf json/${country}.geojson
done