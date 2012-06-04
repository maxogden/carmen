-- Create table with:
-- shp2pgsql -W LATIN1 -s 4326 -c -D -I gadm2.shp gadm2 | psql gis

-- Geometry needs to be clipped to the 900913 bounding box and reprojected to
-- 900913. This is done in two steps via an extra column otherwise it fails.

-- create & populate clipped column
select  addgeometrycolumn(
            'public',
            'gadm2',
            'geom_clipped',
            4326,
            'MULTIPOLYGON',
            2
        );

update  gadm2
set     geom_clipped = st_multi(st_intersection(geom,st_geomfromtext(
            'MULTIPOLYGON(((-180 -85.084059268853,-180 85.084059268853,180 85.084059268853,180 -85.084059268853,-180 -85.084059268853)))')));

-- create & populate reprojected column from clipped column
select  addgeometrycolumn(
            'public',
            'gadm2',
            'geom_merc',
            900913,
            'MULTIPOLYGON',
            2
        );

update  gadm2
set     geom_merc = st_transform(geom_clipped, 900913);

-- create materialized columns to use for geocoding
alter   table gadm2 add column carmen_name character varying(100);
alter   table gadm2 add column carmen_search character varying(150);

-- default name & search values
update  gadm2
set     carmen_name = name_5
where   name_5 is not null;

update  gadm2
set     carmen_name = name_4,
        carmen_search = varname_4
where   name_5 is null
and     name_4 is not null;

update  gadm2
set     carmen_name = name_3,
        carmen_search = varname_3
where   name_5 is null
and     name_4 is null
and     name_3 is not null;

update  gadm2
set     carmen_name = name_2,
        carmen_search = varname_2
where   name_5 is null
and     name_4 is null
and     name_3 is null
and     name_2 is not null;


-- specific overrides
-- ------------------

-- look up a level to replaces useless 'n.a.'s
update  gadm2
set     carmen_name = name_3,
        carmen_search = varname_3
where   name_4 ilike 'n.a.%'
and     name_5 is null;

update  gadm2
set     carmen_name = name_2,
        carmen_search = varname_2
where   (name_4 ilike 'n.a.%' or name_4 is null)
and     name_3 ilike 'n.a.%'
and     name_5 is null;

update  gadm2
set     carmen_name = default,  -- already handled by level above
        carmen_search = default
where   (name_4 ilike 'n.a.%' or name_4 is null)
and     (name_3 ilike 'n.a.%' or name_3 is null)
and     name_2 ilike 'n.a.%'
and     name_5 is null;

-- name_1
update  gadm2
set     carmen_name = name_1,
        carmen_search = varname_1
where   name_1 in (
            'Budapest'
        );

-- name_2
update  gadm2
set     carmen_name = name_2,
        carmen_search = varname_2
where   name_1 in (
            'Moscow City'
        );

-- Use Philippine city names over barangays
update  gadm2
set     carmen_name = name_2,
        carmen_search = varname_2
where   name_0 = 'Philippines'
and     name_2 like '% City';

-- drop water bodies; many do not have useful names
update  gadm2
set     carmen_name = default,
        carmen_search = default
where   coalesce(
            engtype_5,
            engtype_4,
            engtype_3,
            engtype_2,
            engtype_1
        ) = 'Water body';
