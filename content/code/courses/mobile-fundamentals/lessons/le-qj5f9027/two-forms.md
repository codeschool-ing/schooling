---
title: The two forms, and what "collect" means in them
version: 1
---

**Both stores make every app answer, in a form, what data it collects and what it does with it, and
both show the answers to the person on the app's page before they install.** Google Play calls this
the *Data safety* section, filled in on the App content page of the Play Console. Apple calls it the
app's *privacy details*, filled in through App Store Connect, and describes the result on its own site
as *Privacy Nutrition Labels*: a short panel on the product page, like the label on a food packet.
Neither form is optional. Apple's page on app privacy details says the information "is required to
submit new apps and app updates to the App Store".

What follows was read from each company's documentation on 30 October 2026: Android's developer guide
to the Data safety form, and Apple's page on app privacy details. Both say they change, and both
forms have changed since they were introduced, so read the current pages before you fill either in.
The detailed definitions for Play live in the Play Console Help Center, which could not be reached
from the machine this course was recorded on; the summary below is from Android's developer guide.

## The questions are the same questions

**Strip the vocabulary and both forms ask three things about each kind of data.** Does the data
leave the device? Does it go to anybody other than you? What is it used for? Apple adds a fourth:
whether the data is linked to the person's identity, through an account, the device or anything else.

| question | Apple's words | Google Play's words |
|---|---|---|
| does it leave the device? | *collect*: sent off the device and kept longer than the request needs | *collect* |
| does someone else get it? | *third-party partners*, and *tracking* | *share* |
| why? | a purpose from a fixed list | a purpose from a fixed list |

**"Collect" means the data leaves the phone, and that is the word most people get wrong.** Apple
defines it exactly: transmitting data off the device "in a way that allows you and/or your third-party
partners to access it for a period longer than what is necessary to service the transmitted request
in real time". So a plan that stays on the phone is not collected, however much of it there is, and a
single email address sent to your server and kept there is. The common belief runs the other way,
that "collected" means anything the app touches, and it leads to labels that frighten people for no
reason.

**The purposes are a short list, and "the app needs it to work" is one of them.** Apple's list is
App Functionality, Analytics, Product Personalization, Developer's Advertising or Marketing,
Third-Party Advertising, and Other Purposes, each with a definition. Its page adds that data collected
only for the app's own functioning "still needs to be declared": a purpose does not excuse a
collection, it describes it.

## The code you did not write counts

**Data collected by a library inside your app is your collection, on both forms.** Android's guide
says that if a third-party SDK or library in your app collects or shares user data, "you must reflect
this collection and sharing in the Data safety form". Apple asks for the practices "of third-party
partners whose code you integrate into your app", and defines those partners as "analytics tools,
advertising networks, third-party SDKs, or other external vendors". A crash reporter, an analytics
kit or an advertising library you add in an afternoon changes what your form has to say, whether or
not you read its documentation.

**And the form is a promise someone checks.** Android's guide says the developer alone is
responsible for complete and accurate declarations, and that when Google becomes aware of a
discrepancy between an app's behaviour and its declaration, it "may take appropriate action, including
enforcement action". A form filled in once, from memory, and never updated as libraries are added is
the usual way an honest app ends up declaring something false.

## Tracking has a narrower meaning than it sounds

**Apple's *tracking* is a defined term: linking data from your app with data from other companies'
apps or websites for advertising, or passing it to a data broker.** Its page lists that, and only
that. Analytics about how people use your own app is not tracking in this sense, though it is still
collection and still declared. When an app does track, iOS requires it to ask first, through the App
Tracking Transparency framework, which the next section shows. The planner does not track, and nothing
in this course asks you to.
