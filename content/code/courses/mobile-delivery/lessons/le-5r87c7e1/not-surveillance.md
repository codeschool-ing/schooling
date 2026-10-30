---
title: Measurement that is not surveillance
version: 1
---

**Measuring the product means counting what people do with it; surveillance means building a
picture of the person.** The line between them is not the technology, which is the same, but what is
kept, what it is tied to, and who else sees it. The planner's analytics sit on the right side of it
by decisions made in advance, and each one can be checked in the code of the last section.

## The decisions

- **No content.** The schema allows numbers and fixed choices. A course name, a note, the text of a
  search: none of it can be sent, and the schema refuses it, as the simulation showed.
- **No identity.** The installation's identifier is random and lives on the device. It is not the
  account's id, not the e-mail, not the advertising identifier. Lesson 5's label calls this *Data Not
  Linked to You*, and it stays true only while nothing joins the two.
- **No third party that would make it tracking.** Apple defines **tracking** as linking data from
  your app with data from other companies' apps or websites for advertising, or sharing it with a data
  broker. Since iOS 14.5, an app that tracks must ask through **App Tracking Transparency**, and most
  people say no. The planner does not track, so it never asks.
- **Short retention.** Event rows older than what the funnel and the retention of lesson 17 need are
  deleted. A year of individual rows answers no question a week of aggregates does not.
- **Aggregates for reading.** People look at counts and rates, never at one installation's timeline.
  A screen that shows "installation i042 did this, then this, then this" is the tool that turns
  measurement into watching, whatever its purpose.

## The law, briefly

In Brazil the **LGPD** applies to personal data, and a random installation identifier tied to
behaviour can be personal data under it. In the European Union, the **GDPR** and the rules on
storing identifiers on a device ask for consent for analytics in many cases. The safe design is the
one above, plus **asking**: an analytics switch in the planner's settings, off-by-default where the
law expects it, and the event queue emptied when it is switched off. *This is not legal advice; it is
the design that keeps a privacy officer's conversation short.*

## The same on three platforms

Every rule above is about what the app sends, so it is the same in Kotlin, Swift and React Native.
The place to enforce it is one function, `track`, that every screen calls and that holds the schema,
on whichever platform; the next section shows the products such a function wraps.
