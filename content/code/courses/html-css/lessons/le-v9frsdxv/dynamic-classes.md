---
title: A class the build cannot see
version: 1
---

The build finds class names by **reading the files as text**. It does not run JavaScript. So a class name built by joining strings does not exist as far as the build is concerned:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="out.css">
  </head>
  <body>
    <p id="status" class="text-red-700">Sold out</p>
    <script>
      const colour = "green";
      document.querySelector("#status").className = "text-" + colour + "-700";
    </script>
  </body>
</html>
```

The script changes the paragraph's class to `text-green-700`, assembled from `"text-"`, a variable and `"-700"`:

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd dynamic -i input.css -o out.css --silent
ana@laptop:~/site$ grep -c "text-red-700" dynamic/out.css
1
ana@laptop:~/site$ grep -c "text-green-700" dynamic/out.css
0
ana@laptop:~/site$ probe dynamic/index.html style "#status" color
p#status  color: rgb(0, 0, 0)
```

`text-red-700`, written whole in the HTML, has a rule: **1**. `text-green-700` has none: **0**. In the browser the script did its job, the class is on the element, and the colour is **black**, because no stylesheet says anything about that class. Nothing reported an error.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"The Tailwind build as a picture. On the left, an HTML file with class attributes: mt-4 p-4, text-2xl font-bold, border-emerald-700, and a script that assembles a class from text-, a variable and -700. The scanner reads the file as text. On the right, out.css has a rule for each class written whole, and none for the assembled one.\"><defs><marker id=\"ah13\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"220\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">index.html</text><text x=\"32\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">class=&quot;mt-4 p-4&quot;</text><text x=\"32\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">class=&quot;text-2xl font-bold&quot;</text><text x=\"32\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">class=&quot;border-emerald-700&quot;</text><text x=\"32\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&quot;text-&quot; + colour + &quot;-700&quot;</text><line x1=\"250\" y1=\"95\" x2=\"300\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13)\"></line><rect x=\"310\" y=\"66\" width=\"120\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">scanner</text><text x=\"370\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">reads text</text><line x1=\"440\" y1=\"95\" x2=\"490\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13)\"></line><rect x=\"500\" y=\"20\" width=\"200\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">out.css</text><text x=\"512\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.mt-4 { … }</text><text x=\"512\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.p-4 { … }</text><text x=\"512\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.text-2xl { … }</text><text x=\"512\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.font-bold { … }</text><text x=\"512\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.border-emerald-700 { … }</text><text x=\"20\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">The scanner looks for anything shaped like a class name and writes a rule for each one it knows.</text><text x=\"20\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A name assembled by a script is never written whole, so there is no rule for it.</text></svg>", "caption": "The build reads your files; it does not run them."}
```

**Write class names whole**, every one of them, somewhere the build reads. Instead of assembling one, choose between complete names:

```js
const colours = { available: "text-green-700", soldOut: "text-red-700" };
```

It is a common Tailwind bug, and it is invisible until somebody sees the wrong colour. When a class is on the element in the Elements panel and does nothing, check whether the stylesheet has a rule for it.
