---
title: Video and audio
---

The native elements need no library for the common case:

```html
<video controls preload="metadata" poster="cover.jpg" width="640">
  <source src="lesson.webm" type="video/webm" />
  <source src="lesson.mp4" type="video/mp4" />
  <track kind="captions" src="lesson.vtt" srclang="en" label="English" default />
</video>
```

Several `<source>` elements let the browser take the format it can play. `preload="metadata"` downloads only enough to know the duration — `auto` would download the whole video for someone who may never watch it.

The caption track is not optional in practice: it serves whoever cannot hear, whoever is somewhere noisy and whoever would rather read. And unlike the rest, it cannot be added later without producing the content again.
