---
title: Type, colour and dark mode in each guide
version: 1
---

**Both guides answer the same three questions about how a screen looks, which font, which colours
and what happens at night, and they answer from opposite ends.** Material hands the app a set of
named slots and expects it to fill them. The HIG hands the app the system's own font and colours and
expects it to use them, so that the user's settings reach it. The planner has to sit comfortably in
both, and the difference decides what it writes down for each.

## The font

**Material's type scale is fifteen named styles in five groups**: display, headline, title, body and
label, each in large, medium and small. Android's documentation on Material 3 in Compose lists the
defaults, all in Roboto, and gives each a size and a line height in `sp`: `bodyLarge` is 16/24,
`titleLarge` 22/28, `labelSmall` 11/16. An app is free to change the family and the sizes; the names
stay, and the components ask for a name rather than a number.

**The HIG's answer is the system font, San Francisco, through text styles.** "San Francisco (SF) is
a sans serif typeface family", in the HIG's words, with SF Pro among its variants. An app rarely names it: it asks for a **text style**, `.body`, `.headline`, `.largeTitle`, and
the system picks the font, the weight and the size. The HIG's table for iPhone gives `.body` as 17
points and `.largeTitle` as 34 at the default size, and it gives the table eleven more times, once
for every size the user can choose, from xSmall to the largest accessibility size.

That repetition is the point, and it is called **Dynamic Type**. A person who sets a larger text size
in Settings gets larger text in every app that asked for text styles, and none in an app that asked
for "17 points". Android does the same through the `sp` unit, which its documentation describes as "scaled by the
user's font size preference". Lesson 19 tests what that does to a layout. **For this lesson, the rule is that a size is
asked for by its role**, never fixed as a number, on both platforms.

| | Material 3 | the HIG, on iPhone |
|---|---|---|
| the family | Roboto by default, replaceable | the system font, San Francisco |
| how text asks for a size | a role in the type scale, such as `bodyLarge` | a text style, such as `.body` |
| body text at the default size | 16 sp | 17 pt |
| the user's larger text | `sp` follows the font size setting | Dynamic Type, one table per size |

## The colours

**Material names colours by role.** *Primary* is "used for main components like prominent buttons,
active states", *on primary* is the colour of whatever sits on primary, *surface* is the
background things sit on, *on surface* the text on it. Android's documentation describes each
role as coming from a key colour and a tonal palette of thirteen tones. The app picks the five key
colours, and the roles follow.

**Dynamic colour can replace those choices.** On Android 12 and later, an app that asks for a
dynamic colour scheme gets one derived from the user's wallpaper. That is an app's choice, not the
system's: an app that wants its brand's green everywhere keeps its own scheme and does not ask.

**The HIG names colours by meaning, and keeps the values.** Its dynamic system colours "automatically adapt
to both light and dark contexts", and its page on colour asks apps to avoid "hard-coding system
color values", because the values change between releases. The text colours are *label*,
*secondary label* and so on, and an app that uses them never has to choose a grey. The brand enters
as one **tint**, the colour of controls and links.

**Depth is the last difference.** Material 3 shows a raised surface mainly by a tone: a card higher
up is drawn in a slightly more coloured version of the surface, with or without a shadow. The HIG
uses **materials**, and since 2025 Liquid Glass, a translucent layer for bars and controls that lets
the content beneath show through.

## Dark mode

**Dark mode is a system setting on both, and both expect the app to follow it.** Material's theme
defines a light and a dark scheme, and Compose picks one from `isSystemInDarkTheme()`. The HIG says
an app-specific appearance setting "creates more work for people", and asks that colours be
checked "in all appearances": its dark mode page puts the floor at 4.5:1 between text and its
background, a ratio lesson 19 computes. So the planner needs a dark value for every colour it
chooses, chosen rather than computed: inverting the light palette turns the brand's deep green into
a mauve pink, `#D090B1`, that nobody picked. The planner's dark set is its own: a near-black grey surface, `#1C1B1F`,
text in a soft white, `#E6E1E5`, and a lighter green, `#8FD3AE`, for the accent.
