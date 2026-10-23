---
title: The window where clicks are lost
version: 1
---

**Between the moment a server-rendered page appears and the moment its script takes it over, every
button on it is a picture of a button.** A click in that window reaches an element with no listener,
does nothing, and is forgotten. On a fast laptop the window is a few milliseconds and nobody finds
it. On a slow phone it is seconds.

`tools/hydrate.ts` can make it seconds on purpose: `--script-delay 2000` holds back every script for
two seconds, and `--click-at 300` clicks *Mark done* 300 milliseconds after the page arrived, when
the page is already painted and the script is still on its way:

```
ana@dev:~/planner$ node tools/hydrate.ts http://localhost:3000/courses/git --script-delay 2000 --click-at 300
```

**The click happened, and the session is still not done.** The page had painted long before, and the
script took over about two seconds later, so the click fell in between. Nothing in the page said it
was not ready, and nothing afterwards said a click had been lost.

```schooling-figure
@fig
```

## Three ways to close it

**Make the window short.** Less JavaScript before hydration, and a server close to the person. That
is lessons 7 and 8, and it is the only fix that also helps everything else.

**Make the page say it is not ready.** A button rendered `disabled` by the server and enabled by the
script cannot be pressed in the window, and looks pressable only when it is. It costs a flash of
greyed-out controls and it tells the truth.

**Record the clicks and play them back.** Angular does this with the `withEventReplay()` in lesson 2's
`app.config.ts`: a small script inline in the page, before anything else, records events on the
whole document, and hydration replays them to the components that now exist. The page Angular sent in lesson 2 carries
that script, `ng-event-dispatch-contract`. React, from version 18, replays some events that land
inside a part of the page still hydrating. **A form with a real `action` is the
oldest version of the idea**: a submit before hydration still goes to the server, and works.

The planner has a form, and its *Add session* would post to the server if it were pressed in the
window; `server.ts` has no handler for that, and lesson 1 said so. The *Mark done* buttons have no
fallback at all.
