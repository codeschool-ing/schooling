---
title: Inside the browser, with a process beside it
version: 1
---

**Cypress runs your test inside the browser, in the same window as the application it tests.**
Selenium, in lesson 8, works from the other side: the test is a program outside the browser that
sends it commands, one at a time, through a driver. Playwright, which this course has used since
lesson 1 and which lesson 10 covers properly, is outside too. Most of what is good about Cypress,
and most of what limits it, follows from that one difference of position.

**Nothing in this lesson that needs Cypress itself was run.** Cypress comes in two parts: an npm
package, and a separate program the package downloads from Cypress's own server when it installs.
The machine these transcripts come from cannot reach that server. So the package was installed and
what it prints is captured, and the spec files are shown whole and were checked against the type
definitions the package ships. None of them was executed, and no Cypress run, result, screenshot or
timing appears anywhere in this lesson. You can install all of it; the next section says how.

## Two places a test can stand

The usual first picture is that every browser tool does the same job with a different syntax:
`cy.get` here, `page.locator` there. **The syntax is the small difference. Where the test code runs
is the large one.**

**Outside**, your test is a Node process and the browser is another program. Each step becomes a
message. Selenium sends it over HTTP to chromedriver, which passes it on to the browser; Playwright
sends it straight to the browser's own debugging protocol. The answer comes back the same way. The
test and the page share nothing but those messages, so every value the test reads from the page,
a text or a count, is a copy made at the moment it was asked for.

**Inside**, Cypress starts a browser and loads a page of its own into it, which its documentation
calls the runner. Your spec is bundled and runs as a script in that page, and your application is
loaded into a frame beside it. Next to the browser, Cypress keeps a Node process, the Cypress
server: it starts the browser, reads your files from disk, and stands between the browser and the
network as a proxy. Every request the application makes passes through it on the way to the
server it was meant for, which is what section 05 of this lesson uses.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two arrangements side by side. On the left, labelled Selenium and Playwright, the test is a Node process outside the browser, sending a command across and getting an answer back. On the right, labelled Cypress, the browser holds two frames in one window, the runner with the spec and the application; beside the browser a Cypress server, a Node process, starts it, and every request from the application passes through that server on its way to quitanda on port 3000.\"><text x=\"20\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">outside: Selenium, Playwright</text><rect x=\"20\" y=\"100\" width=\"125\" height=\"80\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"34\" y=\"130\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">your test</text><text x=\"34\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a Node process</text><path d=\"M150 125 L215 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M215 125 L206.0 120.0 L206.0 130.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"182\" y=\"117\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">command</text><path d=\"M215 158 L150 158\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M150 158 L159.0 163.0 L159.0 153.0 Z\" fill=\"var(--amber)\"></path><text x=\"182\" y=\"175\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">answer</text><rect x=\"220\" y=\"100\" width=\"120\" height=\"80\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"234\" y=\"130\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">the browser</text><text x=\"234\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the page</text><text x=\"20\" y=\"215\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">One message each way per step; whatever the</text><text x=\"20\" y=\"232\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">test reads from the page is copied across.</text><path d=\"M355 20 L355 290\" stroke=\"var(--wire)\" stroke-dasharray=\"3 4\"></path><text x=\"372\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">inside: Cypress</text><rect x=\"370\" y=\"45\" width=\"330\" height=\"135\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"384\" y=\"66\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">the browser</text><rect x=\"384\" y=\"78\" width=\"150\" height=\"74\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"396\" y=\"102\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the runner</text><text x=\"396\" y=\"122\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">your spec runs</text><text x=\"396\" y=\"138\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">here, as a script</text><rect x=\"540\" y=\"78\" width=\"148\" height=\"74\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"552\" y=\"102\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a frame</text><text x=\"552\" y=\"122\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the application</text><text x=\"535\" y=\"171\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">one window, one event loop</text><rect x=\"370\" y=\"225\" width=\"190\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"384\" y=\"250\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Cypress server</text><text x=\"384\" y=\"270\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a Node process</text><rect x=\"590\" y=\"225\" width=\"110\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"604\" y=\"250\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">quitanda</text><text x=\"604\" y=\"270\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">:3000</text><path d=\"M420 225 L420 185\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M420 185 L415.0 194.0 L425.0 194.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"428\" y=\"207\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">starts it</text><path d=\"M612 185 L545 225\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M545 225 L555.3 224.7 L550.2 216.1 Z\" fill=\"var(--amber)\"></path><path d=\"M562 255 L586 255\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M586 255 L577.0 250.0 L577.0 260.0 Z\" fill=\"var(--amber)\"></path><text x=\"630\" y=\"207\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">requests</text></svg>", "caption": "The same click from two places. Outside, it is a message; inside, it is a script on the page, and the page's requests pass through Cypress on their way out."}
```

## What that position buys

- **The application is within reach.** A test can take the page's `window` with `cy.window()`,
  read its `localStorage`, call one of its functions, or replace one with `cy.stub()`. It can stop
  the page's clock with `cy.clock()` and move it forward by hand. Nothing is copied across a
  socket, because there is no socket.
- **The test sees the page between frames.** The spec and the application share one event loop, so
  Cypress checks the DOM in the same browser that is changing it, and tries a check again as soon
  as it fails. Retrying is the subject of the next section but one.
- **The runner is a window you can read.** `npx cypress open` shows the commands of a test in a
  list beside the application, and its documentation describes going back to any command to see
  the page as it was at that moment. This needs a screen, and the machine these lessons were
  recorded on has none and no Cypress binary, so there is no picture of it here.

## What it costs

The same position puts your test under the rules the browser applies to every script on a page.
A script may not read the contents of a frame that came from another origin, and a Cypress test is
a script on a page, so the rule applies to it; lesson 10's Playwright, standing outside, is not
bound by it. A script in one tab cannot drive another tab. And the browser has to be one Cypress
knows how to start and load its runner into. Section 06 takes each of these in turn and
measures the first one for real.
