---
title: A label nobody mapped
version: 1
---

**The most important line in `categorise.py` is the one that stops.** A mapping table is complete for
the data it was written against, and the next export will contain something it has never seen: a
new category, a new spelling, a typo nobody has made yet.

There are three things the code could do with it, and only one is safe:

- **drop the row**: the product disappears from every report, silently;
- **map it to a default** such as `Outros`: the product appears, in a group that grows quietly
  until it is the third largest category and nobody knows what is in it;
- **refuse, and name the label**: the cleaning stops until a person adds a line to the table.

To see it work, Ana removes the `emporio` line from the map and runs the step again:

```
ana@lab:~/clean$ cp category_map.csv map.bak && grep -v '^emporio' map.bak > category_map.csv && python -c 'import categorise' ; cp map.bak category_map.csv
3 products have a category the map does not know: ['Empório']
```

The message says how many products are affected and which label they carry. **The fix takes a
minute and is made by somebody who knows what `Empório` means**; the alternative is a silent error
in every sales report for months.

The same refusal is worth adding to every mapping in a pipeline, and lesson 17 makes it a test that
runs on each new export. It is also why the join in `categorise.py` is a left join: an inner join
would have dropped the unmapped products before the check could count them.
