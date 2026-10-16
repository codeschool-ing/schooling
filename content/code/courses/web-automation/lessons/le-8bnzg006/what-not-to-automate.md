---
title: What to leave to a person, or to another layer
version: 1
---

**The common mistake is to treat the manual tests as the backlog of the automated ones**, as
though every case a person runs is waiting its turn to become code, and a suite is finished when
the list is empty. Some cases should never move. A few would cost more than any defect they could
find, and others a robot cannot do at all, because the answer needs judgement, or the page
belongs to somebody else, or the page exists to stop robots. For each, the useful question is
what to do instead, and there is always an answer.

| the case | why not a browser test | what to do instead |
|---|---|---|
| a check you will run once | writing costs more than one run by hand | run it by hand, and write down what you saw |
| a feature nobody has seen yet | you do not know the right answer, so a test would freeze a guess | explore it first (`manual-testing` lesson 11); automate what turns out to matter |
| how a page looks, how the copy reads | a pixel difference is not a judgement | a person looks; a test checks the facts underneath, such as no sideways scroll |
| a feature about to change | every test written now is maintained, or deleted, next month | test it by hand until the design settles |
| a rule a lower layer can check | a browser is the slowest place to check a sum | the unit or API test lesson 21 puts below the browser |
| a page that belongs to somebody else | it changes without telling you, and a red run is not yours to fix | stub the boundary, as lesson 9's `cy.intercept` did, and test your side of it |
| a CAPTCHA | it exists to tell a robot from a person, so passing it is a defect in the CAPTCHA | turn it off in the test environment, or use the provider's documented test keys |
| a payment provider | real cards, real money, a page that is not yours | the provider's sandbox and its test cards, within what its test mode supports |

## Three of them in more detail

**A new feature first gets a person.** Exploratory testing, with a charter and notes, is how a
tester learns what a feature does and what can go wrong with it, which is exactly the knowledge a
good automated test needs. A test written before that encodes whatever the author assumed. The
search page of lesson 3 is a fair example: nothing in its specification said *the last answer to
arrive wins*, and a person typing quickly is how you would have met the defect first. The test came
after, and was precise because of it.

**Looks are judged; facts are checked.** The experiment in the previous section put both on one
table. Whether a border is the right green is a decision somebody made, and a robot comparing
pixels can only report that it changed. Whether the page scrolls sideways at 360 pixels, whether a
price is in the page, whether a target is 24 pixels across: those have answers, and lesson 7 checked
them. Split a visual question that way, and the robot gets the half with an answer.

**Somebody else's page is a boundary, not a test subject.** A payment page, a map, a login run by
another company: each changes on its own schedule, and a test that drives it fails on their
release day rather than on yours. Lesson 9 met Cypress's limits with a second origin; Playwright
would drive one, and that is not the question. The question is what a red run would tell you, and
the answer is *something about a company that does not read your reports*. Test that your shop
sends the right request and handles each answer it can get, including a refusal and a timeout, with
the other side stubbed. The provider's own test mode is for the one end-to-end run that checks the
two of you still agree, and its documentation says which cards and answers that mode supports.

## A CAPTCHA is not a test problem

A CAPTCHA exists so that a program cannot pass it. A test that solves one, by any means, has
shown that the CAPTCHA does not work, and that is a defect to report rather than a technique to
keep. The tester's side is two questions. In the test environment, is the CAPTCHA off, or answering
to the provider's documented test keys, so the rest of the form can be tested? And in production,
is it on? The second is one request, made by a person or by a check that only reads the page.

## When automating a case is right after all

Turn the table round and the cases that deserve a browser test have a shape too: **run often,
stable in design, with an answer a machine can compare, and costly when they break**. The basket
total, the search that must settle on what was typed, the page that must not scroll sideways on a
phone. The course's tests mostly look like that, and the two sections that follow are about keeping
them that way.
