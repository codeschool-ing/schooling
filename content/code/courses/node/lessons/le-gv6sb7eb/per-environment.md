---
title: Development, test and production
version: 1
---

**The same code runs in three places, and each has its own way of getting its variables.** None of
them needs a different file of code, and none of them is chosen by a variable that says which place it
is:

| where | how the variables arrive | what is different |
|---|---|---|
| development, your laptop | `.env`, read with `--env-file-if-exists` | a key of your own; data in `data/` |
| test, `npm test` | `test.env`, committed, with nothing secret in it | a throwaway key; data in `test/tmp/` |
| production, a server | the service manager or the platform | the real key; data where the server keeps it |

The test row is the one that was missing. Since lesson 8 the store writes a file, so **the tests of
lesson 6 have been writing their links into the same `data/links.json` you use by hand**. A test that
changes the developer's data is a test nobody wants to run. `test.env` gives the tests a file of their
own and a key that can be committed because it guards nothing:

```schooling-example
{"language": "sh", "file": "test.env", "parts": [
 {"code": "# The environment of npm test. Nothing here is a secret.\nADMIN_KEY=only-for-tests-and-not-a-secret\nDATA_FILE=test/tmp/links.json", "note": "**Committed on purpose**: these values guard nothing and exist so that `npm test` works on a fresh clone with no setup."}
]}
```

The scripts in `package.json` choose the file. Three `npm pkg set` lines rewrite them:

```
ana@dev:~/server/links$ npm pkg set scripts.start='node --env-file-if-exists=.env server.js'
ana@dev:~/server/links$ npm pkg set scripts.dev='node --env-file-if-exists=.env --watch server.js'
ana@dev:~/server/links$ npm pkg set scripts.test='node --env-file=test.env --test --test-reporter=spec'
ana@dev:~/server/links$ ls data
ls: cannot access 'data': No such file or directory
```

```
ana@dev:~/server/links$ npm test 2>&1 | grep -E "^(✔|✖|ℹ (tests|pass|fail))"
✔ a code has the right length (0.713149ms)
✔ a code uses only the alphabet (5.573364ms)
✔ isCode refuses what makeCode would never make (0.155228ms)
✔ a new link answers 201 with its location (47.567979ms)
✔ following a link redirects and counts the visit (11.781897ms)
✔ a url that is not a web address is refused (2.735758ms)
✔ deleting needs the admin key (14.30293ms)
ℹ tests 7
ℹ pass 7
ℹ fail 0
ana@dev:~/server/links$ ls data test/tmp
ls: cannot access 'data': No such file or directory
test/tmp:
links.json
```

**The tests passed, and `data/links.json` was not touched**: their links went to `test/tmp/`, which
`.gitignore` already leaves out. In production, `npm start` finds no `.env`, reads what the service
manager put in the environment, and `config.js` refuses to start if that is incomplete.
