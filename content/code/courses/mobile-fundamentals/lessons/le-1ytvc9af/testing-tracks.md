---
title: Testing tracks, before the public sees anything
version: 1
---

**A testing track is a store's way of giving a build to some people and not to everybody, through the
store itself.** The common picture of a beta is a file passed around by email. On Android that still
works for a friend's phone, as lesson 1 said; on an iPhone it does not, because an iPhone installs
only what Apple signed. Both stores therefore offer tracks, and the useful thing about a track is
that the tester installs and updates the app the way a real user will, from the store, with the same
signing and the same update path.

## Google Play: internal, closed, open

Android's documentation on testing an app bundle describes three stages a release can pass through
"before pushing to production":

| track | who gets it | what it is for |
|---|---|---|
| **internal test** | a small list of people you name | "internal testing and quality assurance checks", quickly |
| **closed test** | "a larger set of testers", by invitation | pre-release versions, after the team is happy; Play creates one called Alpha to start with |
| **open test** | anyone who joins | "a wider range of users", before production |

**The order is the point.** Each track widens the audience only after the narrower one found nothing
serious, and the pre-launch report from the previous section runs on the closed and open tracks, so a
crash on a phone model nobody on the team owns turns up before the public's first install. The same
page also describes **quick sharing**: a URL for one test build, where "version codes don't need to
be unique". That exception is useful here, because everywhere else the version code is the number the
store will not let you reuse, as the next section shows.

## Apple: TestFlight

**TestFlight is Apple's testing track, with two kinds of tester.** Apple's TestFlight page, read on
30 October 2026, gives the numbers:

| | how many | who | review |
|---|---|---|---|
| **internal testers** | "up to 100 members of your development team" | people with a role in the team's App Store Connect account | the page names no review step |
| **external testers** | "up to 10,000" | anyone with an email address or a public link | the first build must be "approved by App Review" |

**External testing is reviewed, and that surprises people.** Apple's guideline 2.2 adds that "significant
updates to your beta build should be submitted to TestFlight App Review before being distributed to
your testers", and that a TestFlight build should be meant for public release and follow the same
guidelines. So the rejections of the previous section can reach a beta too, which is one more reason
to run the checklist before the first external build rather than before launch.

## The planner's way through

For a planner built after the fork, a sensible order on each store is the same three steps:

1. **The team first.** Internal testing on Play and internal testers on TestFlight: the people who
   wrote it, on their own phones, within minutes of the upload.
2. **A group who are not the team.** A closed track or a TestFlight group of a few dozen students who
   agreed to try it, for long enough to use it for a real week of study, which is the only way the
   week's total gets tested on data nobody invented.
3. **Anyone who wants it.** An open track, or a TestFlight public link, for the last round before
   production.

**A tester's feedback is only as useful as the build number on it.** "The total is wrong" from a
tester means nothing until you know which build they ran, and the store tells you, because every build
carries its own number. That number, and the rule that it must always grow, is the next section.

**`mobile-delivery` lesson 7 is the practice** of this section: setting up each track, inviting
testers, and moving a build from one stage to the next.
