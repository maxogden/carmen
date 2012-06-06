### Sources

- Natural Earth 1.4.0 10m-admin-1-states-provinces

### Notes

    # Importing to PostGIS
    createdb -U postgres -T template_postgis provinces
    ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=provinces" -nlt multipolygon provinces.sqlite

    # Adding centroid lon/lat
    ALTER TABLE data ADD COLUMN lon DOUBLE PRECISION;
    ALTER TABLE data ADD COLUMN lat DOUBLE PRECISION;
    UPDATE data SET lon = X(ST_Transform(ST_Centroid(ST_GeomFromEWKB(wkb_geometry)),4326));
    UPDATE data SET lat = Y(ST_Transform(ST_Centroid(ST_GeomFromEWKB(wkb_geometry)),4326));

    # Back out
    ogr2ogr -f "SQLite" p.sqlite PG:"host=localhost user=postgres dbname=provinces"
    dropdb -U postgres provinces
