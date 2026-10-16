---
title: The compatibility matrix
version: 1
---

**A compatibility matrix is the list of device configurations an app promises to work on, and the
subset of them you actually test.** Its rows are combinations: an Android version, a screen size, a
manufacturer, a language, and anything else that changes how the app behaves. Lesson 19 said why the
combinations matter: a maker's background rules or a small screen each hide their own defects. This
lesson is about which ones to test, because there are far too many to test them all.

The usual first answer is to take a list of the best-selling phones in the world, or the top ten
from a market report, and test those. **The phones that matter are your users' phones**, and they
are not the world's. An app for a theatre in São Paulo is opened mostly on the mid-range and budget
Android phones sold in Brazil, by people who keep a phone for years. A list of flagships from
another market tests almost none of them.

## The dimensions

| dimension | why it matters | where its values come from |
|---|---|---|
| **Android version** | permissions, background limits and APIs change from one version to the next (lessons 14 and 21) | your analytics; the oldest end is fixed by the app's minimum SDK, 26 for Tickets |
| **screen size and density** | layouts break on the smallest and the largest screens, not on the one the designer used | your analytics, grouped into a few classes: small phone, large phone, tablet |
| **manufacturer** | each maker's version of Android has its own launcher, settings and background rules (lesson 19) | your analytics |
| **language and region** | text grows in translation, dates and money are written differently | the languages the app ships in, and the regions it sells to |
| **anything the app depends on** | Google Play services, a camera, a fingerprint reader | what the app's own features need |

Each dimension multiplies the others. **Four Android versions, three screen sizes, three makers and
two languages are already 72 combinations**, and section 04's script counts them. Add a fifth
version or a fourth maker and the number grows by a quarter or a third at once. Nobody runs a suite
on 72 configurations before every release, and nobody should. Most of those rows test the same
thing as their neighbours.

## Three ways to cut it down

The rest of this lesson uses all three, in this order:

1. Coverage keeps the values that most of your users have, until they add up to a share you
   choose. The rare ones are left for a lighter check. Section 03.
2. Pairwise picks combinations among the values you kept, so that every pair of values is tested
   together at least once. That is a small fraction of the full product. Section 04.
3. Renting runs the combinations you cannot own on real phones in a device cloud. Sections 05
   and 06.

When the app is new and has no users yet, start from public figures for the country it is sold in,
and replace them with your own as soon as the first month of analytics arrives.
