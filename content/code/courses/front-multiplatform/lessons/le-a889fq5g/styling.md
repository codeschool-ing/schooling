---
title: Styling without CSS
version: 1
---

**A React Native style is a JavaScript object, and most of its names are CSS names in camelCase**:
`backgroundColor`, `fontSize`, `borderRadius`. That resemblance is the trap. Four differences from CSS
explain almost every surprise:

1. **Flexbox is the only layout, and its direction defaults to `column`.** Everything stacks
   vertically until a parent says `flexDirection: "row"`, which is how each session row in this lesson
   puts its date and its button side by side. There is no `float`, no `grid` and no `display: block`.
2. **Nothing cascades.** A colour or a font on a `View` reaches none of the `Text` inside it, and there
   are no selectors and no classes: each component gets its own style. The one exception is that a
   `Text` inside a `Text` takes its parent's text styles.
3. **Numbers have no unit.** `padding: 16` is sixteen density-independent pixels, a unit that is the
   same physical size on a phone with a dense screen and one without. Percentages exist as strings,
   `width: "50%"`; `rem`, `em` and `vh` do not.
4. **The platforms still differ.** A shadow is `boxShadow` in recent versions, and it renders
   differently on Android and iOS; fonts, the keyboard and the status bar differ too. `Platform.OS` and
   `Platform.select({ ios: …, android: … })` are how a style says so.

```tsx
const styles = StyleSheet.create({
  row: { flexDirection: "row", justifyContent: "space-between", paddingVertical: 10 },
  action: { color: "#0a58ca", fontWeight: "600" },
});
```

**`StyleSheet.create` is the usual way to write them**, outside the component, so the objects are made
once rather than on every draw and the names read like class names. A style is passed with `style=`,
and an array, `style={[styles.input, problem && styles.wrong]}`, combines several, the later ones
winning.

*The rule about cascading is the documented behaviour on a phone; the web build, which turns styles into
CSS, can let a colour on a `View` reach its text, which is one more case of the browser being lenient
where the phone is strict. This course could only run the web build.*

## Colours that pass

The planner's blue on white is `#0a58ca`, a contrast of more than 6 to 1, and its white text on the
same blue the same, so both pass WCAG 2.2 AA for normal text, which asks for 4.5. A phone adds a
setting the web often ignores: **the person's text size**. React Native scales `Text` with the system's
font size by default, and a layout with fixed heights is where text grown by the system gets cut off.
Give rows padding, not heights.
