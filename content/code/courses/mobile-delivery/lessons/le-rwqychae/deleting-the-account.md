---
title: Deleting the account, from inside the app
version: 1
---

**An app that lets people create an account must let them delete it, and both stores now check.**
Apple's guideline 5.1.1(v) says it in a sentence: *if your app supports account creation, you must
also offer account deletion within the app.* Google Play asks the same in the Data safety form, and
also asks for a **web address** where somebody can request deletion without installing the app,
for the person who already uninstalled it.

## What "delete" has to mean

- **Inside the app, findable.** A settings screen, a few taps from the start; not an e-mail
  address in the small print, and not "contact support".
- **The account and its data, not a deactivation.** Hiding an account while keeping everything is
  not deletion. What the law requires you to keep, an invoice for instance, is kept, and the person
  is told what and for how long.
- **Said plainly before it happens, and done after.** One confirmation, a sentence saying what goes,
  and then it goes. If deletion takes days on the server, the person is told that.

## For the planner

The planner's account holds an e-mail and the sessions synced to the server. Deleting it removes
both from the server and signs the phone out. The sessions on the phone itself are the person's to
keep or clear; the app asks which. And the inventory of section "The inventory" answers Google's
question with `"deletionOnRequest": true` only once the web page exists.

## The other two platforms

This is the server's job, not the platform's: one endpoint deletes the account, and each client,
Kotlin, Swift or React Native, has a screen that calls it. The rule is the same in both stores, so
the work is done once.
