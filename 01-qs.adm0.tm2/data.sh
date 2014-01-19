#!/bin/bash
set -e -u

TMP="$(dirname $0)/tmp"
mkdir -p $TMP

if [ $(psql -U postgres -l | grep carmen_qs_adm0 | wc -l) = "1" ]; then
  echo "+ carmen_qs_adm0 (noop)"
  exit 0
fi

# Download qs_adm0
if [ ! -f $TMP/qs_adm0.shp ]; then
  curl -sfo $TMP/qs_adm0.zip http://static.quattroshapes.com/qs_adm0.zip
  unzip -d $TMP -q $TMP/qs_adm0.zip
fi

createdb -U postgres -T template_postgis carmen_qs_adm0
ogr2ogr -nlt MULTIPOLYGON -nln tmpdata -f "PostgreSQL" PG:"host=localhost user=postgres dbname=carmen_qs_adm0" $TMP/qs_adm0.shp

echo "
CREATE TABLE data(id BIGINT PRIMARY KEY, a3 TEXT, text TEXT, center Geometry(Geometry,900913), geometry Geometry(Geometry,900913));
CREATE INDEX data_geometry ON data USING GIST(geometry);
CREATE INDEX data_center ON data USING GIST(center);
-- Uses the first 8 characters of md5 as 32-bit unsigned int.
INSERT INTO data (id, a3, geometry, text) SELECT ('x'||substr(md5(qs_adm0_a3),0,9))::bit(32)::bigint, qs_adm0_a3, st_transform(st_collect(wkb_geometry),900913), min(qs_adm0) AS text FROM tmpdata GROUP BY qs_adm0_a3;
UPDATE data SET center = st_pointonsurface(st_buffer(geometry,0));
UPDATE data SET text='United States, United States of America, America, USA, US' WHERE a3 = 'USA';
UPDATE data SET text='United Kingdom, UK' WHERE a3 = 'GBR';
UPDATE data SET text='Canada, CA' WHERE a3 = 'CAN';
UPDATE data SET text='Colombia, Columbia' WHERE a3 = 'COL';
UPDATE data SET text='Australia, AU' WHERE a3 = 'AUS';
UPDATE data SET text='Germany, DE' WHERE a3 = 'DEU';
UPDATE data SET text='France, FR' WHERE a3 = 'FRA';
UPDATE data SET text='South Korea, Korea' WHERE a3 = 'KOR';
UPDATE data SET text='Democratic Republic of the Congo, DRC' WHERE a3 = 'COD';
UPDATE data SET text='United Arab Emirates, UAE' WHERE a3 = 'ARE';
" | psql -U postgres carmen_qs_adm0

rm -rf $TMP

