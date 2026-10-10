---
title: PostGIS, from a package of its own
version: 1
---

**PostGIS adds geographic types and several hundred functions to PostgreSQL**: points, lines and
areas on the Earth, and questions such as how far, what is inside and what is nearest. It is not a
contrib module. It is a separate project with its own releases, and on Ubuntu its package is built
for one major version of the server at a time, which is the detail that matters to a DBA.

## Installing it

The package name carries both versions, the server's and PostGIS's:

```sh
sudo apt install -y postgresql-16-postgis-3
```

That puts the control file, the scripts and the libraries where the server looks for them, exactly
like the contrib files of the first section, and changes nothing inside any database. The
extension is then created where it is wanted:

```
ana=# CREATE EXTENSION postgis;
CREATE EXTENSION

ana=# SELECT postgis_version();
            postgis_version            
---------------------------------------
 3.4 USE_GEOS=1 USE_PROJ=1 USE_STATS=1
(1 row)

ana=# SELECT count(*) FROM pg_depend
ana-#  WHERE refobjid = (SELECT oid FROM pg_extension WHERE extname = 'postgis')
ana-#    AND deptype = 'e';
 count 
-------
   893
(1 row)
```

`pg_depend` with `deptype = 'e'` lists every object that belongs to an extension, and **893 objects
arrived with one command**: types, functions, operators, a table of coordinate systems. The
extension's record is what keeps them together. `DROP EXTENSION postgis` removes all 893, and the
next section shows that a dump writes one line for them.

## Five points and a distance

A point is written as text, `POINT(longitude latitude)`. **Longitude comes first**, which is the
order of x and y and the opposite of how most maps print a coordinate; swapping them puts São
Paulo in the South Atlantic without an error. Save this as `warehouses.sql`:

```sql
-- warehouses.sql: five points, longitude first
CREATE TABLE warehouses (
    name     text PRIMARY KEY,
    location geography(Point, 4326) NOT NULL
);

INSERT INTO warehouses VALUES
    ('São Paulo',    'POINT(-46.6333 -23.5505)'),
    ('Buenos Aires', 'POINT(-58.3816 -34.6037)'),
    ('Mexico City',  'POINT(-99.1332 19.4326)'),
    ('Lisbon',       'POINT(-9.1393 38.7223)'),
    ('Madrid',       'POINT(-3.7038 40.4168)');
```

`geography(Point, 4326)` says the column holds points, and 4326 is the numbering of WGS 84, the
coordinate system GPS uses. Run it, then ask how far each warehouse is from Rio de Janeiro:

```
ana@db:~$ psql -f warehouses.sql
CREATE TABLE
INSERT 0 5
```

```
ana=# SELECT name,
ana-#        round(ST_Distance(location, 'POINT(-43.1729 -22.9068)') / 1000) AS km_from_rio
ana-#   FROM warehouses
ana-#  ORDER BY km_from_rio;
     name     | km_from_rio 
--------------+-------------
 São Paulo    |         361
 Buenos Aires |        1967
 Mexico City  |        7675
 Lisbon       |        7690
 Madrid       |        8116
(5 rows)

ana=# SELECT name FROM warehouses
ana-#  WHERE ST_DWithin(location, 'POINT(-43.1729 -22.9068)', 2000000);
     name     
--------------
 São Paulo
 Buenos Aires
(2 rows)
```

`ST_Distance` on a `geography` answers in metres along the surface of the Earth, so dividing by
1000 gives kilometres: São Paulo is 361 km from Rio. `ST_DWithin` asks *within this many metres*,
which is the question an application asks most, and it can use an index where computing every
distance and filtering cannot.

## geometry is a different type

PostGIS has a second type, `geometry`, that treats coordinates as points on a flat plane. The same
two cities as `geometry`:

```
ana=# SELECT round(ST_Distance('POINT(-46.6333 -23.5505)'::geometry,
ana(#                          'POINT(-43.1729 -22.9068)'::geometry)::numeric, 2);
 round 
-------
  3.52
(1 row)
```

**3.52 is in degrees**, the straight-line distance on a flat drawing of the map, and it is not
361 km in any unit. `geometry` is right for a city's streets projected onto a local flat
coordinate system, where it is faster, and wrong for distances between continents. Which type a
column uses is the developer's decision; noticing that a report of distances came out in degrees
is often the DBA's.
