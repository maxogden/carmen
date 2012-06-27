#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage:   localize.sh [file]"
  echo "Example: localize.sh countries.sqlite"
  exit 1
fi

touch localize.sql
echo "BEGIN TRANSACTION;" >> localize.sql

for lang in fr es de; do
  if [ -z `sqlite3 "$1" ".schema data" | grep -o "name_$lang"` ]; then
    echo "Adding column name_$lang to data..."
    sqlite3 "$1" "ALTER TABLE data ADD COLUMN 'name_$lang' VARCHAR;"
  fi
  echo "Adding localized names for name_$lang..."
  curl -s http://unicode.org/cldr/trac/export/7345/tags/release-21-0-2/common/main/$lang.xml | \
    grep -o '<territory type="[A-Z]*">[^<]*</territory>' | \
    grep -o '"[A-Z]*">[^<]*' | \
    tr -d '"' | \
    tr ">" "," | \
    sed "s/^\([^,]*\),\(.*\)$/UPDATE data SET name_$lang=\"\2\" WHERE iso2=\"\1\";/" >> localize.sql
done

echo "COMMIT;"  >> localize.sql

sqlite3 "$1" < localize.sql
rm localize.sql
