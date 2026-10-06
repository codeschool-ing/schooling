---
title: The class syntax
version: 1
---

**A class is a cleaner way to write a constructor function and its prototype**, in one block, with
a few guarantees the old way lacked. The same `Book`, with two features the old syntax made awkward:

```schooling-example
{
  "language": "javascript",
  "file": "class.js",
  "parts": [
    {
      "code": "class Book {",
      "note": "`class Book` declares the constructor and the prototype in one place. The body is always strict mode, whether the file is or not."
    },
    {
      "code": "  constructor(title, year) {\n    this.title = title;\n    this.year = year;\n  }",
      "note": "`constructor` is the function `new` calls in step 3. It sets the instance's own properties."
    },
    {
      "code": "  describe() {\n    return `${this.title} (${this.year})`;\n  }",
      "note": "A method written in the class body goes on `Book.prototype`, shared by every book, exactly as `Book.prototype.describe = …` did."
    },
    {
      "code": "  get age() {\n    return 2026 - this.year;\n  }",
      "note": "`get` makes a property that is computed each time it is read. `b.age` is written without parentheses and runs this function."
    },
    {
      "code": "  static fromLine(line) {\n    const [title, year] = line.split(\";\");\n    return new Book(title, Number(year));\n  }\n}",
      "note": "`static` puts a function on the class itself rather than on its instances. A static method that builds an instance from some other input is a common pattern, and `fromLine` is one."
    },
    {
      "code": "const b = Book.fromLine(\"Dom Casmurro;1899\");\nconsole.log(b.describe(), b.age);\nconsole.log(typeof Book, Object.getPrototypeOf(b) === Book.prototype);\nconsole.log(Object.keys(b), Object.hasOwn(Book.prototype, \"describe\"));\nconsole.log(b);",
      "note": "Read the output against the old way: `typeof Book` is still `\"function\"`, the instance's prototype is `Book.prototype`, and `describe` lives there, not on the book."
    }
  ],
  "output": "Dom Casmurro (1899) 127\nfunction true\n[ 'title', 'year' ] true\nBook { title: 'Dom Casmurro', year: 1899 }"
}
```

**Nothing about the prototype chain changed.** A class is a function, and its methods sit on its
`prototype` object, so everything in the last three sections applies to classes unchanged. Console
output puts the class's name, `Book`, in front of the braces, which is the most visible
difference.

## What a class adds

```javascript
class Book {
  constructor(title) {
    this.title = title;
  }
}
const b = Book("Iracema");
```

```
ana@dev:~/js$ node class-no-new.js 2>&1 | head -n 5
/home/ana/js/class-no-new.js:6
const b = Book("Iracema");
          ^

TypeError: Class constructor Book cannot be invoked without 'new'
```

**A class refuses to be called without `new`**, with a message that says what is wrong, instead of
the confusing failure of the last section. Its body is strict mode. Its methods cannot be used as
constructors. And class declarations are hoisted the way `let` is (lesson 3), so using a class
above its declaration is a `ReferenceError` from the temporal dead zone rather than a quiet
`undefined`.

Write classes when you need many objects of one kind that share behaviour, such as books in a
catalogue or components on a page. When you need one object, an object literal is simpler, and when
you need private state for a few functions, a closure (lesson 6) is enough.
