---
title: The stores, and what they review
version: 1
---

**A store is a distributor with rules, and the rules are the part that changes.** Everything in this section
is current as this course was written and comes from the stores' own pages; each store changes its fees, its
forms and its policies on its own schedule, so read the store's page on the day you publish. *No account was
opened and nothing was uploaded for this course: both need a person to accept the terms and, for Apple, a
paid membership.*

## Google Play

An account on the **Play Console** costs a one-time registration fee that Google sets, and asks for your
identity to be verified. Then, for each app:

- **a store listing**: the name, a short and a full description, the icon at 512 pixels, screenshots of
  phones and tablets, and a feature graphic;
- **the forms**: content rating, the target audience, whether there are ads, and the **Data safety** form,
  which says what data the app collects and why. The planner sends nothing off the phone, the location it
  reads included, and the form says exactly that;
- **a privacy policy**, at a public address, even for an app that collects nothing;
- **a test before production**: new personal accounts are asked to run a closed test, with a number of testers
  over a period Google sets, before the app may go to everybody.

Then the AAB of lesson 13 goes to a track, internal, closed, open or production, and a review, usually a matter
of days, comes before the first release of each track.

## The App Store

The **Apple Developer Program** is a yearly membership, at a price Apple sets. Each app gets a record in **App
Store Connect** with its listing, screenshots for the screen sizes Apple asks for, a privacy policy address,
and the **privacy details**, Apple's form for what the app collects. Builds arrive from Xcode, go to TestFlight
first, and are then sent for **App Review**, against Apple's published App Review Guidelines.

## The review that wrapped apps fail

**One guideline matters to this course more than any other.** Apple's guideline on minimum functionality says
an app should be more than a repackaged website, and a wrapped web app that is only its site in a WebView is
the textbook case of a rejection under it. Google's policies have a similar idea of apps that offer little more
than a website.

What a reviewer looks for is what makes an app an app: it works offline, it uses the device, it feels at home on
the platform. **The planner passes on the parts lessons 4 to 6 built**: its data is stored on the phone and works
with no network, it sends local notifications, it uses the camera, and its screens were measured on a phone's
budget. A Capacitor app whose only content is a remote `server.url`, the thing lesson 13's checklist refuses, is
the one that fails. A React Native app, whose screens are native views, starts out on the right side of this
guideline; it is the wrapper that has to earn it.
