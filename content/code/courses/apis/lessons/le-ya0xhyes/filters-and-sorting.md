---
title: Filtering and sorting
version: 1
---

**Filters and the sort order go in the query string, every parameter is named in the contract, and
the fields a client may sort by come from a list the server keeps.** A collection with no filters
sends every client every row to throw most of them away; one with filters nobody wrote down gets a
different spelling at every endpoint.

`catalogue.py` takes two filters and a sort, and they combine. Machado de Assis's books, newest first;
everything out of stock; and the three most expensive:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?author_id=1&sort=-year' | jq -c '.items[] | {id, title, year}'
{"id":1,"title":"Dom Casmurro","year":1899}
{"id":7,"title":"Quincas Borba","year":1891}
{"id":2,"title":"Memórias Póstumas de Brás Cubas","year":1881}
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?in_stock=false' | jq -c '.items[] | {id, title, stock}'
{"id":3,"title":"A Hora da Estrela","stock":0}
{"id":7,"title":"Quincas Borba","stock":0}
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?sort=-price&limit=3' | jq -c '.items[] | {title, price: .price.amount_cents}'
{"title":"Americanah","price":6490}
{"title":"Ensaio sobre a Cegueira","price":5990}
{"title":"Memórias Póstumas de Brás Cubas","price":4490}
```

A minus sign in front of a field sorts it in descending order. Other APIs write the same thing as
`sort=price&order=desc`; either works if it is the only one. Behind each sort, `catalogue.py` adds
the id as a second key, so that two books from the same year always come back in the same order. SQL
promises nothing about the order of rows that tie, and without that second key two requests for the
same page could disagree.

## An allowlist for sorting

The tempting implementation takes the field name from the query string and puts it into
`ORDER BY`. It cannot be passed as a bound parameter, because SQL parameters carry values, never
column names, so it would have to be pasted into the SQL text, and then whatever the client typed
becomes part of the query. `catalogue.py` keeps a dictionary instead, `SORTS`, from each public
name to a column. Only a name in it is accepted, and only the column it maps to reaches the SQL:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?sort=isbn' | jq -r .detail
sort takes id, title, year, price, with a leading - for descending
```

The dictionary does a second job. The public name `price` maps to the column `price_cents`, so the
contract is free to name things for clients rather than after the table. And it is a list of what
can be made fast: every field in it is one the database should have an index for.

## An unknown parameter is an error

The quiet failure here is a typo. A client that asks for `?auther_id=1`, or for a filter the API never
had, gets the whole catalogue back with a 200, and believes it was filtered. `catalogue.py` refuses
what it does not recognise, and checks the values of what it does:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?colour=red' | jq -r .detail
/v1/books does not take: colour
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?in_stock=yes' | jq -r .detail
in_stock is true or false
```

**A cursor belongs to its sort.** The `after` value from a walk sorted by id means nothing in a walk
sorted by title, and the cursor carries the sort it was made for, so a mismatch is refused rather
than answered with the wrong page:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?sort=title&after=WyJpZCIsIDIsIDJd' | jq -r .detail
after takes the cursor of a next link, with the same sort
```

Ranges and multiple values have conventions too, such as `year_min=1900` or `author_id=1,2`. None of
them is standard; pick one, write it down, and use it at every endpoint.
