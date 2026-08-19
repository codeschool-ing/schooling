---
title: Video and audio
---

The native elements need no library for the common case:

[object Object]

Several `<source>` elements let the browser take the format it can play. `preload="metadata"` downloads only enough to know the duration — `auto` would download the whole video for someone who may never watch it.

The caption track is not optional in practice: it serves whoever cannot hear, whoever is somewhere noisy and whoever would rather read. And unlike the rest, it cannot be added later without producing the content again.
