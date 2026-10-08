---
title: Publishing a package
version: 2
---

**Publishing uploads a folder to the registry under a name and a version, and that pair can never
hold different code afterwards.** ana writes a small package of her own:

```json
{
  "name": "shelf-count",
  "version": "1.0.0",
  "description": "Counts books by decade.",
  "type": "module",
  "exports": "./index.js",
  "files": ["index.js"],
  "license": "MIT"
}
```

```javascript
export function byDecade(books) {
  const counts = {};
  for (const { year } of books) {
    const decade = Math.floor(year / 10) * 10;
    counts[decade] = (counts[decade] ?? 0) + 1;
  }
  return counts;
}
```

```javascript
import assert from "node:assert/strict";
import { byDecade } from "./index.js";

assert.deepEqual(byDecade([{ year: 1956 }, { year: 1958 }, { year: 1977 }]), { 1950: 2, 1970: 1 });
console.log("byDecade: ok");
```

- **`exports`** names the file an import of `shelf-count` loads, and nothing else in the package can
  be imported from outside;
- **`files`** lists what goes into the published package. Without it npm sends almost everything in
  the folder, tests and notes included, and a stray `.env` with a password in it has been published
  that way more than once;
- **`license`** tells others what they may do with the code.

## Before publishing

```
ana@dev:~/js/shelf-count$ node index.test.js
byDecade: ok
ana@dev:~/js/shelf-count$ npm whoami
ana
ana@dev:~/js/shelf-count$ npm pack --dry-run 2>&1 | tail -n +3
npm notice Tarball Contents
npm notice 207B index.js
npm notice 186B package.json
npm notice Tarball Details
npm notice name: shelf-count
npm notice version: 1.0.0
npm notice filename: shelf-count-1.0.0.tgz
npm notice package size: 360 B
npm notice unpacked size: 393 B
npm notice shasum: ca192e5fd49921d899c85611eba034847c851102
npm notice integrity: sha512-AIRRh++jaYTaQ[...]MmXLkDYYcoM3w==
npm notice total files: 2
npm notice
shelf-count-1.0.0.tgz
```

`npm whoami` answers with the account npm will publish as: `ana`, the one `npm adduser` created in
the first section, whose token it reads from `~/.npmrc`.

`npm pack --dry-run` builds the package without sending it and lists what is inside. Two files,
because `files` named one and npm always adds `package.json`; the test stayed home. npm starts that
listing with a line holding a parcel emoji the school's typeface cannot draw, and `tail -n +3`
starts the output from its third line.

## Publishing

```
ana@dev:~/js/shelf-count$ npm publish --loglevel=warn
+ shelf-count@1.0.0
ana@dev:~/js/shelf-count$ npm view shelf-count versions
1.0.0
```

`--loglevel=warn` leaves only the line that says what was published. Publishing the same version
twice is refused, because a version is a promise that its contents never change:

```
ana@dev:~/js/shelf-count$ npm publish --loglevel=warn 2>&1 | head -n 2
npm error code E409
npm error 409 Conflict - PUT http://127.0.0.1:4873/shelf-count - this package is already present
ana@dev:~/js/shelf-count$ npm version patch
v1.0.1
ana@dev:~/js/shelf-count$ npm publish --loglevel=warn
+ shelf-count@1.0.1
ana@dev:~/js/shelf-count$ npm view shelf-count versions
[ '1.0.0', '1.0.1' ]
```

`npm version patch` raised `1.0.0` to `1.0.1` in `package.json`. In a git repository it would also
commit that change and tag it `v1.0.1`; this folder is not one, so it only edited the file.
`npm version minor` and `npm version major` raise the other two parts and reset the ones after them.

Once a version is out, people may already depend on it. **Fix a mistake by publishing a new
version, not by removing the old one.** The public registry only lets a version be unpublished
within a short window, and `npm deprecate` attaches a warning instead.

## Using it

```
ana@dev:~/js/first$ npm install shelf-count

added 1 package in 400ms
```

```javascript
import { byDecade } from "shelf-count";

const books = [
  { title: "Dom Casmurro", year: 1899 },
  { title: "Grande Sertão: Veredas", year: 1956 },
  { title: "Vidas Secas", year: 1938 },
  { title: "A Hora da Estrela", year: 1977 },
  { title: "O Tempo e o Vento", year: 1949 },
  { title: "Sagarana", year: 1946 },
];
console.log(byDecade(books));
```

```
ana@dev:~/js/first$ node decades.js
{ '1890': 1, '1930': 1, '1940': 2, '1950': 1, '1970': 1 }
```

The keys come out in ascending order even though the books did not, because JavaScript lists
integer-like keys of an object in numeric order, before any other key. Publishing to an organisation's
private registry works the same way, with its address in `.npmrc`; `front-delivery`, lesson 7,
covers versioning and publishing internal packages for a team.
