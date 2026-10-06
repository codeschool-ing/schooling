---
title: Objects: named parts
version: 1
---

**An object is a collection of properties, each a name with a value.** The value can be anything,
another object included, and when it is a function the property is called a **method**. You write
one with braces:

```javascript
const field = "year";
const book = {
  title: "Dom Casmurro",
  author: "Machado de Assis",
  [field]: 1899,
  "page count": 256,
  describe() {
    return `${this.title}, ${this.year}`;
  },
};

console.log(book.title, book["author"], book[field]);
console.log(book["page count"]);
console.log(book.describe());
console.log(book.isbn);

book.isbn = "978-85-359-0277-8";
delete book["page count"];
console.log("isbn" in book, "page count" in book);
console.log(Object.keys(book));
```

```
ana@dev:~/js$ node objects.js
Dom Casmurro Machado de Assis 1899
256
Dom Casmurro, 1899
undefined
true false
[ 'title', 'author', 'year', 'describe', 'isbn' ]
```

## Reading and writing a property

**Dot notation, `book.title`, is for a name you know when you write the code.** Brackets,
`book["author"]`, take any expression, so they are what you use when the name is in a variable,
as `book[field]` is, or when it is not a valid identifier, like `"page count"` with its space.
Inside the literal, `[field]: 1899` is a **computed key**: the property gets the name `field`
holds, which is `year`.

A property that does not exist reads as `undefined`, as `book.isbn` did. **No error**, which is
convenient and is also how a typo in a property name goes unnoticed; the last section of this lesson
deals with the consequence. Assigning to a property creates it, and `delete` removes one. `in`
asks whether a property exists, which is a different question from whether its value is
`undefined`.

## Methods and `this`

`describe` is written with the short method syntax, and inside it **`this` is the object the
method was called on**, so `book.describe()` could read `this.title`. That is the simple case.
Lesson 6 shows the cases where `this` is not what you expect.

## Shorthand and listing

```javascript
const title = "Iracema";
const year = 1865;
const book = { title, year };
console.log(book);
console.log(Object.entries(book));
```

```
ana@dev:~/js$ node shorthand.js
{ title: 'Iracema', year: 1865 }
[ [ 'title', 'Iracema' ], [ 'year', 1865 ] ]
```

When a property has the same name as the variable holding its value, **`{ title, year }` is short
for `{ title: title, year: year }`**, and you will see it constantly. `Object.keys`, `Object.values`
and `Object.entries` turn an object into arrays of its names, its values, or `[name, value]`
pairs, which is how you loop over an object with the array tools later in this lesson.
