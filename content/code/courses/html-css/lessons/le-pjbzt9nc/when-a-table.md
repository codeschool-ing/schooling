---
title: When a table is the right element
version: 1
---

**A table is for data that has two dimensions**: every value sits at the meeting of a row and a column, and it means something because of both. The bookshop's opening hours are like that: *7 pm* means nothing alone, and means *Monday to Friday, closes* in its row and its column. A price list, a timetable, a comparison of three editions of one book are all tables. A list of events is not: each event is one thing, and the right element is a list or a set of articles, lesson 2.

## Tables are not for layout

For about a decade, before CSS could lay out a page, people built whole sites out of tables: a row for the header, a column for the menu, a cell for the content. You will still meet them in old pages and, very often, in HTML email, because many email programs supported CSS layout badly. **On a web page, a table used for layout is a mistake**, for the same reason as div soup: it says something false. A screen reader meets a table and offers its user table navigation, *row 2, column 3*, through what is really a menu and an article. And it cannot reflow: a table's columns stay side by side, so on a narrow screen the page overflows instead of stacking. Lessons 8 and 9 do the layout with Flexbox and Grid, which were made for it.

## What a screen reader does with a real table

A table is the one element where the accessibility tree adds the most, because the relations between cells are what make the data readable without seeing the grid. Somebody moving through the hours table cell by cell can hear, at *7 pm*, *Monday to Friday, Closes, 7 pm*: the cell, plus the headers of its row and its column. That only works if the HTML says which cells are headers, which is the next section.
