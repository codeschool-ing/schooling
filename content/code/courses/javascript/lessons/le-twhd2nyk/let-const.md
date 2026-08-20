---
title: let and const: the end of var
---

`var` has two properties nobody asked for: it leaks out of the block it was declared in, and it can be redeclared without complaint. `let` and `const` do neither, and that is why `var` no longer shows up in new code.

```schooling-example
{
  "language": "javascript",
  "file": "scope.js",
  "parts": [
    {
      "code": "if (true) {\n  var old = \"I leak\";\n  let fresh = \"I stay put\";\n}",
      "note": "Both are declared inside the `if`. Only one of them still exists after the closing brace."
    },
    {
      "code": "console.log(old);",
      "note": "`var` is FUNCTION-scoped, not block-scoped: it was hoisted to the top of the function and survived the block. That is where nearly every swapped-variable-in-a-loop bug comes from."
    },
    {
      "code": "try {\n  console.log(fresh);\n} catch (e) {\n  console.log(e.constructor.name);\n}",
      "note": "`let` dies with the block. Outside it the name does not even exist — and the error is a `ReferenceError`, not `undefined`, which is an important difference: failing loudly beats carrying on with rubbish."
    },
    {
      "code": "const list = [1, 2];\nlist.push(3);\nconsole.log(list);",
      "note": "The most common confusion about `const`: it freezes the BINDING, not the value. `list = []` would be an error; changing things inside the array is not. To freeze the contents there is `Object.freeze`."
    }
  ],
  "output": "I leak\nReferenceError\n[ 1, 2, 3 ]"
}
```

The practical rule: **`const` by default, `let` when the value really is going to change, `var` never.** Starting from `const` makes the compiler warn you when you reassign by accident — and most of the reassignments we write without thinking are accidents.
