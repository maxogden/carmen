#!/bin/bash

mkdir -p layers

if [ ! -f layers/bird-species.sqlite ]; then
  echo "Downloading bird-species.sqlite..."
  curl -sfo layers/bird-species.sqlite http://mapbox.s3.amazonaws.com/carmen-examples/bird-species.sqlite
fi
