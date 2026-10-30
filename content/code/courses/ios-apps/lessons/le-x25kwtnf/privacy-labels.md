---
title: The privacy label, the manifest's public face
version: 1
---

**Every app's page on the store shows what data it collects and whether that data is linked to the
person or used to track them, and the developer fills it in.** Apple calls it *App Privacy* in App
Store Connect; people call it the privacy nutrition label. It is a declaration, and an untrue one is
grounds for removal. Nothing here was run; it is written from Apple's page *App privacy details on
the App Store*, read on 30 October 2026.

## What "collect" means

The page defines it precisely, and the definition decides most answers: "'Collect' refers to
transmitting data off the device in a way that allows you and/or your third-party partners to access
it for a period longer than what is necessary to service the transmitted request in real time." Data
that stays on the phone is not collected. Data sent to a server and discarded once the request is
answered is not collected either.

## The planner's answers

The planner keeps its plan on the phone, and from lesson 12 it syncs the plan to its own server,
which stores it. **So it collects one kind of data**, and the label says so:

| question | the planner's answer | why |
|---|---|---|
| data collected | the study plan: courses and sessions | it is stored on the server, which is collecting |
| linked to the person | yes | it is stored under their account, and the page treats account data as linked |
| used to track | no | nothing is shared with advertisers or data brokers, lesson 18 section 05 |
| camera photos | not collected | the photo of notes stays on the phone in this course's design |

The category for the plan is a judgement the page leaves to the developer; "Other User Content" is the
one it describes for content a person makes in the app. **Write down why you chose each answer**: the
label is re-read whenever the app changes what it sends, and the person reading it next is you.

## Two files, one story

Lesson 18's **privacy manifest** is inside the app, read by Xcode and App Store Connect, and covers
what the code and its SDKs do. The **label** is on the store, read by people, and covers what the
app collects. They describe the same app from two sides, and they have to agree. An SDK whose
manifest says it collects device identifiers, under a label that says nothing is collected, is the
mismatch App Review looks for.
