---
title: Online-first and offline-first
version: 1
---

**An app built online-first asks the server for every screen and treats the device as a window.
An app built offline-first reads every screen from its own database and treats the server as
somebody to agree with later.** The two look the same on a good connection. They come apart the
moment the connection does.

The common picture is that offline support is a feature you add: a cache in front of the requests,
switched on when the network fails. It is not a feature. It decides **where the truth lives while
the person is using the app**, and that decision changes the path every write takes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l07-two-ways\" aria-label=\"Two rows. Online-first: the screen asks the server through the network for every read and every write, and when the network is gone the screen has nothing to draw. Offline-first: the screen reads and writes the database on the device, and a separate sync step carries changes to the server later, when there is a network.\"><defs><marker id=\"l07-two-ways-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">online-first</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the screen</text><rect x=\"550\" y=\"40\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the server</text><path d=\"M170 62 L550 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l07-two-ways-ah-paper-dim)\" marker-start=\"url(#l07-two-ways-ah-paper-dim)\"></path><text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">every read and write</text><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">no network: nothing to draw</text><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">offline-first</text><rect x=\"20\" y=\"144\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the screen</text><rect x=\"270\" y=\"144\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"345.0\" y=\"159.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the database</text><text x=\"345.0\" y=\"172.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">on the device</text><rect x=\"550\" y=\"144\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the server</text><path d=\"M170 166 L270 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-two-ways-ah-paper-dim)\" marker-start=\"url(#l07-two-ways-ah-paper-dim)\"></path><text x=\"220\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">reads and writes, at once</text><path d=\"M420 166 L550 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l07-two-ways-ah-paper-dim)\" marker-start=\"url(#l07-two-ways-ah-paper-dim)\"></path><text x=\"485\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">sync, later</text></svg>", "caption": "Online-first puts the server between the person and every screen. Offline-first puts the device's database there, and sends to the server as a separate step."}
```

## Online-first

The screen asks the server, waits, and draws what came back. A new session is a `POST`; the list
shows it once the server has said yes. On a train, the button spins until it times out, and the
person learns that the planner does not work underground. Nothing is lost, because nothing was
ever kept.

## Offline-first

The screen reads the database on the device. A new session is a row written there, and the list
shows it at once, because the list was drawn from that database to begin with. **Sending it to the
server is a separate step that happens afterwards**, when there is a network, and the row carries
a mark saying whether that step has happened yet.

What offline-first costs is everything this course from lesson 8 to lesson 15 is about. The device
and the server each hold a copy, so somebody has to carry changes from one to the other (an
outbox, lesson 8), survive the network failing halfway (lessons 9 and 10), learn what changed on
the other side (lessons 11 and 12), and decide what happens when both sides changed the same thing
(lessons 13 to 15).

## Which one a planner wants

The question is who is hurt by waiting. A banking balance must be the bank's number, and showing a
number the server has not confirmed would be a lie. A study planner is the opposite: the session
the person typed is theirs, and nothing the server knows makes it more true. **Writing it locally
first loses nothing and removes every spinner from the screen.** That is the planner this lesson
builds.

Most apps are a mix, and the split is per screen rather than per app. The planner's list of courses
on sale can be online-first, since a price is the server's to say; the sessions are offline-first.
