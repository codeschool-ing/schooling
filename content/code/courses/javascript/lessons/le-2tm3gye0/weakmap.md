---
title: WeakMap: notes attached to objects
version: 1
---

**A `WeakMap` is a `Map` whose keys must be objects, and which does not keep its keys alive.** The
second half of that sentence is the subject of the last section; this one is about what it lets
you do. The interface is the familiar one, minus everything that would walk the entries:

```javascript
const visits = new WeakMap();
const reader = { name: "ana" };

visits.set(reader, 1);
visits.set(reader, visits.get(reader) + 1);
console.log(visits.get(reader), visits.has(reader));
console.log(visits.size, typeof visits.keys);

visits.set("ana", 1);
```

```
ana@dev:~/js$ node weakmap.js 2>&1 | head -n 7
2 true
undefined undefined
/home/ana/js/weakmap.js:9
visits.set("ana", 1);
       ^

TypeError: Invalid value used as weak map key
```

`set`, `get`, `has` and `delete` work. **There is no `size` and no `keys`**, and a `WeakMap`
cannot be looped over. A string key is refused with a `TypeError`, because a string is not an
object. Both restrictions come from the same place: the entries may disappear at any moment, so
there is no stable list to count or walk.

## What it is for

**A `WeakMap` attaches information to an object without putting it on the object.** Two common
uses:

- **a cache** keyed by an object, such as the measured size of each element on a page, or the
  result of an expensive calculation per document. When the object goes away, its cache entry goes
  with it, and nobody has to remember to delete it;
- **data the object's owner should not see**, kept beside the object rather than in it:

```javascript
const balances = new WeakMap();

function openAccount(owner) {
  const account = { owner };
  balances.set(account, 0);
  return account;
}

function deposit(account, cents) {
  balances.set(account, balances.get(account) + cents);
}

function balance(account) {
  return balances.get(account);
}

const acc = openAccount("ana");
deposit(acc, 1990);
deposit(acc, 500);
console.log(acc, balance(acc));
```

```
{ owner: 'ana' } 2490
```

`acc` printed as `{ owner: 'ana' }`: **the balance is not on the object at all.** Only code that can
reach `balances` can read it, which here means the three functions. Lesson 8 shows the class
syntax for the same idea, private fields, which is what you would write today; this pattern is what
libraries used before those existed, and what you still use to annotate objects someone else
created, such as elements of a page.
