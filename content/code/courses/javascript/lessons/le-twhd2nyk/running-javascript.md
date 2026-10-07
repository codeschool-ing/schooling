---
title: Two places to run it
version: 1
---

**JavaScript is a language, and a language needs a program to run it.** That program is called a
host. This course uses two: a browser, where JavaScript was born in 1995 and where every page with
a script runs some of it, and **Node.js**, which takes the same language out of the browser and
runs it like any other program on your computer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two hosts around one language. On the left, the browser: the V8 engine runs the language, and the browser adds document, localStorage, fetch and setTimeout. On the right, Node.js: the same V8 engine, with process, fs, fetch and setTimeout added instead.\"><rect x=\"20\" y=\"16\" width=\"330\" height=\"218\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the browser (Chromium)</text><rect x=\"40\" y=\"56\" width=\"290\" height=\"62\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">the language</text><text x=\"185.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">run by the V8 engine</text><text x=\"185\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what the host adds</text><rect x=\"40\" y=\"156\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">document</text><rect x=\"190\" y=\"156\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">localStorage</text><rect x=\"40\" y=\"192\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fetch</text><rect x=\"190\" y=\"192\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">setTimeout</text><rect x=\"370\" y=\"16\" width=\"330\" height=\"218\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Node.js</text><rect x=\"390\" y=\"56\" width=\"290\" height=\"62\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">the language</text><text x=\"535.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">run by the V8 engine</text><text x=\"535\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what the host adds</text><rect x=\"390\" y=\"156\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">process</text><rect x=\"540\" y=\"156\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fs</text><rect x=\"390\" y=\"192\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fetch</text><rect x=\"540\" y=\"192\" width=\"140\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">setTimeout</text></svg>", "caption": "The language is the same in both. Of what each host adds, only the two outlined in amber, fetch and setTimeout, exist in both."}
```

The language in the middle is the same. What changes is what each host adds around it. A browser
gives your program the page, as `document`, and a way to store things for the next visit. Node
gives it the computer instead: files, the process it runs in, a network server. Lessons 11 and 12
are about the browser's half, and the rest of the course is the language. **That seam is
deliberate**: a later course on Node needs everything here except the page.

## Node: a file and a command

The first thing to check on any machine is the version of Node, from `~/js`, where your work goes:

```
ana@dev:~/js$ node --version
v22.22.0
```

A program is a text file ending in `.js`. ana writes one with two lines:

```javascript
console.log("Hello from Node");
console.log(2 + 3);
```

`console.log` prints whatever it is given, and `node` runs the file from the top to the bottom:

```
ana@dev:~/js$ node hello.js
Hello from Node
5
```

For a single expression there is a shortcut. `node -p` evaluates what you give it and prints the
result, which is handy for checking how something behaves without writing a file:

```
ana@dev:~/js$ node -p '2 ** 10'
1024
```

## The browser: a page and its console

In a browser, JavaScript arrives inside a page. A `<script>` element holds the code, and the
browser runs it while it reads the page:

```html
<!doctype html>
<title>Hello</title>
<script>
  console.log("Hello from the browser");
  console.log(2 + 3);
</script>
```

With a browser on your desktop you could open this file and look at the **console**, the panel the
browser's developer tools keep for messages from scripts. A terminal transcript cannot show a
window, so this course uses the `page` command from the previous section. It serves `~/js` at
`http://127.0.0.1:8080`, opens the page in a real Chromium, and prints what the console said:

```
ana@dev:~/js$ page hello.html
Hello from the browser
5
```

Same two lines, same answers. **What `page` prints is the browser's console, one message per
line**, and lesson 22 opens the real panel and the rest of the developer tools.

## The same file, two hosts

A script can ask what it is running in. `typeof` answers with the kind of a value, and a name that
does not exist answers `"undefined"` rather than failing:

```javascript
console.log(typeof process, typeof document);
```

```html
<!doctype html>
<script src="where.js"></script>
```

```
ana@dev:~/js$ node where.js
object undefined
ana@dev:~/js$ page where.html
undefined object
```

**Node has `process` and no `document`; the browser has the opposite.** Everything else in this
lesson works in both, and from here on a program runs in whichever host makes the point clearer.
