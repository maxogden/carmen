#!/bin/bash
set -e -u

# set up
TMP=`mktemp -d tmpXXXX`
createdb $TMP
psql -d $TMP -c "create extension postgis"

# download + import TZ geometries 
curl -sfo $TMP/tz_world_mp.zip http://efele.net/maps/tz/world/tz_world_mp.zip
unzip -q $TMP/tz_world_mp.zip -d $TMP
shp2pgsql -s 4326 $TMP/world/tz_world_mp.shp import | psql -d $TMP

# download + import offsets
curl -sfo $TMP/tzids.csv http://www.snae.net/tzids.csv
psql -d $TMP -c "CREATE TABLE offsets (tzid VARCHAR, utc int, windows_id VARCHAR, windows_display VARCHAR)"
sed '1d' $TMP | psql -d $TMP -c "COPY offsets FROM STDIN"

echo "
CREATE TABLE data(id SERIAL PRIMARY KEY, name VARCHAR, search VARCHAR, utc VARCHAR, lon FLOAT, lat FLOAT, bounds VARCHAR);
SELECT AddGeometryColumn('public', 'data', 'geometry', 4326, 'MULTIPOLYGON', 2);
INSERT INTO data (id, geometry, name, search, utc) SELECT ogc_fid, setsrid(wkb_geometry,4326), utc FROM import;
UPDATE data SET lon = x(pointonsurface(geometry)), lat = y(pointonsurface(geometry)), bounds = xmin(geometry)||','||ymin(geometry)||','||xmax(geometry)||','||ymax(geometry);
" | psql -U postgres $TMP

# todo: join tzid geom to offset

ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:900913 -f "SQLite" -nln data tz.sqlite PG:"host=localhost user=postgres dbname=$TMP" data
dropdb -U postgres $TMP
rm -rf $TMP

echo "Written to tz.sqlite."
