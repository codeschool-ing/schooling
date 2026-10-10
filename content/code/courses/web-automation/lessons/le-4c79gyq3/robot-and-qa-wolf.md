---
title: Robot Framework, QA Wolf, and how a team chooses
version: 1
---

The last two names on the list are the furthest from Playwright, and each one answers a different
question. **Robot Framework changes who can write a test. QA Wolf changes who writes it at all.**

## Robot Framework

Robot Framework calls itself "a generic open source automation framework for acceptance testing,
acceptance test driven development (ATDD), and robotic process automation (RPA)". It is written in
Python, at 7.5 on PyPI, and its development is sponsored by a non-profit foundation. Its tests are not code in the usual
sense: **a test is a list of keywords**, each one a short phrase followed by its arguments, separated
by two or more spaces. The keywords come from libraries, and for a browser there are two:
**SeleniumLibrary** (6.9.0), which works through Selenium and so through WebDriver, and the
**Browser** library (20.6.0), which its description says is "powered by Playwright".

The banana test with SeleniumLibrary, in a file such as `banana.robot`; Robot Framework was not
installed for this course, and this was not run:

```
*** Settings ***
Library    SeleniumLibrary

*** Test Cases ***
A banana goes into the basket
    Open Browser    http://localhost:3000/    headlesschrome
    Wait Until Element Is Visible    css:[data-testid=product-banana] button
    Click Button    css:[data-testid=product-banana] button
    Wait Until Element Contains    css:[data-testid=basket-count]    1
    [Teardown]    Close Browser
```

**The point is the next layer up.** A team writes its own keywords out of these, `Add Banana To
Basket` or `Basket Should Hold    1`, and the test cases become sentences a business analyst can
read and even write, which is the acceptance-testing idea in the description. The price is a
second language between the tester and the browser. When a keyword misbehaves, somebody has to
read the Python or the Selenium underneath, and the tables hide nothing from that person. **A team
picks it** when its testers are not programmers, when the company already uses Python, or when the
same tool has to drive things other than browsers, which Robot's other libraries do.

## QA Wolf, a service

QA Wolf is a company, and what it sells is **the work rather than a tool**. As the service is
commonly described, its engineers write end-to-end tests for your application as Playwright code, run them on
its own machines, keep them working as the application changes, and look at each failure before
telling you about it. This course has not used it, and its terms, prices and promises are its own
to state; read them on its site, not here.

The company did once publish a tool. The npm package `qawolf` set up browser tests from your machine, and
the registry now marks it deprecated, with a message that sends readers to the company's e-mail
address. That is the model in one line: the tool became a service.

What a team weighs is the same as in any outsourcing decision. It gets a suite without hiring
for one. It gives up having the knowledge of *what is tested and why* inside the team, which is
what `qa-fundamentals` lesson 20 says decides where testing effort goes. Ask what happens to the
tests when the contract ends, and who decides what is worth a test, before asking how many tests
there will be.

## How a team chooses

Feature lists are the last thing that decides it. In order, the questions that usually do:

1. **What language and runner does the team already use?** Python points at Robot Framework or
   Selenium for Python; a Jest suite points at a library inside Jest; a TypeScript front end
   points at Playwright or WebdriverIO.
2. **Which browsers must it reach?** CDP stops at Chromium, so Puppeteer cannot test Safari.
   WebDriver reaches every browser with a driver, and Playwright reaches WebKit through its own build.
3. **What already runs the tests?** A grid of WebDriver machines or a cloud provider's browsers is
   an investment, and WebdriverIO, Nightwatch and Selenium use it as it is.
4. **Who writes the tests?** Programmers, testers who do not program, or nobody inside the
   company.

A team that answers those four has usually chosen before the comparison table is open. That is
no failure of judgement: **a tool the team already knows, on the browsers it must cover, beats
a better one nobody will maintain.** Lesson 22 asks the same kind of question about which tests
are worth writing at all.
