---
title: The protocol: a test, a driver and a browser
version: 1
---

The picture most people start with is that Selenium is a program that clicks around inside the
browser, the way a browser extension would. **It is three programs, and they talk over HTTP.**
Your test is an HTTP client. The **driver**, `chromedriver` for Chrome, is a small HTTP server
that listens on a port. The browser sits behind the driver, and only the driver talks to it, in
whatever way that browser's makers built for the purpose. Nothing of Selenium runs inside the
page.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Three boxes in a row. Your test, using selenium-webdriver, is an HTTP client. It sends requests such as POST /session to chromedriver on localhost port 9515, an HTTP server, and gets JSON back; that conversation is the W3C WebDriver standard. Chromedriver drives Chrome, where the page runs, through the browser's own channel.\"><rect x=\"20\" y=\"50\" width=\"170\" height=\"110\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><rect x=\"275\" y=\"50\" width=\"170\" height=\"110\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><rect x=\"530\" y=\"50\" width=\"170\" height=\"110\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"105\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper)\">your test</text><text x=\"105\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">selenium-webdriver</text><text x=\"105\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">an HTTP client</text><text x=\"360\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">chromedriver</text><text x=\"360\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">localhost:9515</text><text x=\"360\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">an HTTP server</text><text x=\"615\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper)\">Chrome</text><text x=\"615\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the page runs here</text><text x=\"615\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">does the work</text><path d=\"M195 92 L270 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M270 92 L260 86 L260 98 Z\" fill=\"var(--phosphor)\"></path><path d=\"M270 120 L195 120\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><path d=\"M195 120 L205 114 L205 126 Z\" fill=\"var(--phosphor-dim)\"></path><text x=\"232\" y=\"40\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">POST /session/…</text><text x=\"232\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">requests out, JSON back</text><path d=\"M450 105 L525 105\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M525 105 L515 99 L515 111 Z\" fill=\"var(--amber)\"></path><text x=\"488\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the browser's</text><text x=\"232\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">W3C WebDriver</text><text x=\"488\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">own channel</text></svg>", "caption": "Three programs. Only the middle one ever touches the browser, and the standard covers only the left-hand arrow."}
```

The language between the first two is a **W3C standard, WebDriver**. Every command a test can
give is one HTTP request: `POST /session` opens a browser, `POST /session/{id}/url` sends it to an
address, `POST /session/{id}/element` finds an element, `GET .../text` reads it, `DELETE
/session/{id}` closes it. The answers are JSON. Because it is a standard, the same request works
against `chromedriver`, Firefox's `geckodriver` or Apple's `safaridriver`, and a library for any
language can speak it. Selenium's libraries for Java, Python, C#, Ruby and JavaScript are each a
tidy way of writing these requests and no more.

## Selenium in the project

The shop's project gets a second testing library beside Playwright. `package.json` gains one line,
the exact version of `selenium-webdriver` these transcripts were recorded with. Replace the file
with this one, as `package.json`:

```json
{
  "name": "quitanda",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node app/server.js",
    "test": "playwright test"
  },
  "devDependencies": {
    "@playwright/test": "1.56.0",
    "selenium-webdriver": "4.51.0"
  }
}
```

```
%%CAP npm-install%%
```

That installed the library and, inside it, a small program called **Selenium Manager**, whose job
is to find a driver that fits your browser and download one if there is none. Ask it which driver
it would use for Chrome. The path below is the Linux one; on a Mac the folder is `bin/macos`, and
on Windows it is `bin\windows\selenium-manager.exe`:

```
%%CAP manager%%
```

The last two lines are the answer: a driver and a browser. Section 04 reads the rest of that
output; what matters here is that you now have a `chromedriver` and know where it is. On your
machine the path is in a cache folder, something like `~/.cache/selenium/chromedriver/linux64/`
followed by a version; on the machine these transcripts come from, it is on the `PATH`, so the
name alone is enough. Use the path yours printed.

## Holding the conversation by hand

**You can speak the protocol yourself with `curl`**, and doing it once makes every later error
message easier to read. You need three terminals: the shop running in the first (`npm start` in
`~/quitanda`), the driver in the second, and the requests in the third. On Windows, run these in
Git Bash, which comes with `curl` and quotes the way the transcripts do; PowerShell's quoting rules
would mangle the JSON.

Start the driver on the port the standard suggests:

```
%%CAP chromedriver%%
```

It is now a web server, and it answers on `/status` like one:

```
%%CAP status%%
```

**A session is one browser, opened by one request.** The body says which browser and with which
options; `--headless=new` asks Chrome to run without a window, because the machine these
transcripts come from has no screen:

```
%%CAP session%%
```

Two things in the answer matter. `browserVersion` says which Chrome the driver found, and
`sessionId` is the handle for everything that follows: every later address carries it. Paste
yours where this transcript has its own. Send the browser to the shop:

```
%%CAP navigate%%
```

`null` is the standard's way of saying *done, nothing to report*. Now find the heading of the
Banana card, with the same CSS selector you would try in the Elements panel:

```
%%CAP find%%
```

**An element comes back as a reference, never as the element.** The long string under that odd
key, `element-6066-11e4-a52e-4f735466cecf`, which the standard fixes so that no page's own JSON
can be mistaken for it, is the driver's name for a node in the page. To learn anything about it,
you ask again:

```
%%CAP text%%
```

And close the session, which closes the browser:

```
%%CAP delete%%
```

## What that costs, and what it explains

That was five round trips to read one word. **Every Selenium command is one of these requests**,
whatever the library makes it look like: `driver.findElement(...)` is the `POST .../element` you
just typed, and `getText()` is the `GET .../text`. Three things follow, and lessons 9 and 10 come
back to each of them.

- A test is a **conversation from outside the page**. Between two of your requests the page goes
  on running, so a script can change it while the test is deciding what to do next. You saw the
  shop do that in lesson 1, and lesson 3 is about what it does to a test.
- The element reference can go **stale**. It names a node at the time it was found. If the page
  throws that node away and draws a new one, the reference names nothing, and the driver says so.
- The test and the browser **need not be on the same machine**. The driver only needs a port your
  test can reach, which is the whole idea of the grid at the end of this lesson.

Typed by hand, the seconds between your commands were enough for the shop to fetch its products
before you asked for the banana. A program asks within milliseconds, and the next section shows
what it does instead.
