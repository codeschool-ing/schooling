---
title: When it is rejected anyway
version: 1
---

**A rejection is a message from a person, with a reason and usually a screenshot, and the fastest
way through it is to read it as a bug report.** *Read from Apple's App Review pages, October 2026,
and Google's Play Console Help as published in 2025; not run.*

## Reading it

On Apple's side, the rejection arrives in App Store Connect's **App Review** messages, naming the
guideline, describing what the reviewer saw and often attaching a screenshot or a short video. On
Google's side, the Play Console names the policy and the version, and an e-mail says the same.

Three questions, in order:

1. **Can you reproduce what they saw?** Sign in with the demo account, on a clean install, on the
   device type they name. Most 2.1 rejections reproduce in five minutes.
2. **Is the reason about the build or about the listing?** A listing problem, a screenshot or a
   sentence, is fixed without a new build; a crash is not.
3. **Did they misunderstand the app?** Sometimes they did: a feature behind a setting, a flow that
   needs a second device. Then the answer is an explanation, not a change.

## Answering

- **Fix and resubmit** when the reviewer was right. Say in the notes what changed. The review clock
  starts again.
- **Reply** when they misunderstood. On Apple's side, a reply in the same thread, with a short video
  of the feature working, settles most of these without a new build.
- **Appeal** when you believe a rule was applied wrongly. Apple's **App Review Board** hears
  appeals, one per rejected submission, and asks you to answer any request for information first.
  Google has an **appeal form** for policy decisions. An appeal is slower than a fix, and right only
  when the fix would remove something the app should have.

## What not to do

- **Resubmit the same build hoping for another reviewer.** It is the same build, and the second
  rejection is now on record.
- **Hide the feature during review.** A feature switched off for the reviewer and on for everybody
  else is the behaviour both stores remove apps for, and lesson 19's remote configuration makes it
  easy to do by accident.
- **Argue in the listing.** A rejection is answered in the review thread, not in the description.

## The other two platforms

The process is the store's, so it is the same for Kotlin, Swift and React Native. What differs is
how fast a fix ships: a listing fix is a form in either store, while a code fix in a React Native
app may tempt a team to send it over the air instead of resubmitting. Section "The common
rejections" says why that is a risk when the fix changes what the reviewer saw.
