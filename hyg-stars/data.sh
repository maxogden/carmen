#!/bin/bash

curl -sf http://www.astronexus.com/files/downloads/hygxyz.csv.gz | gzip -d > hygxyz.csv && \
  python data.py && \
  ogr2ogr -f "SQLite" stars.sqlite stars.shp && \
  rm hygxyz.csv stars.???

echo "Data written to stars.sqlite."
