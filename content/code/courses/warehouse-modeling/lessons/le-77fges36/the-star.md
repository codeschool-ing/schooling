---
title: The star
version: 1
---

Lesson 2 built a fact table and four dimensions, and joined each dimension to the fact table by one
key. Draw that, with the fact table in the middle, and it is a **star**: a hub with points, and
nothing beyond the points.

**The shape is the definition.** A star schema is one fact table, and dimensions that are each
exactly one join away from it. A dimension never joins to another dimension. Whatever describes a
book, all the way up to its department, lives in `dim_book`; whatever describes a shop, down to its
region, lives in `dim_shop`.

Two consequences follow from that, and they are why the star is the default:

- **Every query has the same shape.** Start at the fact table, join out to the dimensions the
  question mentions, filter and group by their columns, sum the measures. A person who has written
  one query against a star can write the next one without a diagram.
- **The database can rely on the shape.** The fact table is large and the dimensions are small, so
  the plan is nearly always the same: read the small tables, build a lookup from each, and stream
  the large one past them once. Analytical databases are built around that plan, and some of them
  recognise a star by its shape and choose it without being told.

A warehouse usually has several stars, one per business process. Ana's has five fact tables, and
section 09 is about the dimensions they share. The word **constellation** is sometimes used for
that, and it does not change anything about each star.
