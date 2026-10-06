---
title: Map: a dictionary with any keys
version: 1
---

Before 2015 there was only one way to keep values by key, which was to use an object's property
names as the keys. **It works for strings you control, and fails in two quiet ways** for anything
else:

```javascript
const iracema = { title: "Iracema" };
const casmurro = { title: "Dom Casmurro" };

const loans = {};
loans[iracema] = 3;
loans[casmurro] = 5;
console.log(Object.keys(loans), loans[iracema]);

const counts = {};
for (const word of ["the", "constructor", "the"]) {
  counts[word] = (counts[word] || 0) + 1;
}
console.log(counts.the);
console.log(counts.constructor);
```

```
ana@dev:~/js$ node object-dictionary.js
[ '[object Object]' ] 5
2
function Object() { [native code] }1
```

**Property names are strings**, so both books became the key `"[object Object]"`, the text
lesson 2 showed for an object turned into a string. The second book overwrote the first, and
`loans[iracema]` gave 5. The second failure is worse: **an object already has properties it
inherited**, one of them called `constructor`, so counting the word "constructor" started from a
function instead of from zero. Lesson 8 explains where inherited properties come from.

## `Map`

A `Map` keeps keys of any type, compared the way `===` compares them, and has nothing inherited
to collide with:

```javascript
const iracema = { title: "Iracema" };
const casmurro = { title: "Dom Casmurro" };

const loans = new Map();
loans.set(iracema, 3);
loans.set(casmurro, 5);
loans.set(1, "the number one");
loans.set("1", "the string one");

console.log(loans.get(iracema), loans.get(casmurro));
console.log(loans.get(1), "/", loans.get("1"));
console.log(loans.size, loans.has(casmurro));
loans.delete(1);

for (const [key, value] of loans) {
  console.log(typeof key, value);
}
```

```
ana@dev:~/js$ node map.js
3 5
the number one / the string one
4 true
object 3
object 5
string the string one
```

- `set(key, value)` and `get(key)` are the two you use most; `has`, `delete` and `size` complete it;
- **the two objects are two keys**, because they are two objects. So are `1` and `"1"`, which an
  object would have merged into one property;
- a `Map` remembers **the order keys were added in**, and `for…of` gives each entry as a
  `[key, value]` pair, ready to destructure.

## Back and forth

```javascript
const prices = new Map([
  ["Iracema", 2990],
  ["Dom Casmurro", 3450],
]);
console.log(prices);

const asObject = Object.fromEntries(prices);
console.log(asObject);

const back = new Map(Object.entries(asObject));
console.log(back.get("Iracema"));
console.log(JSON.stringify(prices), JSON.stringify(asObject));
```

```
ana@dev:~/js$ node map-convert.js
Map(2) { 'Iracema' => 2990, 'Dom Casmurro' => 3450 }
{ Iracema: 2990, 'Dom Casmurro': 3450 }
2990
{} {"Iracema":2990,"Dom Casmurro":3450}
```

A `Map` is built from a list of pairs, and `Object.fromEntries` and `Object.entries` convert in
both directions when the keys are strings. **`JSON.stringify` does not know about `Map`** and wrote
`{}`, silently dropping both prices. Lesson 16 is about JSON; for now, convert a `Map` to an object
before sending it anywhere as JSON.

The word count, done with a `Map`, has no inherited trap:

```javascript
const counts = new Map();
for (const word of ["the", "constructor", "the"]) {
  counts.set(word, (counts.get(word) ?? 0) + 1);
}
console.log(counts);
```

```
ana@dev:~/js$ node counts.js
Map(2) { 'the' => 2, 'constructor' => 1 }
```
