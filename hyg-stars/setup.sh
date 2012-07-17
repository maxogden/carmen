#!/bin/bash

mkdir -p layers

if [ ! -f layers/stars.sqlite ]; then
  echo "Downloading stars.sqlite..."
  curl -sfo layers/stars.sqlite http://mapbox.s3.amazonaws.com/carmen-examples/stars.sqlite
fi
