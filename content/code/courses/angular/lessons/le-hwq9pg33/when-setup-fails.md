---
title: When the setup fails
version: 1
---

Setting up is where a course loses people, and almost always to one of a handful of failures. Each
one below was produced on purpose on the recording machine, so the message you see is the one you
will get. Two rules first, because they settle most cases on their own.

**Read the first error, not the last line.** npm prints a page and ends with the path of a log file;
the line that says what went wrong is near the top, after `npm error code`.

**Search for the exact words.** Copy the message without your own paths and file names into a search
engine, in quotes. Somebody has had it before you, and the answer is usually in the project's own
issue tracker.

## The CLI refuses your Node

The Angular CLI checks the version of Node before it does anything. Angular 22, the newest major
when this course was recorded, asks for more than the Node this track installs. Asking it for its
version shows both halves of the answer: npm warns about each package first, then the CLI itself
stops.

```
ana@dev:~$ npx @angular/cli@22.2.4 version 2>&1 | head -12
npm warn exec The following package was not found and will be installed: @angular/cli@22.2.4
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@angular/cli@22.2.4',
npm warn EBADENGINE   required: {
npm warn EBADENGINE     npm: '^6.11.0 || ^7.5.6 || >=8.0.0',
npm warn EBADENGINE     node: '^22.22.3 || ^24.15.0 || >=26.0.0',
npm warn EBADENGINE     yarn: '>= 1.13.0'
npm warn EBADENGINE   },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@angular-devkit/architect@0.2202.4',
```

`EBADENGINE` is npm reading the `engines` field each package declares and noticing that `v22.22.0`
is outside it. npm only warns, and goes on. The CLI is the one that refuses:

```
ana@dev:~$ npx @angular/cli@22.2.4 version 2>&1 | tail -4
The Angular CLI requires a minimum Node.js version of v22.22.3 or v24.15.0 or v26.0.0.

Please update your Node.js version or visit https://nodejs.org/ for additional instructions.
```

**This is why the course uses Angular 21.** Its CLI accepts Node from 22.12, so it runs on the Node
the whole track shares, and it is in long-term support until May 2027, eighteen months after its
release in November 2025. Lesson 2 pins it, and its last section shows what moving to 22 would
take. If you see this message for 21, your Node is older than 22.12: `node --version` will say so, and `javascript` lesson 1 is
where it was installed.

## npm cannot reach the registry

Every `npm install` and every `npx` downloads from `registry.npmjs.org`. When the network between
you and it is in the way, a company proxy, a firewall, a hotel's Wi-Fi login page, the error is
always about a connection. This one was made by pointing npm at a port where nothing listens:

```
ana@dev:~$ npm view @angular/cli version --registry http://127.0.0.1:9/
npm error code ECONNREFUSED
npm error syscall connect
npm error errno ECONNREFUSED
npm error FetchError: request to http://127.0.0.1:9/@angular%2fcli failed, reason: connect ECONNREFUSED 127.0.0.1:9
npm error     at ClientRequest.<anonymous> (/home/ana/.local/node/lib/node_modules/npm/node_modules/minipass-fetch/lib/index.js:130:14)
npm error     at ClientRequest.emit (node:events:519:28)
npm error     at emitErrorEvent (node:_http_client:107:11)
npm error     at _destroy (node:_http_client:954:9)
npm error     at onSocketNT (node:_http_client:974:5)
npm error     at process.processTicksAndRejections (node:internal/process/task_queues:91:21) {
npm error   code: 'ECONNREFUSED',
npm error   errno: 'ECONNREFUSED',
npm error   syscall: 'connect',
npm error   address: '127.0.0.1',
npm error   port: 9,
npm error   type: 'system'
npm error }
npm error
npm error If you are behind a proxy, please make sure that the
npm error 'proxy' config is set properly.  See: 'npm help config'
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-29T23_33_59_073Z-debug-0.log
```

`ECONNREFUSED` means something answered and said no; `ETIMEDOUT` means nothing answered at all;
`ENOTFOUND` means the name of the registry did not resolve, which is a DNS problem. npm's own
suggestion at the bottom is the right one for a company network: ask whoever runs it for the proxy's
address, and set it with `npm config set proxy` and `npm config set https-proxy`.

`npm config get registry` says where npm is pointed. It should be `https://registry.npmjs.org/`
unless your company runs a mirror.

## Two failures lesson 2 shows where they happen

- **npm stops with `Cannot read properties of null (reading 'edgesOut')`** while installing a new
  project. That is a defect in npm 10.9.4 itself, the version this Node ships with, and it is
  triggered by the packages a new Angular project asks for. Lesson 2, section "A project, at
  exact versions", shows it and the one-line setting that avoids it.
- **`Port 4200 is already in use`** when you start the dev server: a dev server from earlier is
  still running in another terminal. Lesson 2 shows what to do with it.

## The disk fills up

A new Angular project is a few hundred megabytes, almost all of it in `node_modules`, and npm keeps
a cache of everything it downloaded in `~/.npm`. When the disk runs out, npm says `ENOSPC`. A
project you finished can lose its `node_modules` safely, because `npm ci` puts it back exactly from
`package-lock.json`; `npm cache clean --force` empties the cache.
