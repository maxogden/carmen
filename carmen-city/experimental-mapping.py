# -*- coding: utf-8 -*-

import re

from imposm.mapping import (
    Options,
    Points, LineStrings, Polygons, PolygonTable,
    String, Bool, Integer, OneOfInt,
    set_default_name_type, LocalizedName,
    WayZOrder, ZOrder, Direction,
    GeneralizedTable, UnionView,
    PseudoArea, meter_to_mapunit, sqr_meter_to_mapunit,
    DropElem
)

from imposm.db import postgis

import imposm.config
imposm.config.import_partial_relations = True
imposm.config.relation_builder = 'contains'

db_conf = Options(
    # db='osm',
    host='localhost',
    port=5432,
    user='osm',
    password='osm',
    sslmode='allow',
    prefix='osm_new_',
    proj='epsg:900913',
)

class NiceName(LocalizedName):
    pattern = re.compile('(;[ ]*)|( - )', re.UNICODE)
    def value(self, val, osm_elem):
        name = LocalizedName.value(self, val, osm_elem)
        # NOTE: The first is a non-breaking space!!
        return self. pattern.sub(u' — ', name)

# Set default name column to 'name_loc' using NiceName class.
set_default_name_type(NiceName(), 'name_loc')
enfirst = ['name:en', 'int_name', 'name']

place_point = Points(
    name = 'place_point',
    mapping = {
        'place': (
            'city',
            'town',
            'village',
        ),
    },
    fields = (
        ('name_en', NiceName(enfirst)),
        ('z_order', ZOrder([
            'city',
            'town',
            'village',
        ])),
        ('population', Integer()),
    ),
)

place_poly = Polygons(
    name = 'place_poly',
    mapping = {
        'place': (
            'city',
            'town',
            'village',
        ),
        'border_type': (
            'city',
            'town',
            'village',
        ),
        'boundary': (
            'administrative',
        ),
    },
    fields = (
        ('name_en', NiceName(enfirst)),
        ('z_order', ZOrder([
            'city',
            'town',
            'village',
        ])),
        ('population', Integer()),
        ('admin_level', Integer()),
    ),
)

addr_points = Points(
    name = 'addr_points',
    mapping = {
        'addr:city': (
            '__any__',
        )
    },
    fields = (
        ('name_en', NiceName(enfirst)),
    ),
)

addr_lines = LineStrings(
    name = 'addr_lines',
    mapping = {
        'addr:city': (
            '__any__',
        )
    },
    fields = (
        ('name_en', NiceName(enfirst)),
    ),
)

addr_polygons = Polygons(
    name = 'addr_polygons',
    mapping = {
        'addr:city': (
            '__any__',
        )
    },
    fields = (
        ('name_en', NiceName(enfirst)),
    ),
)

