# north america - 28 MB

ogr2ogr \
	-f "GeoJSON" \
	-sql \
	"select * from data where name in ( \
		'Antigua and Barbuda','Bahamas','Barbados','Belize','Canada','Costa Rica','Cuba', \
		'Dominica','Dominican Republic','El Salvador','Grenada','Guatemala','Haiti','Honduras', \
		'Jamaica', 'Mexico', 'Nicaragua', 'Panama', 'Saint Kitts and Nevis', 'Saint Lucia', \
		'Saint Vincent and the Grenadines','Trinidad and Tobago','United States')" \
	na-countries.geojson \
	qs-countries.sqlite

# south america

ogr2ogr \
	-f "GeoJSON" \
	-sql \
	"select * from data where name in ( \
		'Argentina','Bolivia','Brazil','Chile','Colombia','Ecuador', \
		'Guyana','Paraguay','Peru','Suriname','Uruguay','Venezuela')" \
	na-countries.geojson \
	qs-countries.sqlite