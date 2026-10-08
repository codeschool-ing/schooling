---
title: Tile maps and cartograms
version: 1
---

The maps in this lesson draw every state as the same square. That is not a shortcut; it is a design
with a name, the tile map, and it solves the problem the second section raised: **on a
geographic map, big places dominate**.

On a real map of Brazil, Amazonas, Pará and Mato Grosso together cover nearly half the country, and
hold about 8% of its people. Whatever value a choropleth shows, those three states paint most of the
picture. The Federal District, the best state by rate, is a dot you can barely see.

A tile map **gives every state the same weight**, which is right when every state counts as one: a
ranking, a policy, a vote. The positions keep a rough sense of geography, so neighbours stay
neighbours and the North stays at the top.

## What a tile map gives up

- **Shape and size.** Nobody recognises a state by its square. The labels have to be there, as they
  are in the first figure of this lesson.
- **Exact adjacency.** Some neighbours cannot touch in a grid. In this layout, Tocantins sits beside
  Goiás but not beside Bahia, though the two share a long border.
- **Area as information.** When the size of the place is part of the story, such as farmland or
  forest, a tile map hides it.

## Cartograms

A **cartogram** goes further and resizes each area by the data: a state with twice the orders is
drawn twice as large, bending the borders to fit. It is striking, and it combines the strengths of a
symbol map and a shaded map, at the price of a map nobody recognises without practice. Use one when
the audience already knows the real map well, and pair it with the real one when they do not.

## Where the real shapes come from

To draw the real borders, a tool needs a **geographic file** describing each state's outline:
shapefiles or GeoJSON, published for Brazil by IBGE, the national statistics institute. Power BI and
Tableau include common boundaries; in Python, libraries such as geopandas read the files and draw
them with matplotlib. Lesson 20 compares the tools.
