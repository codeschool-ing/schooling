---
title: Text instead of a picture
version: 2
---

Every `<img>` needs an **`alt` attribute**, and the question it answers is not "what is in the picture?" but **"what would I write here if I could not use a picture?"**. Its text replaces the image for anybody who cannot see it: a screen reader user, a reader whose connection did not load the file, a search engine. Every image falls into one of three cases, and one page below shows all three.

The pictures in this lesson are not photographs. They are flat green with their size written on them, so that when a page could choose between several files you can see which one it chose. One page makes all of them, and the video in section 11 as well. Save it as `pictures.html` in `site` and open it:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Pictures for lesson 4</title>
  </head>
  <body>
    <h1>Pictures for lesson 4</h1>
    <p>Save each file into your site folder: click it, or right-click and choose to save the link.</p>
    <ul id="files"></ul>
    <script>
      function offer(blob, name) {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = name;
        link.textContent = name;
        const item = document.createElement('li');
        item.append(link);
        document.getElementById('files').append(item);
      }
      // Flat green with the size written on it, so you can see which file a page chose.
      function draw(width, height) {
        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const pen = canvas.getContext('2d');
        pen.fillStyle = '#2f6f4e';
        pen.fillRect(0, 0, width, height);
        if (height >= 40) {
          pen.fillStyle = 'white';
          pen.font = Math.round(height / 8) + 'px sans-serif';
          pen.textAlign = 'center';
          pen.textBaseline = 'middle';
          pen.fillText(width + '×' + height, width / 2, height / 2);
        }
        return canvas;
      }
      function picture(width, height, name, type = 'image/png', quality) {
        draw(width, height).toBlob(blob => offer(blob, name), type, quality);
      }
      picture(200, 300, 'cover.png');
      picture(400, 8, 'divider.png');
      picture(480, 320, 'shelves-480.png');
      picture(960, 640, 'shelves-960.png');
      picture(1600, 1067, 'shelves-1600.png');
      picture(600, 600, 'shelves-crop-600.png');
      picture(960, 640, 'shelves-960.webp', 'image/webp', 0.8);
      // Two seconds of video: the same green, recorded from a canvas.
      const screen = draw(320, 180);
      const recorder = new MediaRecorder(screen.captureStream(25), { mimeType: 'video/webm' });
      const chunks = [];
      recorder.ondataavailable = event => chunks.push(event.data);
      recorder.onstop = () => offer(new Blob(chunks, { type: 'video/webm' }), 'reading.webm');
      const tick = setInterval(() => screen.getContext('2d').fillRect(0, 0, 1, 1), 40);
      recorder.start();
      setTimeout(() => { recorder.stop(); clearInterval(tick); }, 2000);
    </script>
  </body>
</html>
```

It lists eight files. Click each one: your browser saves it in its downloads folder, and from there it goes into `site`. The page uses a little JavaScript, a canvas to draw on and a recorder for the video. The `javascript` course is where that is taught; here it only has to run. With the pictures in place, this is the page with the three cases, `alt.html`:

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
