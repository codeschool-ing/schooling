---
title: Three gates between your code and the screen
version: 1
---

**A notification is a request, not an order.** Your code builds one and hands it to the system, and
the system decides whether anybody sees it. Most of the confusion about notifications comes from
treating `notify` as a function that shows something: it returns nothing, throws nothing, and on a
phone that has said no it does nothing at all, silently.

The planner wants one kind of notification: on a day with a session planned, a short line saying
which course and how many minutes, and a tap that opens that course. Lesson 18's worker is a
natural place to call it from, once a day. This lesson builds the notification and the checks
around it, and lesson 20 asks the student for the permission it needs.

## The gates

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l19-gates\" aria-label=\"A flow from left to right. showReminder is called. First question: on Android 13 or later, is POST_NOTIFICATIONS granted? If not, nothing is shown. Second: are the app's notifications turned on in settings? If not, nothing is shown. Third: the channel the notification names, and its importance, which the student can change: high shows it over the screen, default shows it in the shade with a sound, low without a sound, and none blocks it.\"><defs><marker id=\"l19-gates-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-gates-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"16\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"76\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">showReminder()</text><rect x=\"166\" y=\"34\" width=\"150\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"241\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Android 13+:</text><text x=\"241\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">permission granted?</text><rect x=\"346\" y=\"34\" width=\"150\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"421\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">notifications</text><text x=\"421\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">on in settings?</text><rect x=\"526\" y=\"34\" width=\"178\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the channel's</text><text x=\"615\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">importance</text><path d=\"M136 60 L164 60\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-gates-ah-wire)\"></path><path d=\"M316 60 L344 60\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-gates-ah-wire)\"></path><path d=\"M496 60 L524 60\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-gates-ah-wire)\"></path><rect x=\"166\" y=\"170\" width=\"330\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"331\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">nothing is shown, and no error</text><path d=\"M241 86 L241 168\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-gates-ah-amber)\"></path><path d=\"M421 86 L421 168\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-gates-ah-amber)\"></path><text x=\"250\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no</text><text x=\"430\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no</text><text x=\"540\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">high: over the screen</text><text x=\"540\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">default: shade, with sound</text><text x=\"540\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low: shade, silent</text><text x=\"540\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">none: blocked</text><path d=\"M532 100 L532 196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"615\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the student can lower it</text></svg>", "caption": "Three gates stand between notify and the screen, and the last one belongs to the student: an app picks a channel's first importance, and only the student can change it after that."}
```

Read the figure left to right, because the order is the order Android applies:

1. **On Android 13 and later, the app must hold `POST_NOTIFICATIONS`.** It is a runtime permission:
   declared in the manifest and then granted by the student in a dialog. Before Android 13 there was
   no such permission and every app could post. Section 05 handles both.
2. **The student can turn off all of an app's notifications** in its settings, whatever it was
   granted. `areNotificationsEnabled()` is how the app finds out.
3. **Every notification belongs to a channel**, and the channel's importance decides how loudly it
   arrives, from appearing over whatever is on screen down to not appearing at all. The app sets a
   channel's first importance; after that, it is the student's.

**The first two gates fail without telling anybody.** No exception, no log line in your app, no
return value from `notify`. That is why this lesson's `showReminder` checks both itself and answers
`true` or `false`: the caller then knows whether the student was reached, and can show the
reminder inside the app instead.

## What this lesson can show, and what it cannot

The notification shade, the heads-up banner and the system's permission dialog are drawn by the
phone's system interface, not by your app, so neither Robolectric nor Roborazzi can photograph them.
What a test can do is ask the system what it was given: Robolectric keeps every notification the
app posted, with its title, its text, its channel and the intent its tap would fire. Sections 03 to
06 read those. Section 07 describes what only a phone shows, marked **not run**.

**A notification sent from a server is a different mechanism**: a push message arrives through
Firebase Cloud Messaging and the app turns it into a notification like this one.
`mobile-fundamentals` lesson 17 explains how pushes arrive and why they are not a channel to abuse;
it needs a Firebase project and a device, and is not built here.
