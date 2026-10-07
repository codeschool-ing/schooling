---
title: The build writes only the classes you use
version: 2
---

Tailwind knows thousands of classes, and the stylesheet it wrote is small. It **scanned the files** in the folder for anything that looks like one of its class names, and wrote a rule only for those it found:

```
ana@laptop:~/site$ grep -A2 "\.p-4 {" first/out.css
  .p-4 {
    padding: calc(var(--spacing) * 4);
  }
ana@laptop:~/site$ grep -c "p-5" first/out.css
0
ana@laptop:~/site$ probe first/index.html style "#content" padding-top,max-width style "#title" font-size,font-weight style "#poetry" border-left-color
main#content  padding-top: 16px
main#content  max-width: 768px
h1#title  font-size: 24px
h1#title  font-weight: 700
article#poetry  border-left-color: oklch(0.508 0.118 165.612)
```

`p-4` is in the page, so there is a rule for it: `padding: calc(var(--spacing) * 4)`. `p-5` is not, and the stylesheet does not mention it at all: **0**. The page then renders as any page does, and the `probe` reads it as it has for twelve lessons. The padding is **16px**, the main column's `max-width` is **768px**, the heading is **24px** and bold, and the card's border is green.

The colour is printed as **`oklch(0.508 0.118 165.612)`**. Tailwind's palette is written in **OKLCH**, a way of writing colours by lightness, chroma and hue, chosen so that equal steps of lightness look equal to the eye. Browsers have supported it since 2023. For a colour you choose yourself, a hex value still works, as section 07 shows.

## Building for production

The scanning is what keeps the file small, and the size still matters, lesson 1 section 12. For production, **`--minify`** removes the spaces and comments:

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd first -i input.css -o out.min.css --minify --silent
ana@laptop:~/site$ wc -c first/out.css first/out.min.css
 6749 first/out.css
 5868 first/out.min.css
12617 total
```

**6749** bytes as written, **5868** minified, for a page with a dozen classes. A whole site's stylesheet typically stays at a few tens of kilobytes, because however big the site is, it uses one scale. `front-delivery` is where this build becomes part of how a site is deployed.
