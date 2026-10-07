---
title: Video and audio
version: 2
---

`<video>` and `<audio>` put a recording in the page, played by the browser itself, with no plug-in. The bookshop has a recording of last month's poetry reading:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Last month's reading · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Last month's reading</h1>
      <figure>
        <video controls preload="none" width="320" height="180" poster="cover.png">
          <source src="reading.webm" type="video/webm">
          <track kind="captions" src="reading.vtt" srclang="en" label="English" default>
          <a href="reading.webm">Download the video</a>.
        </video>
        <figcaption>Hilda Hilst's poems, read by three of our customers.</figcaption>
      </figure>
    </main>
  </body>
</html>
```

What each part does:

- **`controls`** shows the browser's own play, pause, volume and full-screen buttons. Without it there are none, and a video with no controls is one that a keyboard user cannot stop.
- **`<source>`**, with a `type`, lists the files; the browser plays the first it can. Several sources in different formats work like `<picture>` in section 08.
- **`<track kind="captions">`** gives a file of captions in **WebVTT**, a text format with a time range and a line for each caption. `default` turns them on unless the reader turns them off.
- **`poster`** is the picture shown before the video plays.
- **The content inside `<video>`**, the download link, is shown only by a browser that cannot play video at all.
- **`preload`** says how much to fetch before somebody presses play.

The captions file, `reading.vtt`, is plain text, and this one has a single caption:

```
WEBVTT

00:00.000 --> 00:02.000
Good evening, and welcome to Andorinha Books.
```

## What `preload` changes

With `preload="none"`, and then with a copy saved as `video-metadata.html` that says `preload="metadata"` instead:

```
ana@laptop:~/site$ probe video.html fetched
cover.png
ana@laptop:~/site$ probe video-metadata.html fetched
cover.png
reading.webm
```

With `none`, the browser fetched the poster and nothing else: the reader's data plan is untouched until they press play. With `metadata`, it also requested the video file, to learn its duration and dimensions. On a page with one video near the top, `metadata` is the usual choice; on a page listing twenty recordings, `none` saves the reader twenty requests.

## Captions are not optional

**A video with speech needs captions**: they are how deaf and hard-of-hearing people follow it, how anybody follows it with the sound off on a bus, and WCAG requires them for prerecorded video. An audio recording needs a **transcript**, the whole text on the page or behind a link. Generating captions automatically is a start that needs correcting by a person, because a wrong word in a caption is a wrong word in what the reader was told.

**Do not autoplay sound.** A page that starts talking when it opens fights with the screen reader of anybody using one. Browsers block autoplay with sound anyway; `autoplay` together with `muted` is allowed and is how background videos work, and even those need a visible way to stop them.
