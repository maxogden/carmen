#!/bin/bash
set -e -u

TMP=`mktemp -d tmpXXXX`
createdb -U postgres -T template_postgis $TMP
curl -sfo $TMP/10m-admin-0-countries.zip http://mapbox-geodata.s3.amazonaws.com/natural-earth-1.4.0/cultural/10m-admin-0-countries.zip
unzip -q $TMP/10m-admin-0-countries.zip -d $TMP
ogr2ogr -s_srs EPSG:900913 -t_srs EPSG:4326 -nlt MULTIPOLYGON -nln import -f "PostgreSQL" PG:"host=localhost user=postgres dbname=$TMP" $TMP/10m-admin-0-countries.shp

echo "
CREATE TABLE data(id SERIAL PRIMARY KEY, name VARCHAR, _text VARCHAR, population INTEGER, iso2 VARCHAR, lon FLOAT, lat FLOAT, bounds VARCHAR);
SELECT AddGeometryColumn('public', 'data', 'geometry', 4326, 'MULTIPOLYGON', 2);
INSERT INTO data (id, geometry, name, _text, population, iso2) SELECT ogc_fid, st_setsrid(wkb_geometry,4326), admin AS name, admin AS _text, pop_est, iso_a2 FROM import;
UPDATE data SET lon = st_x(st_pointonsurface(geometry)), lat = st_y(st_pointonsurface(geometry)), bounds = st_xmin(geometry)||','||st_ymin(geometry)||','||st_xmax(geometry)||','||st_ymax(geometry);
" | psql -U postgres $TMP

ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:900913 -f "SQLite" -nln data 01-ne.country.sqlite PG:"host=localhost user=postgres dbname=$TMP" data
dropdb -U postgres $TMP
rm -rf $TMP

echo "
ALTER TABLE data ADD COLUMN _id INTEGER;
UPDATE data SET _id = ogc_fid;
UPDATE data SET _text='United States of America, United States, America, USA, US' WHERE iso2 = 'US';
UPDATE data SET _text='United Kingdom, UK' WHERE iso2 = 'GB';
UPDATE data SET _text='Canada, CA' WHERE iso2 = 'CA';
UPDATE data SET _text='Colombia, Columbia' WHERE iso2 = 'CO';
UPDATE data SET _text='Australia, AU' WHERE iso2 = 'AU';
UPDATE data SET _text='Germany, DE' WHERE iso2 = 'DE';
UPDATE data SET _text='France, FR' WHERE iso2 = 'FR';
UPDATE data SET _text='South Korea, Korea' WHERE iso2 = 'KR';
UPDATE data SET _text='Democratic Republic of the Congo, DRC' WHERE iso2 = 'CD';
UPDATE data SET _text='United Arab Emirates, UAE' WHERE iso2 = 'AE';
" | sqlite3 01-ne.country.sqlite

echo "Written to 01-ne.country.sqlite."
