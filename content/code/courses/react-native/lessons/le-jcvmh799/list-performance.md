---
title: Long lists that scroll smoothly
version: 1
---

**A FlatList is fast by default; a few habits make it slow.** Each item of this section is a known cause
of a list that stutters or flashes blank space while scrolling, and the fix for each is local.

## Do not redraw every row on every change

When the screen re-renders, the FlatList re-renders, and by default every rendered row runs its
`renderItem` again even if its item did not change. Two things stop that:

- **`React.memo` on the row component.** A memoised `CourseRow` re-renders only when its props change.
- **Stable props.** A function written inline, `onOpen={(id) => setOpen(id)}`, is a new function on every
  render, which counts as a changed prop and defeats the memo. Passing `setOpen` itself, as the planner
  does, is stable; lesson 9's `useCallback` makes other functions stable.

Lesson 19 measures the difference with React's profiler, rather than assuming it.

## Tell the list the row height, when it is fixed

A FlatList measures each row after rendering it, to know where the next one goes and how far the
scrollbar should be. When every row has the same height, `getItemLayout` tells it in advance, which makes
scrolling to an item instant and removes a measurement per row:

```tsx
getItemLayout={(_, index) => ({ length: 62, offset: 62 * index, index })}
```

62 is the height lesson 5 measured for the planner's rows. If the person's text size grows, so do the
rows, and a fixed `getItemLayout` becomes wrong; use it only for rows whose height cannot change.

## Images in rows

A list of pictures is the heaviest list there is. Each image is decoded to its full size in memory, so
thumbnails should be served at thumbnail size, and a list should use an image component that caches and
downsamples, `expo-image` for instance. Lesson 19 measures what a full-size photo in a small row costs.

## When FlatList is not enough

**FlashList**, from Shopify, recycles row components instead of creating and destroying them, which
helps lists of thousands of complex rows on slower Android phones. It is a separate library with its own
rules about sizing. The planner does not need it, and a list that does should be measured before and
after switching, as lesson 19 does for the changes above.
