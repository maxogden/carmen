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
psql -d $TMP -c "CREATE TABLE offsets (tzid VARCHAR, utc FLOAT, windows_id VARCHAR, windows_display VARCHAR)"
sed '1d' $TMP/tzids.csv | psql -d $TMP -c "COPY offsets FROM STDIN WITH DELIMITER ',' CSV"

echo "
CREATE TABLE data(id SERIAL PRIMARY KEY, name VARCHAR, search VARCHAR, utc VARCHAR, lon FLOAT, lat FLOAT, bounds VARCHAR);
SELECT AddGeometryColumn('public', 'data', 'geometry', 4326, 'MULTIPOLYGON', 2);
INSERT INTO data (id, geometry, name, search, utc) SELECT a.gid, a.geom, a.tzid, a.tzid, b.utc FROM import a JOIN offsets b ON lower(a.tzid) = lower(b.tzid);
UPDATE data SET lon = st_x(st_pointonsurface(geometry)), lat = st_y(st_pointonsurface(geometry)), bounds = st_xmin(geometry)||','||st_ymin(geometry)||','||st_xmax(geometry)||','||st_ymax(geometry);
" | psql $TMP

# -- UPDATE data SET lon = x(pointonsurface(geometry)), lat = y(pointonsurface(geometry)), bounds = xmin(geometry)||','||ymin(geometry)||','||xmax(geometry)||','||ymax(geometry);
# todo: join tzid geom to offset

ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:900913 -f "SQLite" -nln data tz.sqlite PG:"host=localhost dbname=$TMP" data
dropdb $TMP
rm -rf $TMP

echo "Written to tz.sqlite."
