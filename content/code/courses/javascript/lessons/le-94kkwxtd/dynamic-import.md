---
title: import() when you need it
version: 1
---

A static `import` sits at the top of a file and is loaded before any code runs. Sometimes a module
is only needed on one path, such as a report nobody asked for or a page of the site the visitor never
opens. **`import()` loads a module when the line is reached**, and gives back a promise of its
exports:

```javascript
console.log("report.mjs loaded");
export function render(rows) {
  return rows.map((r) => `- ${r}`).join("\n");
}
```

```javascript
const wantsReport = process.argv[2] === "report";
console.log("start");

if (wantsReport) {
  const { render } = await import("./report.mjs");
  console.log(render(["Iracema", "Dom Casmurro"]));
}
console.log("end");
```

```
ana@dev:~/js$ node lazy/main.mjs
start
end
ana@dev:~/js$ node lazy/main.mjs report
start
report.mjs loaded
- Iracema
- Dom Casmurro
end
```

Without the `report` argument, `report.mjs` was **never loaded**: `report.mjs loaded` did not print.
With it, the module loaded in the middle of the program, between `start` and `end`, and `render`
was destructured out of what came back.

## Two things to read in that program

- `import()` looks like a function call and is not one: it is syntax, and it works in ES modules and
  in CommonJS files alike, which made it the bridge between the two before `require` could load an
  ES module;
- **`await` stands at the top level of the file**, outside any function. That is allowed in an ES
  module, and only there; it pauses the module until the import has finished. A promise is what
  `import()` returns, and `await` waits for one; lesson 14 is the lesson about both, and this is a
  preview of the shape.

In the browser, `import()` is how a large application loads the code for a screen only when the
user goes to it, so that the first page arrives sooner. The build tools of the framework courses do
this for you when a route is declared lazily; what they generate is a call to `import()`.
