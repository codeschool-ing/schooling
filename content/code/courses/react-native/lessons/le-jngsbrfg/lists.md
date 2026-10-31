---
title: Lists that stay smooth
version: 1
---

Lesson 7 showed why `FlatList` exists: it creates the rows near the screen and not the thousand behind
them. The last section saw the same from the other side, five rows of fifty. **A list stutters when a frame
needs rows it has not made yet**, and the props that decide how many it makes, and when, are the tools:

- **`initialNumToRender`**, 10 by default, is how many slots the first render makes. Enough to fill the
  screen once is right; more delays the first frame.
- **`windowSize`**, 21 by default, measured in screens: how much of the list is kept rendered around the
  visible part, ten screens above and ten below. A smaller window saves memory and work and shows blank
  rows sooner on a fast fling.
- **`maxToRenderPerBatch`** and **`updateCellsBatchingPeriod`** decide how many rows are made per pass
  while scrolling, and how often.
- **`getItemLayout`**, when every row has the same height, tells the list where row 500 is without
  measuring the 499 before it, so scrolling to it, or jumping with the scrollbar, needs no layout of the
  rows in between.
- **`keyExtractor`**, from lesson 7, keeps React from rebuilding rows that only moved.

**And the row itself is most of it.** A list renders rows constantly while it scrolls; a row that renders
fast and rarely, the last two sections' `memo` and stable callbacks, is worth more than any of these
numbers.

**FlashList**, from Shopify, takes a different approach: it recycles the native views of rows that left
the screen for the rows entering it, as Android's `RecyclerView` and iOS's `UICollectionView` do natively,
instead of making new ones. For long lists of similar rows it is often the bigger win. *The planner's lists
are short, so this course did not install it.*
