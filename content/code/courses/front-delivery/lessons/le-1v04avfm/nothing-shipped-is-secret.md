---
title: Nothing in the bundle is a secret
version: 1
---

**Every value in a front end's bundle is readable by everybody who can open the page.** The bundle is a
file the browser downloads; anybody can download it with `curl`, open it in the browser's developer
tools, or search it. Minifying it changes the names of variables, and a string stays a string.

## The obvious fix, and what it does

The last section left a line in `main.ts` printing `SUPPORT_TOKEN`, which came out `undefined`. The fix
somebody reaches for at the end of a long day is to give the variable the prefix it was missing:

```
ana@dev:~/planner$ sed -i 's/SUPPORT_TOKEN/VITE_SUPPORT_TOKEN/' .env.local src/main.ts
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ grep -o 'token:[^)]*' dist/assets/*.js
token:`,`tok-demo-not-a-real-secret`
```

The token is in the bundle, in plain text, beside the label the code printed. Deployed, it would be in
the file every visitor's browser downloads, and in every copy of that file the CDN keeps. **Removing it
from the code later does not take it back**: whoever downloaded the file has it, and the token has to be
replaced at whatever issued it.

Put the planner back as it was:

```
ana@dev:~/planner$ git checkout src/main.ts && rm .env.local
Updated 1 path from the index
```

## Public keys and secret keys

Many services know this and issue **two kinds of key**. A payment provider, a maps service, an error
reporter: each gives you one key that is meant to be published, and one that is not.

| | a publishable key | a secret key |
|---|---|---|
| where it goes | in the front end, under `VITE_` | only on a server you control |
| what it can do | what the service allows from a browser: show a map, start a checkout, send a report | anything the account can do: refund, read every record, change settings |
| what protects it | limits set at the service: which domains may use it, how often | being kept out of every file a visitor can reach |
| if it leaks | somebody uses your quota from their own page, which the domain limit blocks | somebody acts as you |

**A key is publishable because the service says so, not because it is in a `VITE_` variable.** Read the
service's documentation for which is which; most name them plainly (`pk_` against `sk_` is a common
convention). When a service gives you one key only, assume it is secret. Lesson 11 uses the publishable
kind: an error reporter's address, which is in every visitor's browser by design.

## The places a value hides

The bundle is not the only place. **Source maps** carry the original code, comments and all, when they
are published; lesson 11 builds them so they are not. **`index.html`** can hold values too, since Vite
replaces `%VITE_…%` in it. And **a request the page makes** carries whatever the code put in it: a
secret sent as a header from the browser is as public as one written in the bundle, because the
developer tools' network panel shows every header.

The rule that covers all of them is the one from the start of this section: if the browser has it, the
person using the browser has it.
