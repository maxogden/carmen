#!/usr/bin/env bash

mkdir -p tiles

data=(
  "carmen-city/layers/places.sqlite"
  "carmen-hamlet/layers/hamlets.sqlite"
  "carmen-country/layers/countries.sqlite"
  "carmen-province/layers/provinces.sqlite"
  "carmen-zipcode/layers/zipcodes.sqlite"
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

