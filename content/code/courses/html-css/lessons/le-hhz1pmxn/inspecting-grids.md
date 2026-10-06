---
title: Seeing the grid: DevTools
version: 1
---

A grid is invisible. The tracks, the lines and the gaps are not drawn, so a layout that goes wrong usually looks like "the items are in the wrong place" with no indication of why. **DevTools draws the grid for you**, and this is the habit that saves the most time:

1. **In the Elements panel, find the grid container.** Every element with `display: grid` has a small **grid** badge beside it in the tree. Click it, and the grid is drawn over the page: the tracks outlined, the gaps hatched.
2. **Open the Layout pane**, beside Styles and Computed. It lists every grid on the page with a checkbox to show its overlay, and options to show **line numbers**, **track sizes** and **area names** on the overlay.
3. **Turn on line numbers.** They are drawn at both ends of every line, positive and negative, which is exactly what you need to read or write `grid-column: 2 / -1`.
4. **Turn on track sizes**, and each track is labelled with the size you wrote and the size it came to: `1fr` and `189.33px`, the same pair this lesson computed for `tracks.html`.
5. **Turn on area names**, and the named areas are labelled where they are, which is the template drawn back onto the page.

The Computed pane shows `grid-template-columns` resolved to pixels, as `probe style` did for `autofit.html`: that is how this lesson saw the collapsed `0px` track of `auto-fit`. Firefox's grid inspector, which came first, does the same and draws a little more.

## Three things to check when a grid misbehaves

**The items are not grid items.** `display: grid` applies to the direct children only; a wrapper `<div>` between the grid and the cards makes the wrapper the single grid item.

**An area name is misspelt, or an area is not a rectangle.** The whole `grid-template-areas` value is then invalid and ignored, and DevTools strikes it through in the Styles pane, which is lesson 5's warning sign again.

**Content forces a track wider than intended.** A `1fr` track has a minimum of `auto`, which means it will not shrink below its content: the same floor as lesson 8 section 08. `minmax(0, 1fr)` removes it.
