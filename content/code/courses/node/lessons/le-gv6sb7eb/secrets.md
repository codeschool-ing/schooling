---
title: Secrets
version: 1
---

**A secret is a value whose leaking would let somebody do something they should not**: the admin key,
a database password, an API token. Three rules keep one secret, and each is a habit rather than a
tool.

## Long and random

A key a person chose is a key a person can guess. **Generate it**, from the random source lesson 4
used for codes:

```
ana@dev:~/server/links$ node -p 'require("node:crypto").randomBytes(24).toString("base64url")'
5Hum7Nw7Qc1lNv_k5f-LNxT7q3S_awPo
ana@dev:~/server/links$ echo "ADMIN_KEY=$(node -p 'require("node:crypto").randomBytes(24).toString("base64url")')" > .env
```

Twenty-four random bytes, written as 32 characters of base64url, which is safe in a header and a file.
The second line makes a new one and writes it to `.env` without it ever being typed.
That is why `config.js` refuses anything shorter than 24 characters: the example values and the old
`change-me-in-lesson-9` are both refused.

## Never in git

The project becomes a repository now, if it is not one already, and the secret's file is ignored
before it exists:

```
ana@dev:~/server/links$ git init -q && printf '.env\ntest/tmp/\n' >> .gitignore && cat .gitignore
node_modules/
data/
.env
test/tmp/
ana@dev:~/server/links$ git check-ignore -v .env data/links.json
.gitignore:3:.env	.env
.gitignore:2:data/	data/links.json
ana@dev:~/server/links$ git status --short
?? .env.example
?? .gitignore
?? .npmrc
?? count.js
?? demo/
?? jar.txt
?? package-lock.json
?? package.json
?? public/
?? server.js
?? src/
?? test.env
?? test/
```

`git check-ignore -v` says which rule ignores a file, which is the way to be sure before the first
commit rather than after it. **A secret committed once is in the history for ever**: deleting it in
the next commit leaves it in every clone, and the only fix is to make it worthless, by generating a
new one and retiring the old. Services that scan repositories for leaked keys, GitHub's own among
them, find these within minutes of a push to a public one.

## Never in a log

The service prints its configuration at start-up, and **`summary()` replaces the key with a sentence
about it**. A secret in a log is a secret in every system the logs are shipped to, and readable by
everyone who can read them:

```
ana@dev:~/server/links$ node --env-file=.env server.js
links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/data/links.json',
  adminKey: '(set, 32 characters)'
}
```

The admin's requests now need the new key, and the old one is refused like any other wrong key:

```
ana@dev:~/server/links$ curl -s -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links
{"error":"this needs the admin key"}
ana@dev:~/server/links$ curl -s -H "x-admin-key: $(sed -n 's/^ADMIN_KEY=//p' .env)" http://127.0.0.1:3000/links
[]
```

`$(sed -n 's/^ADMIN_KEY=//p' .env)` in the second command reads the key out of the file, so it is
never typed or pasted.

On a server the same variable comes from wherever the platform keeps secrets: a protected file the
service manager reads, which lesson 10 shows, or a secret store. The code is the same in each case,
because it only ever reads `process.env`.
