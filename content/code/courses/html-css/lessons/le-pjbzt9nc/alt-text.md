---
title: Text instead of a picture
version: 1
---

Every `<img>` needs an **`alt` attribute**, and the question it answers is not "what is in the picture?" but **"what would I write here if I could not use a picture?"**. Its text replaces the image for anybody who cannot see it: a screen reader user, a reader whose connection did not load the file, a search engine. Here are the three cases every image falls into:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>This week's find · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>This week's find</h1>
      <img src="cover.png" width="200" height="300"
           alt="First edition of Grande Sertão: Veredas, green cloth cover, spine faded">
      <img src="divider.png" width="400" height="8" alt="">
      <img src="cover.png" width="200" height="300">
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe alt.html tree axe
- main:
  - heading "This week's find" [level=1]
  - 'img "First edition of Grande Sertão: Veredas, green cloth cover, spine faded"'
  - img
image-alt (critical, 1 element): Images must have alternative text
```

**The first picture carries information**, so its `alt` says what a reader needs to know from it: which book, which edition, what condition. The tree lists it as an **img** named by that text.

**The second is decoration**, a divider line, and its `alt` is empty: `alt=""`. That is not a missing alt; it is a statement that the image says nothing. The browser leaves it out of the tree entirely, so a screen reader skips it, which is exactly right: hearing *image, divider* between every section is noise.

**The third has no `alt` at all**, and it is the worst of the three. The tree shows a bare **img**, and many screen readers then fall back to reading the file name, *cover dot png*, which is how people end up hearing `IMG_4031.jpg` read aloud. axe reported it as **image-alt**, critical.

## How to write good alt text

- **Say what the image is for, in context.** The same photograph of the shop is *the front of Andorinha Books, Rua dos Pinheiros* on the contact page and could be decoration on the home page.
- **Do not start with "image of" or "picture of".** The screen reader already says *image*.
- **Keep it to a sentence.** If the picture needs more, a chart for example, the explanation belongs in the page's text, where everybody can read it.
- **Text in the image goes in the alt.** A picture of a poster that says *Book swap, Saturday 10 am* has that as its alt.
- **Inside a link, describe where the link goes**, as lesson 2 section 09 showed.

The decision between the first two cases is the one that matters: **if removing the picture would lose information, describe it; if it would lose nothing, `alt=""`.**
