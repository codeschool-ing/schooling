---
title: "LCP: when the main thing appeared"
version: 1
---

**Largest Contentful Paint is the time from the start of the navigation until the largest image or
block of text in the window was painted.** It stands for the moment a person decides the page has
loaded, which is not the first pixel but the moment the thing they came for is there. A page that
paints a header in 200 milliseconds and its article in three seconds has an LCP of three seconds.

## What counts as the largest

The browser keeps a candidate as the page loads and replaces it whenever something larger is painted:

- images, including an image drawn as a CSS background and the poster of a video;
- blocks of text, measured by the area of the text itself, not of its box;
- only what is inside the window, and only its visible part.

**The candidate stops changing at the first interaction**, a tap, a click or a key, or when the
page is hidden. After that the page is the person's, and what loads later is not part of the load.
That is why a page can have a late LCP because of something nobody asked for, and the section "A
layout shift, made and removed" finds exactly that in the planner: the largest text on the course
page is a notice that arrives after everything else.

## Four parts of one number

The `web-vitals` library splits an LCP into four parts, and each one points at a different fix:

| part | what it is | the usual fix |
|---|---|---|
| time to first byte | until the HTML began to arrive | a faster server, a closer one, a cache (lesson 9) |
| resource load delay | until the LCP image began to load, if it is an image | let the browser discover it in the HTML, not from a script (lesson 7) |
| resource load duration | how long the image took to download | a smaller image (lesson 7) |
| element render delay | from having it to painting it | less blocking CSS and script (lessons 7 and 8) |

For the planner, whose largest element is text, the second and third parts are zero, and the number
is the server's time plus whatever held back the paint. Lesson 1's measurement was already this
number in all but name: the client-rendered page painted its content at 948 milliseconds with every
request slowed, and the server-rendered one at 640.

**The threshold is 2.5 seconds for good and 4 seconds for poor**, measured as the section
"Good, needs improvement, poor" describes.
