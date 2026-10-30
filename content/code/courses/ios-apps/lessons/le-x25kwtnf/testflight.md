---
title: TestFlight, the beta before the store
version: 1
---

**TestFlight is how a build reaches people before it reaches the store.** Testers install Apple's free
TestFlight app, accept an invitation by email or through a public link, and install your build; they
send feedback and screenshots from inside it, and you see sessions and crashes in App Store Connect.
Nothing here was run; the numbers are from Apple's *TestFlight overview* in App Store Connect help,
read on 30 October 2026.

## Two kinds of tester

| | internal | external |
|---|---|---|
| who | "up to 100 App Store Connect users with access to your content" | "up to 10,000 people", by email or public link |
| needs a review first | no | the first build added to a group "gets sent to App Review" |
| for | the team, every build, the same day | real users, before release |

**The first external build is reviewed, and later ones may not be.** The overview says that "a review
is required only for the first build" and that "subsequent builds may not require a full review".
That first review is a dress rehearsal for section 06's: a planner that crashes on launch, or a
sign-in nobody can pass, fails here as it would there.

## What the overview asks you to provide

- **Test information**: a description of the beta, what to test and an email for feedback. It is
  what external testers read, and what the reviewer reads too.
- **Export compliance**: whether the app uses encryption beyond what iOS provides. The planner talks
  to its server over HTTPS through `URLSession`, lesson 12, which Apple's documentation on export
  compliance treats separately from encryption an app implements itself; answer the question from
  that page, not from memory.
- **A build that is new enough** for section 02's minimums.

## How long a build lasts

"You can test a build for up to 90 days", the overview says, and then "your build becomes unavailable
for testers after 90 days". **A tester who opens an expired build gets nothing**, so a beta that runs
for a semester needs a new build at least every three months. Expire a build yourself when it is
replaced, or testers keep using it even after the release, as the overview also warns.

`mobile-delivery` lesson 7 compares TestFlight with Google Play's internal, closed and open testing
tracks; the shape is the same, and the review step is Apple's own.
