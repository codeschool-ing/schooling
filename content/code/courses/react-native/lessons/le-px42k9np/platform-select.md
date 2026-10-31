---
title: Platform.select, a value per platform
version: 1
---

**`Platform.select` takes an object keyed by platform and returns the value for the one the app is
running on.** It is the tidy form of a chain of ternaries, and the usual place for it is a style.

## Shadows, the classic case

**The two platforms draw shadows differently**, and for most of React Native's history each needed its
own properties. iOS draws a shadow from four of them, colour, opacity, radius and offset, under any view
with a background. Android draws it from one, `elevation`, a height above the surface from which the
system works out the shadow itself. A raised card needs both. Save this as `src/card.ts`:

```typescript
// src/card.ts: a raised card, which each platform draws its own way.
import { Platform, type ViewStyle } from "react-native";

export const card: ViewStyle = {
  borderRadius: 12,
  padding: 16,
  ...Platform.select<ViewStyle>({
    ios: { shadowColor: "#000", shadowOpacity: 0.12, shadowRadius: 8, shadowOffset: { width: 0, height: 2 } },
    android: { elevation: 3 },
    default: { boxShadow: "0 2px 8px rgba(0, 0, 0, 0.12)" },
  }),
};
```

The spread, `...Platform.select(…)`, merges the chosen object into the card's style. `default` covers
every platform not named, here the web, which uses a CSS-like `boxShadow`. React Native 0.76 added
`boxShadow` as a style for the phones too, drawn the same way on both, so a new project may use it
everywhere; the two older forms remain in nearly every library and answer you will read, which is why
this card shows them.

## What it returns

`Platform.select` returns the value, not a style or a component, so it works for anything:

```tsx
const keyboardOffset = Platform.select({ ios: 64, android: 0, default: 0 });
const title = Platform.select({ ios: "Settings", android: "Preferences", default: "Settings" });
```

The second line is the kind worth thinking twice about. Each platform has a word its users expect in some
places, and following it makes the app feel native; but a text that differs per platform is also two
texts to translate and two to test. **Use the platform's word where people look for it**, in a menu
title or a system action, and the same word everywhere else.

## When a value is not enough

A shadow is a value. A date picker is not: on iOS it is a wheel or a calendar inline in the screen, on
Android a dialog that opens over it, and the code around each is different. When the difference is a
whole component's worth, the next section's file extensions keep each version in a file of its own,
instead of one file full of branches.
