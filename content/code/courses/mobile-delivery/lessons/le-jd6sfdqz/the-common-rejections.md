---
title: The common rejections, and the one that repeats
version: 1
---

**Most rejections are not about subtle rules; they are about a reviewer who could not do what the
listing promised.** Apple says that **over 40% of unresolved issues relate to guideline 2.1, App
Completeness**: crashes, placeholder content, incomplete information. That is the rejection that
repeats, release after release, in team after team, and it is almost always preventable.

## Apple's usual reasons

| guideline | what it means in practice |
|---|---|
| **2.1 App Completeness** | the app crashed, a link was dead, the reviewer could not sign in, or the server was off |
| **2.3 Accurate Metadata** | screenshots that show a splash screen or a login page, a description that promises a feature the build lacks, prices in the name |
| **4.2 Minimum Functionality** | a website wrapped in an app, with nothing an app adds |
| **5.1.1 Data Collection and Storage** | a vague purpose string, a login demanded for no reason, no way to delete the account (lesson 5) |
| **3.1.1 In-App Purchase** | digital content sold in the app through anything but Apple's purchase system |

The first row deserves its own sentence from the guidelines: *include demo account info (and turn
on your back-end service!) if your app includes a login.* **The reviewer cannot sign up with a
real phone number, cannot receive your SMS code, and does not know your staging server is off on
Sundays.** If the planner needs an account, the review notes carry a working demo account whose
data shows every screen with something in it.

## Google's usual reasons

Google's rejections are policy-shaped rather than guideline-numbered: **permissions** the app's
features do not justify (lesson 5), **Data safety answers** that do not match what the app is seen
to send, **deceptive behaviour** such as a listing for features the app lacks, and **broken
functionality** found by its automated testing. A rejection names the policy, and the Play Console
shows the version and the reason.

## The one that repeats

A rejection that comes back on the next release is never bad luck. It is a step done by memory: the
demo account whose password somebody changed, the screenshot nobody regenerated, the privacy answer
nobody revisited after a new library. **Whatever was rejected once becomes a line in a check that
runs before every submission**, which is the next section.

## The other two platforms

React Native apps are reviewed exactly like native ones, and one guideline concerns them more:
**2.5.2** says an app may not *download, install, or execute code which introduces or changes
features or functionality*. Over-the-air updates of the JavaScript bundle, such as Expo's, are
therefore kept by careful teams to fixes that leave the reviewed features as they were; a new
feature goes through review in a new build. Lesson 19 comes back to it.
