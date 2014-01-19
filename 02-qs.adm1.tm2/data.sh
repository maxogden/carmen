#!/bin/bash
set -e -u

TMP="$(dirname $0)/tmp"
mkdir -p $TMP

if [ $(psql -U postgres -l | grep carmen_qs_adm1 | wc -l) != "0" ]; then
  echo "+ carmen_qs_adm1 (noop)"
  exit 0
fi

# Download qs_adm1 shapefile.
if [ ! -f $TMP/qs_adm1.shp ]; then
  curl -sfo $TMP/qs_adm1.zip http://static.quattroshapes.com/qs_adm1.zip
  unzip -d $TMP -q $TMP/qs_adm1.zip
fi

if [ ! -f $TMP/10m-admin-1-states-provinces-shp.shp ]; then
  curl -sfo $TMP/10m-admin-1-states-provinces-shp.zip http://mapbox-geodata.s3.amazonaws.com/natural-earth-1.4.0/cultural/10m-admin-1-states-provinces-shp.zip
  unzip -q $TMP/10m-admin-1-states-provinces-shp.zip -d $TMP
fi

createdb -U postgres -T template_postgis carmen_qs_adm1

ogr2ogr -nlt MULTIPOLYGON -nln tmpdata -f "PostgreSQL" PG:"host=localhost user=postgres dbname=carmen_qs_adm1" $TMP/qs_adm1.shp

ogr2ogr --config SHAPE_ENCODING UTF-8 -nlt MULTIPOLYGON -nln ne -f "PostgreSQL" PG:"host=localhost user=postgres dbname=carmen_qs_adm1" $TMP/10m-admin-1-states-provinces-shp.shp

psql -U postgres carmen_qs_adm1 < wrapx.sql

echo "
CREATE TABLE data(id BIGINT PRIMARY KEY, handle TEXT, text TEXT, area FLOAT, center Geometry(Geometry,900913), geometry Geometry(Geometry,900913));
CREATE INDEX data_geometry ON data USING GIST(geometry);
CREATE INDEX data_center ON data USING GIST(center);
INSERT INTO data (id, handle, text, geometry) SELECT
    ('x'||substr(md5(qs_adm0_a3||'-'||coalesce(qs_a1_lc,qs_a1,'')),0,9))::bit(32)::bigint AS id,
    max(qs_adm0_a3||'-'||coalesce(qs_a1_lc,qs_a1,'')) AS handle,
    max(qs_a1||coalesce(','||n.postal,'')) AS text,
    st_collect(st_transform(st_wrapx(t.wkb_geometry,180,-180),900913)) AS geometry
    FROM tmpdata t
    LEFT JOIN ne n ON t.qs_adm0_a3||'-'||qs_a1 = n.adm0_a3||'-'||name_1
    -- exclude antarctica for now which has a geometry beyond 900913 extents.
    WHERE qs_adm0_a3 <> 'ATA'
    GROUP BY id;
UPDATE data SET center = st_pointonsurface(st_buffer(geometry,0));
UPDATE data SET area = 0;
UPDATE data SET area = st_area(st_geogfromwkb(st_transform(geometry,4326)));
-- where st_within(geometry,st_geomfromtext('POLYGON((-20037508.34 -20037508.34, -20037508.34 20037508.34, 20037508.34 20037508.34, 20037508.34 -20037508.34, -20037508.34 -20037508.34))',900913));
" | psql -U postgres carmen_qs_adm1 

