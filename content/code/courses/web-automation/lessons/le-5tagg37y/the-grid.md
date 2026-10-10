---
title: The grid: one address, many browsers
version: 1
---

Section 02 ended on the fact that a driver is only a port, and the test only needs to reach it.
**Selenium Grid** is that fact built into a service: one address that accepts WebDriver requests
and hands each new session to a browser on one of many machines. A team uses one to run the same
suite against Chrome on Linux, Edge on Windows and Safari on a Mac without owning all three at
every desk, or to run many sessions at once, which lesson 19 is about.

The common belief is that the grid is a special mode of the test, with its own API. **To the test
it is just another driver.** It speaks the same protocol on its own port, 4444, and the only line
that changes in the test is where the builder sends its requests:

```javascript
driver = await new Builder()
  .forBrowser('chrome')
  .setChromeOptions(options)
  .usingServer('http://localhost:4444')
  .build();
```

`selenium-webdriver` also reads the same address from an environment variable,
`SELENIUM_REMOTE_URL`, which is how the run below points the unchanged `selenium/shop.test.js` at
a grid without editing it.

## What is inside

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Tests on the left send WebDriver requests to one address, port 4444. Inside the grid, four parts: the router takes every request; the session queue holds new-session requests; the distributor matches each to a free slot on a node; the session map remembers which node holds each session. On the right, three nodes on three machines, each with its own browsers and drivers: Chrome on one, Firefox and Edge on another, Safari on a third.\"><rect x=\"20\" y=\"130\" width=\"130\" height=\"70\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"85\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">your tests</text><text x=\"85\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">any machine</text><path d=\"M155 165 L225 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M225 165 L215 159 L215 171 Z\" fill=\"var(--phosphor)\"></path><text x=\"190\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">:4444</text><rect x=\"230\" y=\"30\" width=\"220\" height=\"270\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"340\" y=\"54\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">the hub</text><rect x=\"246\" y=\"70\" width=\"188\" height=\"46\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"340\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">router</text><text x=\"340\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every request comes in here</text><rect x=\"246\" y=\"126\" width=\"188\" height=\"46\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"340\" y=\"146\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">session queue</text><text x=\"340\" y=\"163\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">new sessions wait their turn</text><rect x=\"246\" y=\"182\" width=\"188\" height=\"46\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"340\" y=\"202\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">distributor</text><text x=\"340\" y=\"219\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">picks a node with a free slot</text><rect x=\"246\" y=\"238\" width=\"188\" height=\"46\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"340\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">session map</text><text x=\"340\" y=\"275\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">which node holds which session</text><rect x=\"530\" y=\"40\" width=\"170\" height=\"70\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"615\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">node · Linux</text><text x=\"615\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Chrome · Chrome</text><path d=\"M455 75 L525 75\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M525 75 L515 69 L515 81 Z\" fill=\"var(--amber)\"></path><rect x=\"530\" y=\"130\" width=\"170\" height=\"70\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"615\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">node · Windows</text><text x=\"615\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Firefox · Edge</text><path d=\"M455 165 L525 165\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M525 165 L515 159 L515 171 Z\" fill=\"var(--amber)\"></path><rect x=\"530\" y=\"220\" width=\"170\" height=\"70\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"615\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">node · macOS</text><text x=\"615\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Safari</text><path d=\"M455 255 L525 255\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M525 255 L515 249 L515 261 Z\" fill=\"var(--amber)\"></path><text x=\"490\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each node: browsers + drivers</text></svg>", "caption": "One address in front of many browsers. A test asks for a browser by its capabilities and never learns which machine it got."}
```

Selenium Grid 4 is a handful of parts, and their names appear in its log, so they are worth
knowing:

- the **router** is the address. Every request comes in there, and it forwards each one: a new
  session to the queue, a command in an existing session to the node that holds it;
- the **session queue** holds requests for new sessions, in order, until something can take them;
- the **distributor** knows every node and its free **slots**, and gives each queued request to a
  node whose slots match the capabilities it asked for, `browserName: chrome` for instance;
- the **session map** remembers which node holds which session;
- a **node** is a machine with browsers and drivers. It starts a session when it is given one, and
  from then on the router sends that session's commands straight to it.

Those parts can run as separate processes on separate machines, which is how a large grid is
built. `hub` mode puts the first four in one process and each machine joins it with `node` mode.
**`standalone` puts all of them, and one node, in a single process**, which is what you run on one
computer to see how it works.

## A grid on your own computer

The grid is a Java program, so it needs Java; this one ran on OpenJDK 21:

```
%%CAP java%%
```

Download `selenium-server-4.51.0.jar` from the Selenium project's releases on GitHub, the asset of
the `selenium-4.51.0` release, into your home folder, and start it in a terminal of its own:

```
%%CAP grid-start%%
```

Read it from the top. The node looked on the `PATH` for drivers, used Selenium Manager to check
them, and offered four slots for each browser it believed it could drive, one per processor. The
last line gives the address. **It offered Firefox and Edge as well, and neither is installed on
this machine**: Selenium Manager could not check them without the internet, and the node offered
the slots anyway. A slot is a promise the node makes, not a browser anybody has checked. The address in the log is the machine's network
address; `localhost:4444` reaches the same server.

With the shop running in another terminal, run the same test through the grid:

```
%%CAP grid-run%%
```

It passed, and the grid's terminal printed the story of that session as it happened:

```
%%CAP grid-log%%
```

The **distributor** received a request for `browserName: chrome`, the **node** created the
session, the **session map** recorded which node had it, and when the test called `quit()` the
slot was released for the next request. Nothing in the test knew any of this happened.

**One thing changes when the node is another machine:** `localhost` in the test's `driver.get()`
is resolved by the browser, on the node, where no shop is running. On a real grid the application
under test needs an address the nodes can reach. Stop the grid with Ctrl+C when you are done.
