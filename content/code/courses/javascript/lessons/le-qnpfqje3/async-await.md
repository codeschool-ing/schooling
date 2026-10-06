---
title: async and await
version: 1
---

**`await` pauses an `async` function until a promise settles, and gives back its value.** The two
reads that needed nesting with callbacks, and a chain with promises, become two ordinary lines:

```schooling-example
{
  "language": "javascript",
  "file": "await.mjs",
  "parts": [
    {
      "code": "import { readFile } from \"node:fs/promises\";",
      "note": "The promise version of `readFile`. This file is an ES module, so it can also use `await` at the top level (lesson 9)."
    },
    {
      "code": "async function describe(id) {\n  const book = JSON.parse(await readFile(`books/${id}.json`, \"utf8\"));\n  const author = JSON.parse(await readFile(`authors/${book.authorId}.json`, \"utf8\"));\n  return `${book.title} by ${author.name}`;\n}",
      "note": "`async` before a function lets it use `await` inside. Each `await` waits for one read, and the function carries on with the value, as if the read had returned it directly."
    },
    {
      "code": "const result = describe(12);\nconsole.log(result);",
      "note": "Calling an `async` function returns a promise straight away, which printed as pending. Its `return` value becomes the promise's value."
    },
    {
      "code": "console.log(await result);",
      "note": "`await` on that promise gave the sentence."
    },
    {
      "code": "try {\n  console.log(await describe(99));\n} catch (err) {\n  console.log(\"failed:\", err.code);\n}",
      "note": "A rejected promise makes `await` throw, so an ordinary `try`/`catch` handles errors from asynchronous work. Book 99 does not exist, and the `catch` got its error."
    }
  ],
  "output": "Promise { <pending> }\nDom Casmurro by Machado de Assis\nfailed: ENOENT"
}
```

## Still promises

**`async` and `await` are promises with a different syntax**, not a different mechanism:

- an `async` function **always returns a promise**, even when it returns a plain value;
- what follows an `await` runs later, as a **microtask** (lesson 13), once the awaited promise has
  settled. While the function is paused, the rest of the program carries on;
- `await` on something that is not a promise just gives the value back, after a microtask.

So everything from the last section still applies, and you can mix the two styles: `await` a function
that returns a promise chain, or `.then` an `async` function's result. **Write new code with
`await`**, because it reads top to bottom and its errors are caught with the same `try`/`catch` as
everything else. The one thing it makes easy to get wrong is the subject of the next section.
