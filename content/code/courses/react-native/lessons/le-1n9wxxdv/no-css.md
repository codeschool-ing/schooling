---
title: The CSS that does not exist here
version: 1
---

**Most of what makes CSS powerful is missing on purpose**, and each missing piece has a replacement that
is ordinary code. Knowing the list saves a long search for a property that was never there.

| on the web | here | what you write instead |
|---|---|---|
| selectors, classes, the cascade | none | a style object per element; reuse by importing it |
| inheritance of fonts and colours | only from a `Text` to the `Text` inside it | pass the colour, or read it from a theme, as the dark-mode section does |
| `:hover`, `:active`, `:focus` | none | `Pressable`'s `pressed`, and state you keep |
| media queries | none | `useWindowDimensions` and `useColorScheme`, read in the component |
| `display: grid`, floats | none | rows and columns of flex, or `flexWrap: "wrap"` |
| `px`, `em`, `rem`, `vh` | none | plain numbers, percentages, `flex` |
| `box-shadow` on both platforms | `boxShadow` exists, and is drawn by each platform | check it on both, lesson 6 |
| CSS transitions and keyframes | none | lesson 12's animation libraries |

## What is the same

The box model is: `margin`, `padding`, `borderWidth`, `borderRadius`, with `Horizontal` and `Vertical`
shorthands added, `paddingHorizontal: 16` for left and right at once. `position: "absolute"` with `top`,
`left`, `right` and `bottom` works as on the web, relative to the parent. `zIndex` orders siblings.
`opacity`, `transform` and `overflow` behave as you expect, and `gap` spaces flex children.

## Two traps from the web

**`display: "none"` exists and is rarely right.** It removes the element from the layout and keeps it
in the tree, mounted, with its state. To show something conditionally, render it conditionally,
`{open && <Panel />}`, as the planner's status line does.

**Percentages need a parent with a size.** `width: "50%"` inside a parent whose width comes from its
content is a percentage of something that depends on the child, and Yoga resolves the circle by giving
up. In a column whose children stretch, which is the default, it works; inside a row whose children are
sized by content, it does not.
