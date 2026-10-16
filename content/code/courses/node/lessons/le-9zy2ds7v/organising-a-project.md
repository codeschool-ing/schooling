---
title: Organising a server project
version: 1
---

**A module should do one job, and the folder layout should say which file does which.** That is the
whole rule, and the rest is convention. The service this course builds from lesson 5 on, a link
shortener, ends lesson 10 laid out like this:

```localised
links/
├── package.json        the project: its name, type, scripts and dependencies (lesson 4)
├── package-lock.json   the exact versions installed (lesson 4)
├── server.js           starts it: reads the configuration and listens (lessons 9, 10)
├── src/
│   ├── app.js          builds the Express application, and does not listen (lesson 6)
│   ├── links.js        the routes under /links (lessons 6, 7)
│   ├── store.js        keeps the links, in memory and then in a file (lessons 6, 8)
│   └── config.js       reads and checks the environment, once (lesson 9)
└── test/
    └── links.test.js   asks the app questions on a spare port (lessons 4, 6)
```

Three choices in it are worth naming, because each is a mistake people make once.

**`app.js` builds the application and `server.js` starts it.** A test needs the application without
its real port: it imports `app.js`, starts it on a port the system picks, sends it requests, and
closes it. If the same file also called `listen` on port 3000, every test would fight over that port
and leave the process running, the puzzle from lesson 2's section on
when a process decides it is finished.

**`store.js` hides where the data lives.** The routes call `store.add` and `store.find` and never know
whether that is an array or a file. Lesson 8 changes the inside of `store.js` from one to the other,
and no route changes. A later course on databases changes it again.

**`config.js` is read once.** It reads `process.env`, checks every value, and exports one object.
Because a module runs once and is cached, every file that imports it gets the same object, checked
once, at start-up.

## Folders by kind or by feature

The layout above groups files **by what they are**: routes, storage, configuration. A large service
groups **by feature** instead — `links/`, `users/`, `billing/`, each with its own routes and storage
— so that one change touches one folder. Both are fine, and a service of five files is not large.
The mistake is a third arrangement: no arrangement, with a `utils.js` that grows until every file
imports it and it imports everything back, which is how the cycles in this lesson's section on the cache are born.
