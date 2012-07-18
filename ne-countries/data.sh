#!/bin/bash
set -e -u

TMP=`mktemp -d tmpXXXX`
createdb -U postgres -T template_postgis $TMP
curl -sfo $TMP/10m-admin-0-countries.zip http://mapbox-geodata.s3.amazonaws.com/natural-earth-1.4.0/cultural/10m-admin-0-countries.zip
unzip -q $TMP/10m-admin-0-countries.zip -d $TMP
ogr2ogr -s_srs EPSG:900913 -t_srs EPSG:4326 -nlt MULTIPOLYGON -nln import -f "PostgreSQL" PG:"host=localhost user=postgres dbname=$TMP" $TMP/10m-admin-0-countries.shp

echo "
CREATE TABLE data(id SERIAL PRIMARY KEY, name VARCHAR, search VARCHAR, population INTEGER, iso2 VARCHAR, lon FLOAT, lat FLOAT, bounds VARCHAR);
SELECT AddGeometryColumn('public', 'data', 'geometry', 4326, 'MULTIPOLYGON', 2);
INSERT INTO data (id, geometry, name, search, population, iso2) SELECT ogc_fid, setsrid(wkb_geometry,4326), admin AS name, admin AS search, pop_est, iso_a2 FROM import;
UPDATE data SET lon = x(pointonsurface(geometry)), lat = y(pointonsurface(geometry)), bounds = xmin(geometry)||','||ymin(geometry)||','||xmax(geometry)||','||ymax(geometry);
" | psql -U postgres $TMP

ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:900913 -f "SQLite" -nln data ne-countries.sqlite PG:"host=localhost user=postgres dbname=$TMP" data
dropdb -U postgres $TMP
rm -rf $TMP

echo "
UPDATE data SET search='United States of America, United States, America, USA, US' WHERE iso2 = 'US';
UPDATE data SET search='United Kingdom, UK' WHERE iso2 = 'GB';
UPDATE data SET search='Canada, CA' WHERE iso2 = 'CA';
UPDATE data SET search='Colombia, Columbia' WHERE iso2 = 'CO';
UPDATE data SET search='Australia, AU' WHERE iso2 = 'AU';
UPDATE data SET search='Germany, DE' WHERE iso2 = 'DE';
UPDATE data SET search='France, FR' WHERE iso2 = 'FR';
UPDATE data SET search='South Korea, Korea' WHERE iso2 = 'KR';
UPDATE data SET search='Democratic Republic of the Congo, DRC' WHERE iso2 = 'CD';
UPDATE data SET search='United Arab Emirates, UAE' WHERE iso2 = 'AE';
" | sqlite3 ne-countries.sqlite

echo "Written to ne-countries.sqlite."
