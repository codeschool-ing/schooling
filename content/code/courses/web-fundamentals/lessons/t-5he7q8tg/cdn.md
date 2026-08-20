---
title: CDN: bringing the content closer to whoever asks
---

A **CDN** is a network of servers spread around the world holding copies of your content. Somebody visiting from Lisbon is served by the Lisbon node, not by your server in São Paulo.

It attacks exactly the problem bandwidth cannot solve, three lessons back: **latency is distance**, and the only way to reduce it is to shorten the path. For static files — images, CSS, JavaScript, video — the gain is large and the configuration is small.

A CDN does not replace hosting: it sits in front of it. Your server still exists and still answers for what is dynamic and for what the CDN does not have cached yet — that is what is called the **origin**.

The side effect that bites: because the CDN holds copies, publishing a new version does not always show up straight away. Either you invalidate the cache on deploy, or you use a fingerprinted file name — the same solution as the cache lesson, now at world scale.
