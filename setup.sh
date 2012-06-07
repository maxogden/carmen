#!/usr/bin/env bash

mkdir -p tiles

data=(
  "flickr-places/layers/flickr-places.sqlite"
  "osm-places/layers/osm-places.sqlite"
  "ne-countries/layers/ne-countries.sqlite"
  "ne-provinces/layers/ne-provinces.sqlite"
  "tiger-places/layers/tiger-places.sqlite"
  "tiger-zipcodes/layers/tiger-zipcodes.sqlite"
)

for file in "${data[@]}"
do
  if [ ! -f $file ]; then
    BASE=`basename $file`
    DIR=`dirname $file`
    mkdir -p $DIR
    echo "Downloading $BASE..."
    curl -s -o $file "http://s3.amazonaws.com/mapbox/carmen-data/$BASE"
  fi
done

