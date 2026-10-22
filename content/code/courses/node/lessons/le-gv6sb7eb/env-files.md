---
title: .env files, and --env-file
version: 1
---

**Typing four variables before every command is how mistakes are made, so on a developer's computer
they live in a file**, conventionally called `.env`, one `NAME=value` per line. Node 22 reads one
itself with `--env-file`, so no package is needed:

```
ana@dev:~/server/links$ printf 'PORT=4000\nGREETING=hello from the file\n' > demo.env
ana@dev:~/server/links$ node --env-file=demo.env -p 'process.env.PORT + " " + process.env.GREETING'
4000 hello from the file
ana@dev:~/server/links$ PORT=5000 node --env-file=demo.env -p 'process.env.PORT'
5000
ana@dev:~/server/links$ node --env-file=missing.env -p 'process.env.PORT'
node: missing.env: not found
ana@dev:~/server/links$ node --env-file-if-exists=missing.env -p 'process.env.PORT'
missing.env not found. Continuing without it.
undefined
ana@dev:~/server/links$ rm demo.env
```

**A variable already set in the environment wins over the file**, which is what the second command
shows: the file gives defaults for a developer's laptop, and a deployment that sets the real
environment is never overridden by a file somebody left behind. **A missing file is an error** with
`--env-file`, and with `--env-file-if-exists` it is a note and nothing more, which is what a
`start` script wants: a laptop has a `.env`, a server has its environment set some other way and no
file at all.

## The two files a project keeps

```schooling-example
{"language": "sh", "file": ".env.example", "parts": [
 {"code": "# Copy this file to .env and fill it in. .env itself is never committed.\nPORT=3000\nHOST=127.0.0.1", "note": "**`.env.example` is committed.** It lists every variable the service reads, with safe values or none, so that a new developer copies it to `.env` and knows what to fill in."},
 {"code": "ADMIN_KEY=", "note": "No value for the key, on purpose: a key in an example file is a key in the repository."}
]}
```

**`.env` is not committed, ever**, because it holds the real values, secrets included. It joins
`.gitignore` before it is created, which the section on secrets checks. The package `dotenv` did this
job for years and you will see it in older projects; `--env-file` does the same with nothing installed.
