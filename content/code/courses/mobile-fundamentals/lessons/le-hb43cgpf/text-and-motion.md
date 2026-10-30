---
title: Text that grows, motion that stops, and colour that is not alone
version: 1
---

**Three settings on every phone change what the app has to cope with, and an app that ignores them
breaks quietly for exactly the people who turned them on.** The user picks a larger text size; the
user asks for less motion; and some users cannot tell two colours apart however well they contrast.
None of these shows up on the designer's own phone, which is why each one gets a rule and a test.

## Text at twice its size

**WCAG 2.2's criterion 1.4.4, Resize Text, asks that text can be enlarged "up to 200 percent without
loss of content or functionality"**, and the HIG asks for the same on the phone: "give people the
option to enlarge text by at least 200 percent". Lesson 18 set the planner up for it, by asking for
sizes by role, `bodyLarge` in `sp` on Android and the `.body` text style on iOS, so that the system
can make them larger. That is half the work. The other half is a layout that survives.

**The iPhone's range goes well past 200 percent.** The HIG's tables give `.body` as 17 points at the
default size and 53 at the largest accessibility size, AX5: more than three times as large. At AX2 it
is 33, very nearly double. A row designed around 17-point text and given a fixed height of 44 points
clips its own words at those sizes.

The planner's session row shows what goes wrong, and what the HIG suggests instead:

| at the default size | at twice the size, done badly | at twice the size, done well |
|---|---|---|
| `SQL · Fri 23 Oct · 60 min` and a tick, on one line | the same line, cut off as `SQL · Fri 2…`, in a row of fixed height | the course on one line, the date and length below it, the tick beside them, the row as tall as it needs |

**Three habits keep a layout alive at large sizes.** Let a row's height follow its content instead of
fixing it. Let text wrap onto as many lines as it needs, because the HIG asks to "keep text
truncation to a minimum as font size increases". And where items sit side by side, let them stack:
the HIG's advice for large sizes is "a stacked layout where text appears above secondary items".
Android's `sp` follows the user's font size preference in the same way, so the same habits apply
there. To try it, the HIG names the switch: Settings, Accessibility, Display & Text Size, Larger Text.

## Motion that can be turned down

**Movement on screen can make some people dizzy or unwell**, and both platforms have a setting that
asks apps to move less. The HIG describes iOS's, Reduce Motion, and asks that an app respond by
"reducing automatic and repetitive animations, including zooming, scaling, and peripheral motion",
for instance by replacing a slide with a fade. Android has its own setting to remove animations
among its accessibility options. WCAG's criterion 2.3.3, Animation from Interactions, asks for the
same at its strictest level, AAA: motion triggered by an interaction can be turned off unless it is
essential.

For the planner, the animation worth checking is the one that plays when a session is marked done.
**A tick that fills in is information; a row that bounces and flies off is decoration**, and under
Reduce Motion the decoration goes while the information stays: the tick fills, without the flight.

## Colour that is not alone

**WCAG's criterion 1.4.1, Use of Color, is short: colour must not be "the only visual means of
conveying information"**, and the HIG says the same in its own words, naming the red-green and
blue-orange pairings that people with colour blindness find hard. Contrast, in the previous section,
does not protect against this: a green done row and a red overdue row can each pass 4.5:1 against
white and look identical to somebody who cannot tell red from green.

**The planner's done state therefore has three signals, not one.** The tick is filled or empty, which
is a shape. The row's minutes are struck through or not, which is a text decoration. And the green is
there as well, for everybody who sees it. Take the colour away and the week still says which sessions
are done; and the screen reader, from the earlier sections, hears none of the three and gets "checked"
instead, which is the fourth.

## What none of this replaces

The checks in this lesson are numbers a program can hold: a ratio, a size, a percentage. **What they
cannot hold is whether the app is usable**, and both platforms say so in the same way: turn on the
screen reader, the large text and the reduced motion, and use the app. Android's documentation and
Apple's both describe that test, and the planner's courses after the fork are where it is done on
real screens.
