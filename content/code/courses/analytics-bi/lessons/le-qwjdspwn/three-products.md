---
title: Three products, two histories
version: 1
---

Lesson 7 built the job by hand. This lesson is about the products that sell it, and the first thing to
know about them is that they did not start in the same place.

**Hightouch and Census began as reverse ETL.** Each read a model from the warehouse and wrote it into
operational tools: the arrow of lesson 7, with a catalogue of destinations behind it. Census was bought
by Fivetran in 2025 and is now sold as **Fivetran Activations**; its documentation lives under
Fivetran's, and you will find both names for a while. Hightouch is still independent, and today calls
what it sells a *composable CDP*, which this lesson explains.

**Segment began at the other end.** It was a way to collect events — a visit, a product view, a
purchase — from a website or an app once, and forward them to every tool that wanted them, instead of
installing each tool's own snippet. Twilio bought it in 2020, and its documentation is now on Twilio's
site. Segment added Reverse ETL later, so today it does both: collects events on the way in, and sends
warehouse models on the way out.

| | started as | the arrow it draws |
|---|---|---|
| Hightouch | reverse ETL | warehouse → tools |
| Census (Fivetran Activations) | reverse ETL | warehouse → tools |
| Segment (Twilio) | event collection | app → warehouse and tools, and since then warehouse → tools |

None of the three runs on your machine, and each needs an account, a warehouse it can reach over the
internet and a destination with an API key. **Nothing in this lesson about their screens was run
here**: what it says about them comes from their own documentation, read in 2026, and names the
documented term so you can find it. What was run is the SQL, against the same `lantern` database as
every other lesson.

The point of putting them beside lesson 7 is not to choose one. It is that each of the decisions you
made by hand is a setting in their screens, and **a setting you have never had to decide is one you
cannot judge**.
