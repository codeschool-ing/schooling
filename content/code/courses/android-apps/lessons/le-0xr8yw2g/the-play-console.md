---
title: The Play Console, and what it costs before anything else
version: 1
---

**Publishing on Google Play needs a Google Play developer account, and creating one costs money.**
Google charges a one-time registration fee. Its amount, and the identity checks that come with a new account, are set out in the Play Console Help pages on `support.google.com`. **Those pages could not be reached from the computer this course was recorded on**, so this course does not quote a figure. Read the current amount there before you start; a student who never publishes on Google
Play never pays it, and the `direct` flavour of section 03 is a way to hand the planner to a few
people without an account at all.

Everything below is **not run**, for the same reason: no account was created. The target API rule is
quoted from Google's documentation on `developer.android.com`, read on 30 October 2026. The outline
of the console's steps after it is a description, not a transcript: the Help pages that document each
step are the ones that could not be reached, so check each step there when you do it.

## The target API rule, with its date

Google's page *Target API level requirements for Google Play apps* states that **starting 31 August
2026, new apps and app updates must target Android 16 (API level 36) or higher to be submitted to Google Play**. The page sets lower levels for Wear OS, Android Automotive OS, Android TV and Android XR apps.
It also states that existing apps must target Android 15, API 35, or higher to remain available to
new users on devices running a newer Android than the app targets. The planner targets 36, which is
why lesson 1 chose it. The rule moves every year, and the page is where its next date appears.

## From bundle to students

The path an upload takes, in outline, is worth knowing before you start:

1. **Create the app** in the Play Console: its name, default language, and whether it is free.
2. **Enrol in Play App Signing**, section 07, and register the upload key.
3. **Upload the bundle** of section 06 to a testing track: internal testing reaches a short list of
   testers you name, and closed and open testing reach more people.
4. **Fill in the store listing and the declarations**: the description and screenshots, a privacy
   policy, the content rating questionnaire, and the data safety form, which says what data the app
   collects and why. `mobile-fundamentals` lesson 13 is about what that form makes you declare.
5. **Promote a release to production**, which sends it to Google's review before it reaches the
   store.

The `versionCode` of section 02 must grow with every upload: the console refuses a bundle whose code
it has already seen, which is the one rule here a student meets on their second upload.

## What `mobile-delivery` takes further

The steps after the first upload, such as staged rollouts, release notes in several languages, the
App Store's equivalent and automating all of it, are the subject of `mobile-delivery`, a later course on this track that every student takes. This lesson stops at the first release.
