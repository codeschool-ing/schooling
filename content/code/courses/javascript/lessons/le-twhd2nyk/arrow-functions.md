---
title: Arrow functions
version: 1
---

A **function** is a piece of code with a name, or at least a place, that you can run again with
different inputs. JavaScript has three ways to write one, and you will read all three in any real
codebase. The newest, the **arrow function**, is the shortest:

```schooling-example
{
  "language": "javascript",
  "file": "shelf.js",
  "parts": [
    {
      "code": "function double(n) {\n  return n * 2;\n}",
      "note": "A function declaration: the keyword, a name, the parameters, and a body in braces. `return` hands the result back."
    },
    {
      "code": "const triple = function (n) {\n  return n * 3;\n};",
      "note": "A function expression: the same thing written as a value and given to a name. The name lives wherever `const` puts it."
    },
    {
      "code": "const half = (n) => n / 2;",
      "note": "An arrow function. `=>` stands between the parameters and the body, and with no braces the body is a single expression whose value is returned without writing `return`."
    },
    {
      "code": "const square = n => n * n;",
      "note": "With exactly one parameter the parentheses are optional. Prettier puts them back by default, and most teams leave them in."
    },
    {
      "code": "const describe = (title, year = \"unknown\") => {\n  const age = typeof year === \"number\" ? 2026 - year : \"?\";\n  return title + \" (\" + year + \"), \" + age + \" years old\";\n};",
      "note": "With braces the body is a block like any other, and then `return` is needed again. `year = \"unknown\"` is a default, used when the caller passes nothing for that parameter."
    },
    {
      "code": "console.log(double(4), triple(4), half(4), square(4));\nconsole.log(describe(\"Dom Casmurro\", 1899));\nconsole.log(describe(\"Iracema\"));",
      "note": "The calls. `describe(\"Iracema\")` leaves `year` out, so the default fills it in."
    }
  ],
  "output": "8 12 2 16\nDom Casmurro (1899), 127 years old\nIracema (unknown), ? years old"
}
```

**The three forms do the same job for everything in this lesson.** They differ in what `this`
means inside them, which is lesson 6, and in one more thing at the end of this section.

## The trap: returning an object

An arrow without braces returns its expression. An object is also written with braces, so this
looks like it returns one:

```javascript
const wrong = (title) => { title: title };
const right = (title) => ({ title: title });

console.log(wrong("Iracema"));
console.log(right("Iracema"));
```

```
ana@dev:~/js$ node object-arrow.js
undefined
{ title: 'Iracema' }
```

**After `=>`, a brace always opens a block, never an object.** In `wrong`, the braces are a
function body, `title` and its colon are a label (a part of the language almost nobody uses), and the function
returns nothing. Wrapping the object in parentheses, as `right` does, makes it an expression again.
Everybody writes `wrong` once.

## An arrow cannot be a constructor

```javascript
const Shelf = () => {};
const s = new Shelf();
```

```
ana@dev:~/js$ node new-arrow.js 2>&1 | head -n 5
/home/ana/js/new-arrow.js:2
const s = new Shelf();
          ^

TypeError: Shelf is not a constructor
```

`new` builds an object from a function, and lesson 8 is about how. **Arrow functions were left out
of that on purpose**: they are meant for small pieces of behaviour, passed around and called, and
the class syntax covers the rest.

## Which form to write

Arrows for the small functions you hand to something else, such as the ones lesson 4 passes to
`map` and `filter`. Declarations for the named, top-level functions of a file: they read well, and
lesson 3 shows they can be called before the line that defines them. The expression form is mostly
what you will read in code written before 2015.
