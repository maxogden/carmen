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

places = Points(
    name = 'places',
    mapping = {
        'place': (
            'city',
            'town',
            'village',
            'hamlet'
        ),
    },
    fields = (
        ('name_en', NiceName(enfirst)),
        ('z_order', ZOrder([
            'city',
            'town',
            'village',
            'hamlet'
        ])),
        ('population', Integer()),
    ),
)
