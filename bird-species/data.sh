#!/bin/bash

if [ -z `which shp2pgsql` ]; then
  SHP2PGSQL="/usr/lib/postgresql/9.1/bin/shp2pgsql"
else
  SHP2PGSQL=`which shp2pgsql`
fi

TMP="`dirname $0`/tmp"
mkdir -p $TMP

download() {
for (( i=1; i <= 7; i++ )); do
  (curl -sfo $TMP/Birds_3.0_$i.zip http://www.natureserve.org/getData/dataSets/birdMapData/Birds_3.0_$i.zip && \
    unzip -q -j $TMP/Birds_3.0_$i.zip -d $TMP && \
    rm $TMP/Birds_3.0_$i.zip && \
    echo "+ Birds_3.0_$i.zip") &
done
wait
}

process() {
for file in `find $TMP -name *_pl.shp`; do
  if [ -f $TMP/merged.shp ]; then
    ogr2ogr -f "ESRI Shapefile" -update -append -nln merged -s_srs EPSG:4326 -t_srs EPSG:900913 $TMP/merged.shp $file
  else
    ogr2ogr -f "ESRI Shapefile" -s_srs EPSG:4326 -t_srs EPSG:900913 $TMP/merged.shp $file
  fi
  echo "+ $(basename $file) => merged.shp"
done
}

topostgis() {
createdb -T template_postgis -U postgres bird_species

echo "+ merged => PG:bird_species"
$SHP2PGSQL -I -g geometry -W LATIN1 $TMP/merged.shp birds | psql -q -U postgres bird_species

echo "+ 10m-land => PG:land"
curl -sfo $TMP/10m-land.zip http://mapbox-geodata.s3.amazonaws.com/natural-earth-1.4.0/physical/10m-land.zip && \
  unzip -q -j $TMP/10m-land.zip -d $TMP && \
  $SHP2PGSQL -I -g geometry -W LATIN1 $TMP/10m_land.shp land | psql -q -U postgres bird_species

echo "+ 10m-regions => PG:regions"
curl -sfo $TMP/10m-geography-regions-polys.zip http://mapbox-geodata.s3.amazonaws.com/natural-earth-1.4.0/physical/10m-geography-regions-polys.zip
  unzip -q -j $TMP/10m-geography-regions-polys.zip -d $TMP && \
  $SHP2PGSQL -I -g geometry -W LATIN1 $TMP/10m_geography_regions_polys.shp regions | psql -q -U postgres bird_species
}

makedata() {
echo "
--- limit to present species, native (year-round), and valid geometries.
DELETE FROM birds WHERE presence > 1;
DELETE FROM birds WHERE origin > 1;
DELETE FROM birds WHERE NOT st_isvalid(geometry);

--- group bird geometries by engl_name
CREATE TABLE data(id SERIAL PRIMARY KEY, name VARCHAR);
SELECT AddGeometryColumn('public', 'data', 'geometry', 900913, 'MULTIPOLYGON', 2);
CREATE INDEX data_geom ON data USING GIST(geometry);
INSERT INTO data (name, geometry) SELECT engl_name AS name, st_multi(st_union(setsrid(geometry,900913))) AS geometry FROM birds WHERE st_area(geometry) < 1e14 AND geometrytype(geometry) = 'MULTIPOLYGON' GROUP BY engl_name;

--- generate grid features
CREATE TABLE grid(id SERIAL PRIMARY KEY, count INTEGER, names VARCHAR, lon FLOAT, lat FLOAT, bounds VARCHAR);
SELECT AddGeometryColumn('public', 'grid', 'geometry', 900913, 'POLYGON', 2);
CREATE INDEX grid_geom ON grid USING GIST(geometry);

INSERT INTO grid (geometry) (SELECT ST_Translate(cell, x * 78271.516953125 + 0, y * 78271.516953125 + 0)
  FROM generate_series(-256, -1) AS x, generate_series(0, 255) AS y,
  (SELECT ST_ConvexHull(ST_GeomFromText('POLYGON((0 0, 0 78271.516953125, 78271.516953125 78271.516953125, 78271.516953125 0,0 0))',900913)) AS cell) AS geometry);

-- limit grids to those covering north america land
DELETE FROM grid WHERE id NOT IN (SELECT id FROM grid g JOIN land l ON st_intersects(g.geometry, setsrid(l.geometry, 900913)));
DELETE FROM grid WHERE id NOT IN (SELECT id FROM grid g JOIN regions r ON st_intersects(g.geometry, setsrid(r.geometry, 900913)) AND r.region = 'North America');

-- calculate carmen lon/lat/bounds
UPDATE grid SET lon = x(centroid(transform(geometry, 4326))), lat = y(centroid(transform(geometry, 4326))), bounds = xmin(transform(geometry, 4326))||','||ymin(transform(geometry, 4326))||','||xmax(transform(geometry, 4326))||','||ymax(transform(geometry, 4326));
" | psql -U postgres bird_species
}

calcgrid() {
for (( i=0; i <= 8; i++ )); do
  F=`echo "$i*10" | bc`
  T=`echo "($i+1)*10" | bc`
  (echo "UPDATE grid g SET count = (SELECT count(name) FROM data WHERE st_intersects(geometry, g.geometry)) WHERE ymin(transform(geometry,4326)) BETWEEN $F AND $T;" | psql -U postgres bird_species) &
  (echo "UPDATE grid g SET names = (SELECT array_to_string(array_agg(name ORDER BY st_area(geometry) ASC), ', ') FROM data WHERE st_intersects(geometry, g.geometry)) WHERE ymin(transform(geometry,4326)) BETWEEN $F AND $T;" | psql -U postgres bird_species) &
done
wait
echo "DELETE FROM grid WHERE count < 1;" | psql -U postgres bird_species
}

finish() {
  ogr2ogr -nln data -f "SQLite" bird-species.sqlite PG:"host=localhost user=postgres dbname=bird_species" grid
  rm -rf $TMP
}

download
process
topostgis
makedata
calcgrid
finish
