#!/bin/bash
set -e -u

TMP=`mktemp -d tmpXXXX`
echo "downloading..."
createdb -U postgres -T template_postgis $TMP
curl -sfo $TMP/qs_adm1.zip http://static.quattroshapes.com/qs_adm1.zip
unzip -q $TMP/qs_adm1.zip -d $TMP
echo "reprojecting..."
ogr2ogr -nlt MULTIPOLYGON -nln import -f "PostgreSQL" PG:"host=localhost user=postgres dbname=$TMP" $TMP/qs_adm1.shp

echo "importing..."

# CONCAT(forename,' ',IFNULL(CONCAT(initials,' '), ''),surname)

echo "
CREATE TABLE data(id SERIAL PRIMARY KEY, name VARCHAR, search VARCHAR, lon FLOAT, lat FLOAT, bounds VARCHAR, area FLOAT);
SELECT AddGeometryColumn('public', 'data', 'geometry', 4326, 'MULTIPOLYGON', 2);
INSERT INTO data (id, geometry, name, search) SELECT ogc_fid, st_setsrid(wkb_geometry,4326), qs_a1 AS name, coalesce(qs_a1||','||qs_a1_alt, qs_a1) AS search FROM import;
UPDATE data SET lon = st_x(st_pointonsurface(geometry)), lat = st_y(st_pointonsurface(geometry)), bounds = st_xmin(geometry)||','||st_ymin(geometry)||','||st_xmax(geometry)||','||st_ymax(geometry);
UPDATE data SET area = 0;
UPDATE data SET area = st_area(st_geogfromwkb(geometry)) where st_within(geometry,st_geomfromtext('POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))',4326));
" | psql -U postgres $TMP

echo "exporting..."
ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:900913 -skipfailures -f "SQLite" -nln data qs-adm1.sqlite PG:"host=localhost user=postgres dbname=$TMP" data
echo "cleaning up..."
dropdb -U postgres $TMP
rm -rf $TMP

echo "Written to qs-adm1.sqlite."