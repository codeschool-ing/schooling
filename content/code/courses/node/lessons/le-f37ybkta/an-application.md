---
title: A package.json for an application
version: 1
---

**The project this course builds from here on is a link shortener called `links`, and it starts as one
file.** `npm init -y` would write a `package.json` for you, with a `main`, `keywords` and `license`
that a library needs and a server does not. Write this one by hand instead, in a new folder
`~/server/links`:

```schooling-example
{"language": "json", "file": "package.json", "parts": [
 {"code": "{\n  \"name\": \"links\",\n  \"version\": \"0.1.0\",", "note": "The name and version. Nobody installs a server by name, so the version is a label for you; it never goes to a registry."},
 {"code": "  \"private\": true,", "note": "**`private` makes `npm publish` refuse**, so a server's code cannot be published to the public registry by a slip of the fingers."},
 {"code": "  \"type\": \"module\",\n  \"description\": \"A small link shortener, built in the node course\",", "note": "Every `.js` file in the project is an ES module, as lesson 3 explained."},
 {"code": "  \"scripts\": {\n    \"start\": \"node server.js\",\n    \"dev\": \"node --watch server.js\",\n    \"test\": \"node --test --test-reporter=spec\",\n    \"format\": \"prettier --write server.js src test\"\n  },", "note": "The commands of the project, which the next section is about."},
 {"code": "  \"engines\": {\n    \"node\": \">=22\"\n  }\n}", "note": "The Node it was written for. The section on engines makes npm hold you to it."}
]}
```

There is no `main`: `main` says which file another package gets when it imports this one, and nothing
imports a server. There is no `dependencies` yet either. **npm writes that part itself** when you
install something, and nothing in it should be typed by hand.

npm can read any field back, which is how a script or a person checks a project without opening it:

```
ana@dev:~/server/links$ npm pkg get name version type
{
  "name": "links",
  "version": "0.1.0",
  "type": "module"
}
```

## The first two files

The service hands out short codes, so its first module makes one. It lives in `src/`, as lesson 3's
layout said:

```javascript
// src/code.js: the short codes the links service hands out.
import { randomInt } from "node:crypto";

export const ALPHABET = "23456789abcdefghjkmnpqrstuvwxyz"; // no 0, 1, i, l or o
export const LENGTH = 6;

export function makeCode(length = LENGTH) {
  let code = "";
  for (let i = 0; i < length; i++) code += ALPHABET[randomInt(ALPHABET.length)];
  return code;
}

export function isCode(text) {
  return typeof text === "string" && text.length === LENGTH && [...text].every((c) => ALPHABET.includes(c));
}
```

The alphabet leaves out the five characters people misread for each other, so a code read aloud or
typed from a phone survives. `randomInt` comes from `node:crypto` rather than `Math.random`, because
a link code that can be predicted is a link anybody can guess.

```
ana@dev:~/server/links$ node -e 'import("./src/code.js").then((m) => console.log(m.makeCode(), m.ALPHABET.length))'
327nuk 31
```

Thirty-one characters, six of them per code: 31 to the power 6, almost 890 million codes. The
section on the test runner checks the rules this file promises.
