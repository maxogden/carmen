#!/usr/bin/bash
set -e -u

# takes a sqlite full of carmen-redy data (assumes unique `name` field)
# and outputs one topojson for every record

for country in $(sqlite3 $1 "select name from data order by name" | sed 's/\ /-/g')
do
    j=$(echo $country | sed 's/-/ /g')
    ogr2ogr \
        -f GeoJSON \
        -s_srs EPSG:3857 \
        -t_srs EPSG:4326 \
        -sql "select * from data where name = '$j'" \
        json/${country}.geojson $1

    topojson \
        --no-quantization \
        -p name,search,lat,lon,bounds,area \
        json/${country}.geojson \
        -o json/${country}.json

    rm -rf json/${country}.geojson
done

	# let i=0
	# if [ -e json/${country}.geojson ]; then
	# 	i=$(i + 1)
	# 	echo $i
	# 	country=${country}_${i}
	# 	echo $country
	# fi