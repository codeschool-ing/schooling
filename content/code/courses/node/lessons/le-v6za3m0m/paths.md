---
title: Paths, and keeping a user inside a folder
version: 1
---

**A path built by gluing strings together breaks on the first input nobody expected.** `node:path`
joins, splits and tidies paths with the rules of the operating system, and it is the only way a server
should build one:

```javascript
// paths.js
import path from "node:path";

console.log(path.join("/home/ana/server", "files", "data", "links.json"));
console.log(path.join("/srv/uploads", "../../etc/passwd"));
console.log(path.basename("/srv/uploads/report.pdf"), path.extname("report.tar.gz"));
console.log(path.resolve("data/links.json"));
console.log(path.join(import.meta.dirname, "data"));
```

```
ana@dev:~/server/files$ node paths.js
/home/ana/server/files/data/links.json
/etc/passwd
report.pdf .gz
/home/ana/server/files/data/links.json
/home/ana/server/files/data
```

- **`join` normalises**, so `..` is applied rather than kept, which is exactly what makes the second
  line dangerous: a file name a client sent, `../../etc/passwd`, joined onto an upload folder, points
  outside it.
- **`resolve` makes a path absolute** from the folder you are in, `process.cwd()`, and
  **`import.meta.dirname`** from the folder the program is in. Lesson 3 explained why the second is
  the one to build on.

## Staying inside

A server that reads or writes a file named by a client — an upload, a download, a template — has one
rule. **Resolve the final path, and check that it is still inside the folder.** Not by looking for
`..` in the input, which misses the forms nobody thought of, but by comparing where the path ends up:

```javascript
// inside.js
import path from "node:path";

function inside(root, name) {
  const base = path.resolve(root);
  const target = path.resolve(base, name);
  if (target !== base && !target.startsWith(base + path.sep)) throw new Error(`${name} is outside ${base}`);
  return target;
}

for (const name of ["report.pdf", "2026/october.csv", "../secrets.txt", "/etc/passwd", "a/../../b"]) {
  try {
    console.log(`ok       ${inside("/srv/uploads", name)}`);
  } catch (err) {
    console.log(`refused  ${err.message}`);
  }
}
```

```
ana@dev:~/server/files$ node inside.js
ok       /srv/uploads/report.pdf
ok       /srv/uploads/2026/october.csv
refused  ../secrets.txt is outside /srv/uploads
refused  /etc/passwd is outside /srv/uploads
refused  a/../../b is outside /srv/uploads
```

**The `+ path.sep` matters**: without it, `/srv/uploads-old/x` starts with `/srv/uploads` and would
pass. An absolute name such as `/etc/passwd` is caught too, because `resolve` lets it replace the base
entirely, and the comparison sees where it landed. Express's `express.static`, in lesson 6, did this
check for you; any route of your own that touches the file system has to do it itself.
