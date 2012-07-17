#!/bin/bash

curl -sf http://www.astronexus.com/files/downloads/hygxyz.csv.gz | gzip -d > hygxyz.csv && \
  python data.py && \
  ogr2ogr -f "SQLite" stars.sqlite stars.shp && \
  sqlite3 stars.sqlite "ALTER TABLE stars ADD COLUMN named INTEGER; CREATE INDEX stars_named ON stars(named); UPDATE stars SET named = name IS NOT NULL OR hr IS NOT NULL;" && \
  rm hygxyz.csv stars.???

echo "Data written to stars.sqlite."
