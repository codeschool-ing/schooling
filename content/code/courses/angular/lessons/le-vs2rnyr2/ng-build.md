---
title: A build for the web
version: 1
---

**`ng build` writes the application as files a web server can send.** The dev server builds into
memory and stays running; the build writes to disk and stops. What it writes is what goes on a real
server, and it is built differently: smaller, without the development checks, and with names that
change whenever the content does.

```
ana@dev:~/planner$ npx ng build
❯ Building...
✔ Building...
Initial chunk files | Names         |  Raw size | Estimated transfer size
main-J4WVDBNH.js    | main          | 187.14 kB |                50.84 kB
styles-5INURTSO.css | styles        |   0 bytes |                 0 bytes

                    | Initial total | 187.14 kB |                50.84 kB

Application bundle generation complete. [3.464 seconds] - 2026-10-23T23:33:30.254Z

Output location: /home/ana/planner/dist/planner
```

Two columns of size. **Raw** is the file on disk. **Estimated transfer** is what crosses the network
once the server compresses it, which is what a person on a slow connection waits for. These are the
numbers lesson 1 promised: an application whose whole template is a heading and an empty outlet
already weighs this much, because the framework that calls your code is in the file too.

The production build is the default, because `angular.json` says so. Its **budgets** are limits the
build checks after every run:

```
ana@dev:~/planner$ node -e "console.log(require('./angular.json').projects.planner.architect.build.configurations.production.budgets)"
[
  { type: 'initial', maximumWarning: '500kB', maximumError: '1MB' },
  {
    type: 'anyComponentStyle',
    maximumWarning: '4kB',
    maximumError: '8kB'
  }
]
```

Past `maximumWarning`, the build warns; past `maximumError`, it fails. The second budget limits the
stylesheet of any one component. They exist so that a dependency added on a Friday that doubles the
download is a red build and not a slow site discovered in a month.

## What it wrote

```
ana@dev:~/planner$ ls dist/planner/browser
courses.json
favicon.ico
index.html
main-J4WVDBNH.js
styles-5INURTSO.css
```

`main-` followed by eight characters is the **content hash**: the name is computed from the
file's bytes. Change one line and the name changes, so a browser that cached yesterday's file
cannot mistake it for today's, and a server can tell browsers to keep every hashed file for a year.
`index.html` keeps its name and is the one file that must never be cached for long, because it is
the one that names the others.

## Serving it as a static host would

There is no Angular on a production server. The folder is a set of files, and any server that sends
files will do. Python, which Ubuntu installs with the system, has one built in; in a second
terminal:

```
ana@dev:~/planner$ python3 -m http.server 8081 --directory dist/planner/browser
Serving HTTP on 0.0.0.0 port 8081 (http://0.0.0.0:8081/) ...
```

```
ana@dev:~/planner$ look http://127.0.0.1:8081/
Study planner
```

No console lines this time: no Vite, because there is no dev server, and no development-mode
message, because this is the production build. Now ask the same server for an address the planner
will have from lesson 17:

```
ana@dev:~/planner$ look http://127.0.0.1:8081/courses/git
[error] Failed to load resource: the server responded with a status of 404 (File not found)
Error response

Error code: 404

Message: File not found.

Error code explanation: 404 - Nothing matches the given URI.
```

Python's server looked for a file called `courses/git`, found none, and sent its own error page. The application never
loaded, so it never had the chance to read the address and draw the right screen. **A host for an
Angular application has to answer every address it does not have a file for with `index.html`**,
and let the application decide. The dev server does it already, as two sections back showed for this very address.
Every hosting service has a setting for it, and the course `front-delivery` is where you set one.

Its terminal logged both requests, the second with its 404:

```
ana@dev:~/planner$ python3 -m http.server 8081 --directory dist/planner/browser
Serving HTTP on 0.0.0.0 port 8081 (http://0.0.0.0:8081/) ...
127.0.0.1 - - [23/Oct/2026 20:33:30] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 20:33:31] "GET /styles-5INURTSO.css HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 20:33:31] "GET /main-J4WVDBNH.js HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 20:33:32] code 404, message File not found
127.0.0.1 - - [23/Oct/2026 20:33:32] "GET /courses/git HTTP/1.1" 404 -
```

Stop it with Ctrl-C. The build output is not something to commit: `.gitignore`
already leaves `dist/` out, because it can always be built again from the source.
