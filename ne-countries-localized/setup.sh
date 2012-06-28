#!/bin/bash

mkdir -p layers

if [ ! -f layers/ne-countries-localized.sqlite ]; then
  echo "Downloading ne-countries-localized.sqlite..."
  curl -s http://mapbox.s3.amazonaws.com/carmen-examples/ne-countries-localized.sqlite > layers/ne-countries-localized.sqlite
fi
