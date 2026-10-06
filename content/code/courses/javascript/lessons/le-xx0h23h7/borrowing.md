---
title: Borrowing a function
version: 1
---

**A method is a function stored on an object, and nothing stops you running it on a different
object with `call`.** When the other object has the shape the method expects, it works. That is
borrowing, and it is the use of `call` that has not gone out of date.

## Array methods on things that are not arrays

Some values have numbered items and a `length` without being arrays. They are called
**array-like**, and the classic one is `arguments`, which every normal function has:

```javascript
function oldStyle() {
  console.log(Array.isArray(arguments), arguments.length);
  const list = Array.prototype.slice.call(arguments);
  console.log(list);
  console.log(Array.from(arguments));
}

function newStyle(...titles) {
  console.log(Array.isArray(titles), titles);
}

oldStyle("Iracema", "Dom Casmurro");
newStyle("Iracema", "Dom Casmurro");
```

```
ana@dev:~/js$ node arguments.js
false 2
[ 'Iracema', 'Dom Casmurro' ]
[ 'Iracema', 'Dom Casmurro' ]
true [ 'Iracema', 'Dom Casmurro' ]
```

`arguments` is not an array, so it has no `slice`. **`Array.prototype.slice.call(arguments)`
borrows `slice` from arrays** and runs it on `arguments`, which is enough like an array for `slice`
to work. You will see that exact line in older code. `Array.from` is the modern way to get an
array from anything array-like, and a rest parameter (lesson 4) avoids `arguments` altogether.

On a page, the same thing comes up with lists of elements:

```html
<!doctype html>
<ul>
  <li>Iracema</li>
  <li>Dom Casmurro</li>
  <li>Macunaíma</li>
</ul>
<script>
  const items = document.querySelectorAll("li");
  console.log(typeof items.forEach, typeof items.map);
  console.log(Array.prototype.map.call(items, (li) => li.textContent.length));
  console.log(Array.from(items, (li) => li.textContent.length));
  console.log(items.map((li) => li.textContent));
</script>
```

```
ana@dev:~/js$ page nodelist.html
function undefined
[7, 12, 9]
[7, 12, 9]
Uncaught TypeError: items.map is not a function
```

A `NodeList` has `forEach` and no `map`. Borrowing `map` worked, `Array.from` with a mapping
function worked, and **calling `items.map` threw**. Lesson 11 is about selecting elements; this is
the one thing about the result that surprises everybody.

## Methods that might have been replaced

```javascript
const record = { title: "Iracema", hasOwnProperty: "yes, a field called that" };
const dictionary = Object.create(null);
dictionary.title = "Dom Casmurro";

console.log(Object.prototype.hasOwnProperty.call(record, "title"));
console.log(Object.prototype.hasOwnProperty.call(dictionary, "title"));
console.log(Object.hasOwn(record, "title"), Object.hasOwn(dictionary, "title"));
console.log(record.hasOwnProperty("title"));
```

```
ana@dev:~/js$ node hasown.js 2>&1 | head -n 8
true
true
true true
/home/ana/js/hasown.js:8
console.log(record.hasOwnProperty("title"));
                   ^

TypeError: record.hasOwnProperty is not a function
```

`record` has its own property called `hasOwnProperty`, a string, which hides the method every
object inherits; `dictionary` was made with no inherited methods at all. **Borrowing the method from
`Object.prototype` works on both**, because it does not depend on what the object has. The last line
shows what happens without borrowing. `Object.hasOwn`, added in 2022, does the same as the borrowed
version in fewer characters, and is what to write today.

## Asking what something really is

```javascript
const tag = (v) => Object.prototype.toString.call(v);
console.log(tag([]), tag({}), tag(null), tag(new Date(0)), tag(new Map()));
console.log(String([]), String({}));
console.log(Array.prototype.map.call("abc", (c) => c.toUpperCase()));
```

```
ana@dev:~/js$ node tostring.js
[object Array] [object Object] [object Null] [object Date] [object Map]
 [object Object]
[ 'A', 'B', 'C' ]
```

Borrowing `Object.prototype.toString` gives a precise tag for any value, `[object Array]` or
`[object Null]`, where `String()` gives an empty string for an array. **It is how libraries tell
built-in types apart**, and it is why you will see this exact line in their source. The last line
borrows `map` for a string, whose characters are numbered like an array's items.
