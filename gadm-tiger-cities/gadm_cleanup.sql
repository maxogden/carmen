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
