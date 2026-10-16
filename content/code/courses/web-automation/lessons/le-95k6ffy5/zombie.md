---
title: Zombie.js, and what its last release says
version: 1
---

Zombie.js went on npm in 2011 with a promise in its subtitle: "Insanely fast, headless full-stack
testing using Node.js". For years it was what a Node developer meant by testing a page without a
browser. **Today it is a tool to recognise in an old project, not one to start with**, and the
registry says why before any code runs.

## How it reads

Zombie gives you one object, a `Browser`, that loads pages and acts on them in the words a person
would use: visit, fill, press a button, then assert. Its README opens with this example, written
for the Mocha runner:

```javascript
const Browser = require('zombie');

// We're going to make requests to http://example.com/signup
// Which will be routed to our test server localhost:3000
Browser.localhost('example.com', 3000);

describe('User visits signup page', function() {

  const browser = new Browser();

  before(function(done) {
    browser.visit('/signup', done);
  });

  describe('submits form', function() {

    before(function(done) {
      browser
        .fill('email',    'zombie@underworld.dead')
        .fill('password', 'eat-the-living')
        .pressButton('Sign Me Up!', done);
    });

    it('should be successful', function() {
      browser.assert.success();
    });

    it('should see welcome page', function() {
      browser.assert.text('title', 'Welcome To Brains Depot');
    });
  });
});
```

**Every action takes a callback, and the callback is the wait.** `visit` calls `done` when Zombie
decides the page has finished loading; `pressButton` calls it when the form has been sent and the
next page has loaded. You never write a wait yourself. That reads well, and it puts the whole
question of *when is the page ready* inside Zombie, where you cannot see it.

## Its state, from the registry

`npm view` asks the registry about a package without installing it. The list of releases ends
here:

```
ana@laptop:~/quitanda$ npm view zombie time | tail -6
  '6.1.0': '2018-04-02T23:14:43.758Z',
  '6.1.1': '2018-04-07T17:12:16.567Z',
  '6.1.2': '2018-04-29T21:26:50.740Z',
  '6.1.3': '2018-08-12T03:18:03.070Z',
  '6.1.4': '2018-11-27T17:53:28.989Z'
}
```

**The last release is 6.1.4, from 27 November 2018.** Nothing has been published since. What it
depends on tells the rest:

```
ana@laptop:~/quitanda$ npm view zombie version dependencies.jsdom dependencies.request
version = '6.1.4'
dependencies.jsdom = '11.12.0'
dependencies.request = '^2.85.0'
ana@laptop:~/quitanda$ npm view request deprecated
request has been deprecated, see https://github.com/request/request/issues/3142
```

Zombie pins jsdom at exactly 11.12.0, and this lesson installs jsdom 30.1.2: nineteen major
versions of DOM work it will never receive. It fetches pages with `request`, which its own authors
have deprecated. Neither is a reason a test fails today. Both say that nobody is keeping the tool
level with the web.

## Run once, outside the project

To see it for yourself, use a scratch folder, **not** `~/quitanda`: there is no reason to put an
unmaintained package into the project's `package.json`. Make `~/zombie-try`, go into it and
install:

```
ana@laptop:~/zombie-try$ npm install zombie@6.1.4
npm warn deprecated request-promise-native@1.0.9: request-promise-native has been deprecated because it extends the now deprecated request package, see https://github.com/request/request/issues/3142
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated whatwg-encoding@1.0.5: Use @exodus/bytes instead for a more spec-conformant and faster implementation
npm warn deprecated abab@2.0.6: Use your platform's native atob() and btoa() methods instead
npm warn deprecated domexception@1.0.1: Use your platform's native DOMException instead
npm warn deprecated left-pad@1.3.0: use String.prototype.padStart()
npm warn deprecated w3c-hr-time@1.0.2: Use your platform's native performance.now() and performance.timeOrigin.
npm warn deprecated uuid@3.4.0: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated request@2.88.2: request has been deprecated, see https://github.com/request/request/issues/3142
npm warn deprecated core-js@2.6.12: core-js@<3.23.3 is no longer maintained and not recommended for usage due to the number of issues. Because of the V8 engine whims, feature detection in old core-js versions could cause a slowdown up to 100x even if nothing is polyfilled. Some versions have web compatibility issues. Please, upgrade your dependencies to the actual version of core-js.

added 104 packages in 4s

4 packages are looking for funding
  run `npm fund` for details
```

Every deprecation warning there is a package Zombie pulls in. Then write a file named `visit.js` in
that folder. It visits the shop's home page, which must be running in another terminal, and counts
the cards twice: when `visit` says the page is ready, and two seconds later.

```javascript
// Zombie against the shop: count the cards when visit() is done, and later.
const Browser = require('zombie');

const browser = new Browser({ site: 'http://localhost:3000' });

browser.visit('/', () => {
  console.log(`when visit() called back: ${browser.queryAll('#products li').length} cards`);
  setTimeout(() => {
    console.log(`two seconds later: ${browser.queryAll('#products li').length} cards`);
  }, 2000);
});
```

```
ana@laptop:~/zombie-try$ node visit.js
(node:19961) [DEP0044] DeprecationWarning: The `util.isArray` API is deprecated. Please use `Array.isArray()` instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
when visit() called back: 0 cards
two seconds later: 8 cards
```

**Zero, then eight.** The callback came back before the cards were drawn. The `DEBUG` variable
switches on Zombie's own log, and it shows the order of events:

```
ana@laptop:~/zombie-try$ DEBUG=zombie node visit.js
2026-10-16T01:17:17.222Z zombie Opened window http://localhost:3000/ 
(node:20018) [DEP0044] DeprecationWarning: The `util.isArray` API is deprecated. Please use `Array.isArray()` instead.
(Use `node --trace-deprecation ...` to show where the warning was created)
2026-10-16T01:17:17.263Z zombie GET http://localhost:3000/ => 200
2026-10-16T01:17:17.291Z zombie Loaded document http://localhost:3000/
2026-10-16T01:17:17.296Z zombie GET http://localhost:3000/app.js => 200
2026-10-16T01:17:17.315Z zombie Event loop is empty
when visit() called back: 0 cards
2026-10-16T01:17:17.320Z zombie GET http://localhost:3000/api/products => 200
2026-10-16T01:17:17.335Z zombie GET http://localhost:3000/api/basket => 200
two seconds later: 8 cards
```

Zombie fetched `app.js`, ran it, reported its event loop empty, and called back. Only after that
did the requests for `/api/products` and `/api/basket` go out. Whatever the reason inside Zombie,
the request the page depends on was not part of what it waited for. A test written in its style,
`visit` and then `assert`, fails on a page that is fine; a check that the list starts empty passes
for the wrong reason.

It is lesson 3's race, moved inside the tool. **A tool that decides for you when a page is ready is
only as good as its idea of ready**, and Zombie's was written for pages of 2018. Playwright's
answer is to wait on the thing you assert, not on the page (lesson 10). Delete `~/zombie-try` when
you are done.
