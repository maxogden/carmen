import shapely
import fiona
from fiona import collection
import csv

star_csv = csv.reader(open('hygxyz.csv', 'rb'))

header = star_csv.next()

max_x = 10000000
min_x = -10000000
max_y = 10000000
min_y = -10000000

"""
x: 17
y: 18
"""

schema = {
    'geometry': 'Point',
    'properties': {
        'MAG': 'float',
        'COLOR': 'float',
        'NAME': 'str',
        'HD': 'str',
        'HR': 'str',
        'GLIESE': 'str',
        'BF': 'str'
    }
}

extent = 20037508.34
world_width = 20037508.34 * 262144 

# Open a new sink for features, using the same format driver
# and coordinate reference system as the source.
with collection(
        "stars.shp", "w",
        crs = {
            "type": "name",
            "properties": {
                "name": "EPSG:900913"
            }
        },
        driver = "ESRI Shapefile",
        schema = schema) as sink:
    for row in star_csv: #range(10000):
        #row = star_csv.next()
        x = float(row[17])
        y = float(row[18])
        lon = ( ( (x - min_x) / (max_x - min_x) ) * world_width - (world_width / 2) )
        lat = ( ( (y - min_y) / (max_y - min_y) ) * world_width - (world_width / 2) )
        if (abs(lon) > extent or abs(lat) > extent):
            continue
        if row[16]:
            color_index = float(row[16])
        else:
            color_index = 0
        abs_magnitude = float(row[14])
        proper_name = row[6]
        f = {
                "properties": {
                    "MAG": abs_magnitude,
                    "NAME": proper_name,
                    "COLOR": color_index,
                    "HD": row[2],
                    "HR": row[3],
                    "GLIESE": row[4],
                    "BF": row[5]
                },
                "geometry": {
                    "type": "Point",
                    "coordinates": [lon, lat]
                }
        }
        sink.write(f)
