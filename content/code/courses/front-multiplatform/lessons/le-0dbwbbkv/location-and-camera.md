---
title: Geolocation and the camera
version: 1
---

## Where am I?

`whereAmI()` makes one call, and **the permission question happens inside it** the first time. Here it
is twice: once with nobody to answer, and once with permission granted and a position given to the
browser, a point on Avenida Paulista in São Paulo:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click 'Where am I?' --wait 300 | tail -n 1
  - status: "where failed: User denied Geolocation"
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --grant geolocation --geo -23.561,-46.656 --click 'Where am I?' --wait 300 | tail -n 1
  - status: studying at -23.561, -46.656
```

**A refusal reaches your code as an error**, and the status line turned it into a sentence. That is
the case to design for: the planner works without a location, so a no costs one button and nothing
else. An app that cannot work at all without one has to say so before it asks.

Two details from the plugin's documentation matter on a phone. Android 12 and later let the person
grant only an **approximate** location, which arrives as `coarseLocation` granted and `location`
denied; an app that only needs the city should ask for that alone. And a position **while the app is
in the background** is a separate permission on both systems, granted far more reluctantly and
examined closely by both stores' reviewers.

## A photo of my notes

On a phone, `Camera.takePhoto` opens the system's camera, and the photo comes back to the app. On the
web it opens a file picker instead, because `webUseInput: true` asks for that; without it, the plugin
would look for a camera component from the separate `@ionic/pwa-elements` package. `--upload` answers
the picker with a small white PNG this run had ready:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Guitar --upload ~/notes.png --click 'Photo of my notes' --wait 500 | tail -n 2
  - button "Photo of my notes"
  - status: a photo, image/png, 151 bytes
```

**`webPath` is an address the page can load**, so the planner fetched it and reported what it got: a
PNG, at its size in bytes. On a phone, `webPath` points at a file the app may read, and `uri` at the
same file for the native side; the plugin's documentation explains when to pass one or the other to
Filesystem.

The camera is also where the two platforms disagree most about permission. On iOS, using the camera
and reading the photo library are separate questions with separate sentences in `Info.plist`, which
the next section adds. On Android, taking a photo hands the job to the camera app through an intent,
which needs no camera permission from the planner at all; the manifest entries the plugin's
documentation lists are for saving to the gallery on older Android versions.
