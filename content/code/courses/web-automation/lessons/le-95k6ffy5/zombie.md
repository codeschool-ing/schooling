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
%%CAP zombie-time%%
```

**The last release is 6.1.4, from 27 November 2018.** Nothing has been published since. What it
depends on tells the rest:

```
%%CAP zombie-deps%%
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
%%CAP zombie-install%%
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
%%CAP zombie-visit%%
```

**Zero, then eight.** The callback came back before the cards were drawn. The `DEBUG` variable
switches on Zombie's own log, and it shows the order of events:

```
%%CAP zombie-debug%%
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
