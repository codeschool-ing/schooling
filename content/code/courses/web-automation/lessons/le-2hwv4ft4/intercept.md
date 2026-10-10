---
title: Waiting for a request by name, or answering it yourself
version: 1
---

**`cy.intercept` is the strongest thing Cypress has, and it comes straight from the server standing
in the network path.** A test declares a route: a method and an address. From then on, every
request the application makes that matches it is held up at the Cypress server, where the test
can watch it go by and wait for its answer, or answer it without the real server hearing a thing.

The first habit it replaces is the wrong one. A test that has to wait for the products is tempted
to sleep: `cy.wait(2000)`, two seconds, and hope. It works on a laptop and fails on a busy build
server, and on the days it passes it has wasted most of those two seconds. Lesson 3 measures what
that guess costs. `cy.wait` with a number is still in the API, and its documentation warns against
it for exactly this; the same command given the **name** of a route waits for that request instead,
however long it takes.

Save it as `cypress/e2e/network.cy.js`:

```javascript
describe('the products request', () => {
  it('waits for the answer, not for a number of seconds', () => {
    cy.intercept('GET', '/api/products').as('products');
    cy.visit('/');
    cy.wait('@products').its('response.statusCode').should('eq', 200);
    cy.get('#products').should('have.attr', 'aria-busy', 'false');
    cy.get('#products li').should('have.length', 8);
  });

  it('draws whatever the server answers, however late', () => {
    cy.intercept('GET', '/api/products', {
      delay: 1500,
      body: [{ id: 'banana', name: 'Banana', price: 590, unit: 'dozen' }],
    }).as('products');
    cy.visit('/');
    cy.get('#products').should('have.attr', 'aria-busy', 'true');
    cy.wait('@products');
    cy.get('#products li').should('have.length', 1);
  });
});
```

Like every spec in this lesson, it was checked against the package's type definitions and not run.

## Watching: the first test

`cy.intercept('GET', '/api/products')` with no answer attached only watches, and `.as('products')`
gives the route a name. **The route is declared before `cy.visit`.** The page asks for the products
as soon as its script runs, and a route declared after that request has left watches nothing.

`cy.wait('@products')` then waits for that request to be answered, and yields what Cypress saw of
it: the request and the response. `.its('response.statusCode')` takes one field out of that and
`should('eq', 200)` checks it. The two `should` lines after it read the page the response produced:
the list is no longer busy, and it holds eight items.

This is the shape lesson 3 needs. A test that waits for the answer it depends on, by name, is as
fast as the server on a good day and still correct on a bad one.

## Answering: the second test

Given a third argument, `cy.intercept` **answers the request itself**. Here the answer is one
product, and `delay: 1500` holds it back for a second and a half. The real `/api/products` is never
asked; `/api/basket` is not matched, so it still reaches the shop.

For a tester that buys two things that are hard to get from a real server:

- **A state on demand.** The page with its list still busy is a moment that lasts a few
  milliseconds on a laptop. Held for 1500 ms, it is long enough to check that the page says it is
  loading, every run, in the same way.
- **An answer the server will not give.** A shop with one product, an empty shop, a `500`: each is
  one object in the test rather than a change to the application. Lesson 15 is about the data a
  test needs, and this is one way to have it without touching anybody else's.

The idea is not Cypress's alone: Playwright's `page.route` holds requests in the same way, from
outside the browser. Cypress made it the ordinary way to write a test, and its form is the one most
people meet first.

## What a stub cannot tell you

**A stubbed answer tests the page and says nothing about the server.** The body in the second test
is a copy of what `/api/products` returns today. If the shop renamed `price` to `cents` tomorrow,
this test would keep passing, against an answer the real server no longer gives, while the shop
showed every price as blank. A suite that stubs everything is a suite that cannot see that kind of
break. The usual arrangement is a few tests that stub, for the states that are hard to reach, and
others that do not; checking the server's answers on their own is API testing, which the next
course, `api-mobile-automation`, is about.

One more thing the shop's flaws make visible. Answer `/api/products` with a `500` and a body that
is not JSON, and `app.js` throws when it tries to read it, as it did in lesson 1's Console section.
**Cypress fails the test when the application throws an error it does not catch**, whatever the test was checking, which is the
stronger position that section described. Its documentation shows how to switch this off for one
known error, with `Cypress.on('uncaught:exception', ...)`; a test that switches it off for every
error has given up the evidence.
