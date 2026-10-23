---
title: The documentation, and which version it describes
version: 1
---

**Node's documentation is at nodejs.org, and there is one copy of it per major version.** The page
you land on from a search is often the newest version's, and an option it describes may not exist
in Node 22. The address to keep is `https://nodejs.org/docs/latest-v22.x/api/`, which is the
documentation of the newest 22, the line this course uses.

## Release lines

Node has a new major version twice a year. **The even ones become long-term support (LTS)**
releases, maintained with fixes for about two and a half years, and the odd ones are not. A server
runs an LTS line. Your Node knows which line it is:

```
ana@dev:~/server$ node -p process.release
{
  name: 'node',
  lts: 'Jod',
  sourceUrl: 'https://nodejs.org/download/release/v22.22.0/node-v22.22.0.tar.gz',
  headersUrl: 'https://nodejs.org/download/release/v22.22.0/node-v22.22.0-headers.tar.gz'
}
ana@dev:~/server$ node -p 'process.versions.v8'
12.4.254.21-node.33
```

`lts: 'Jod'` is the name of the 22 line; every LTS line gets one. According to the release schedule
on nodejs.org, Node 22 is maintained until the end of April 2027, and moving a project to a newer
line before then is ordinary maintenance rather than an emergency. The second command is the
version of V8, the JavaScript engine inside Node, which lesson 2 opens.

## Stability

Each part of the API carries a **stability index**, and it decides how much you should build on it:

| index | what it means |
|---|---|
| 0, deprecated | it will go; do not start using it |
| 1, experimental | it may change or vanish in any release, even a minor one |
| 2, stable | it changes only with a major version |
| 3, legacy | it stays, and something better exists |

Experimental features print a warning when used, and lesson 3 shows one. A server should run on
**stable** APIs only, and where this course uses something younger it says so.

## How to read an entry

An entry gives the signature, then the options, then **the history**: a small table of the versions
in which the function was added and changed. That table answers the most common question about any
example found online — *will this work on my Node?* — and it is worth reading before the
description. `node --help` lists every command-line option of the Node you have, and nothing it
lists is missing from yours.
