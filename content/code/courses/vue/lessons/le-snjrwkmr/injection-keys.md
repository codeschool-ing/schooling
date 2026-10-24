---
title: Keys, and why a Symbol
version: 1
---

**The key under which a value is provided can be a string or a Symbol, and in an application of any
size it should be a Symbol exported from one module.** The demos of this lesson have used `unitKey` and
`plannerKey` from `keys.js` from the start; this section is why.

## A string key is a name anybody can use

`provide('unit', 'hours')` works, and `inject('unit')` finds it. It also finds anything else provided
as `'unit'` closer up the tree, by any component, including one inside a library you installed that
happens to use the same word for its own setting. The two never meet in the code, and the
injector gets whichever is nearer. Strings collide silently, because two equal strings are the same
key.

**Two Symbols are never equal**, even with the same description:

```
ana@dev:~/vue/sandbox$ node -e "console.log(Symbol('unit') === Symbol('unit'), 'unit' === 'unit')"
false true
```

A Symbol key can only be used by code that imports that exact Symbol, so the only way to reach
the value is through the module that exports it.

## Why one module

Putting every key in one file, `keys.js`, gives three things that are easy to undervalue:

- **A list of everything provided**, in one place. Provide is the one flow of data in Vue that is not
  visible in the template, and the keys file is where a reader starts.
- **One import to find every user.** A search for `unitKey` shows every component that provides or
  injects the unit, which a search for the string `'unit'` would bury among everything else called unit.
- **A place for types.** Lesson 16 gives a key the type of the value it carries, with `InjectionKey`,
  so that `inject(unitKey)` is known to return a string, or `undefined` when nothing provides one,
  without anybody having to say so.

The planner gets its own `src/keys.js` at the end of this lesson, with one key in it.

## When a string is fine

A string key is the old form and you will see it in older code and in the documentation's shortest
examples. Within a small component library where every key has a prefix of its own, like
`'my-tabs:active'`, it works in practice. The Symbol costs one import and makes the question
unnecessary.
