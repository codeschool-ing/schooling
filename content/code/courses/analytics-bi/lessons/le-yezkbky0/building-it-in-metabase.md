---
title: Building the page in Metabase
version: 1
---

Lantern's Monday page, built in the Metabase of lesson 3. Each card is a question saved first, so it
has a name and a description of its own.

1. **Save the questions.** With the editor of lessons 3 and 5: net revenue for the current month;
   orders for the current month; net revenue by month for the last twelve complete months; net
   revenue by region for the current month. Save each into a shared collection, with a description
   that says what it counts. For the comparisons of this lesson's tiles, a SQL question with the
   month-to-date query of the section on partial periods is the honest choice: the editor compares whole periods.
2. **Create the dashboard**: **New**, then **Dashboard**, a name — *Lantern: Monday* — and the shared
   collection. Metabase opens it in editing mode.
3. **Add questions**, the button with that name, and place them in the four bands of the layout
   section: tiles across the top, trend under them, breakdown below.
4. **Add a heading or text box** at the top right: when the data ends, that June is partial until the
   month closes, and where the definitions are. Text cards are where a dashboard's caveats live.
5. **Add a filter or parameter**, choose **Date picker**, then connect it to the cards it should drive
   — card by card, as the last section warned — and set its default.
6. **Save.**

Then open it as a reader would, with a fresh eye: is every number's comparison visible, is the
partial month marked, could somebody who has never read this course misread anything on it? That is
the review in two sections' time, applied to your own page.
