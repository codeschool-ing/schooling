---
title: Where this course sits
version: 1
---

**The back-end track forks once, on the server language, and joins again straight after.** Four
paths leave from the same point and arrive at the same course:

| path | courses | hours |
|---|---|---|
| **JavaScript / Node.js** | `javascript`, then `node` | 140 |
| Python | `python`, then `python-back` | 150 |
| Java | `java`, `java-functional`, then `java-back` | 230 |
| Go | `go`, `go-concurrency`, `go-back`, then `go-production` | 290 |

You are on the first row, and this is its second course. Whichever row a student takes, the next
course is `sql-databases`, and everything after it — `apis`, `servers-cache`, `testing-cicd`,
`docker`, `architecture`, `scale` — is written for a student who can build a server in **one** of
the four languages. **Those courses name none of them.** Their examples are written so that each
idea can be carried into the language you know, and that is what this course has to leave you able
to do.

## What this course assumes

Two courses before it, and nothing else:

- **`javascript`**, the language itself, without the page. This course uses its syntax, its
  modules, its promises and `async`/`await`, and its event loop, and it points back to the lesson
  where each one was taught rather than teaching it again. Lessons 1 to 10, 13 to 17, 19 and 21 of
  that course matter most here; lessons 11, 12, 18 and 22 were about the browser and are not used.
- **`git`**, because a server project is a repository from its first file, and lesson 9 keeps a
  secret out of one.

## What it leaves you able to do

By lesson 10 you will have written one small service, a link shortener, three times over: once
with nothing but Node's own HTTP module, once with Express, and then grown in place until it keeps
its data in a file, reads its settings from the environment and runs one process per processor.
It is small on purpose. Every line of it is shown in a lesson, and everything it does is something
the courses after this one take for granted.

The eleven lessons go in this order:

| lesson | what it adds |
|---|---|
| 1 | why one language, your machine, a first server |
| 2 | the runtime: V8, the event loop's phases, the thread pool |
| 3 | modules: CommonJS, ES modules, and how Node finds a file |
| 4 | a project: `package.json`, scripts, dependencies, the test runner |
| 5 | an HTTP server and routing with nothing installed |
| 6 | Express: routes, middleware and errors |
| 7 | the request and the response in detail |
| 8 | files, buffers and streams |
| 9 | configuration and the environment |
| 10 | processes, workers and cluster mode |
| 11 | the same server in Python, Go, Java, PHP and C# |
