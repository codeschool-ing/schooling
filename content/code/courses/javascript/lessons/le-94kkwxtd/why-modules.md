---
title: One global scope, and the trouble with it
version: 1
---

A classic `<script>` runs in the page's global scope. Lesson 3 showed what that means for a
top-level `var`; here it is with two files written by two people:

```javascript
function format(title) {
  return `A: ${title}`;
}
```

```javascript
function format(title) {
  return `B: ${title}`;
}
```

```html
<!doctype html>
<script src="a.js"></script>
<script src="b.js"></script>
<script>
  console.log(format("Iracema"));
</script>
```

```
ana@dev:~/js$ cd classic && page page.html
B: Iracema
```

**Both files declared `format` in the same scope, and the one loaded last replaced the other**, with
no error. Whoever wrote `a.js` would find their function answering `B:` and nothing to say why. The
order of the `<script>` tags was also, silently, a list of dependencies: a script that used a
function from another had to come after it, and nothing checked.

## What a module system gives you

A **module** is a file with a scope of its own. Nothing it declares leaks out unless it says so, and
nothing from another file reaches in unless it asks. That gives three things the global scope
could not:

- **names that cannot collide**, because each file's names are its own;
- **dependencies written down in the file that has them**, so the order of loading is worked out by
  the system instead of by whoever edits the page;
- **an explicit public surface**: what a file exports is what other files may rely on, and
  everything else can change freely.

JavaScript has two module systems because the language took twenty years to get one. **CommonJS**
was invented for Node in 2009 and is still the format of most older Node code. **ES modules**, or
ESM, were added to the language in 2015 and work in browsers and in Node alike. The next sections
take ES modules first, since they are the language's own, then CommonJS, then what happens where
they meet.
