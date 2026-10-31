---
title: Styles are objects
version: 1
---

**A style in React Native is a JavaScript object passed to the `style` prop**, with names that look
like CSS written in camelCase and numbers without units: `{ fontSize: 17, paddingHorizontal: 16 }`.
There is no stylesheet file, no class name and no selector. Each element gets exactly the style its
own `style` prop says, and nothing else.

## StyleSheet.create

The planner's components keep their styles at the bottom of the file, in a `StyleSheet.create` call,
as `CourseRow` will in the last section:

```tsx
const styles = StyleSheet.create({
  name: { fontSize: 17, fontWeight: "600" },
  count: { fontSize: 14 },
});
```

`StyleSheet.create` returns the same object it was given, typed: TypeScript knows that `fontWeight`
accepts `"600"` and refuses `"semi-bold"`. Keeping styles there rather than inline in the JSX is a
convention for reading, not a performance rule; an inline object works the same way, and the planner
uses inline objects for the one or two values that depend on the theme.

## Arrays, and the last one wins

`style` also takes an **array**, applied left to right, where a later object overrides an earlier one
property by property, and `false`, `null` and `undefined` are skipped:

```tsx
style={[styles.row, { borderColor: t.line }, pressed && { backgroundColor: t.pressed }]}
```

That one line is the whole of what CSS does with a base class, a modifier and a state. **The order in
the array is the only precedence there is.** No specificity to calculate, no `!important`, no rule in
another file that happens to match.

## Why this is the trade the platform makes

On the web, a rule written for one page reaches every element its selector matches, which is powerful
and is why large stylesheets become hard to change: nobody knows what else a rule touches. **A style
here reaches exactly the element it is attached to.** Reuse is by ordinary JavaScript: export an
object, import it, put it in an array. A component library is a set of components that bring their own
styles, and changing one cannot break a screen that does not use it.

The cost is that there is no inheritance to rely on, with one exception, text inside text, which
lesson 4 showed. A font set on the screen's outer `View` reaches no `Text` at all. The section on the
CSS that is not here lists what else is missing and what replaces it.
