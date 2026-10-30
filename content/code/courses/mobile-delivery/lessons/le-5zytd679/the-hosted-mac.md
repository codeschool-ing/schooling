---
title: The hosted Mac, and what it costs
version: 1
---

**An iOS build needs macOS, and macOS runs only on Apple hardware, so every pipeline that builds for
iOS rents a Mac or owns one.** That single fact shapes mobile CI more than anything else: Linux
minutes are cheap and plentiful, Mac minutes are neither, and a pipeline designed for the web wastes
the expensive ones. *This lesson's pipeline runs on GitHub Actions and could not be run for the
course; its Linux steps are the commands run here, and its Mac steps are read from GitHub's and
Apple's documentation.*

## The choices

| where the Mac comes from | what it is | the price, as published |
|---|---|---|
| **GitHub Actions** macOS runners | a fresh virtual Mac per job, with Xcode installed | free minutes for public repositories; for private ones, a macOS minute is billed at a multiple of a Linux minute, ten times in GitHub's 2025 pricing |
| **Xcode Cloud** | Apple's own CI, configured in Xcode and App Store Connect | 25 compute hours a month included in the developer membership, Apple's page in October 2026 |
| **EAS Build** | Expo's hosted builders, for Expo and React Native projects | a free tier with a queue, paid plans for priority; it holds the credentials, lesson 2 |
| **your own Mac** as a self-hosted runner | a Mac mini under a desk, registered with the CI service | the hardware, its electricity, and somebody who updates Xcode on it |

*GitHub's billing page could not be reached from the recording machine; the multiplier is the
figure GitHub published in 2025.*

## Spending Mac minutes only where they are needed

- **Run everything that is not an iOS build on Linux.** Unit tests of shared logic, the listing check
  of lesson 4, the privacy check of lesson 5, lint, the Android build: none of them needs a Mac.
- **Build iOS only when it matters**: on the release branch, on a tag, or on a pull request that
  touches iOS code, not on every commit to every branch.
- **Cache what a Mac would download again.** The next section.
- **Set a time limit on the job.** A hung simulator on a hosted Mac bills until the job is killed,
  and the default limit on GitHub Actions is six hours.

## The three platforms

A **Kotlin** app needs no Mac at all, and its whole pipeline runs on Linux. A **Swift** app needs one
for every build. A **React Native** app needs one for its iOS half only; its JavaScript tests, its
Android build and every check before them run on Linux, and the iOS build runs on a Mac or on EAS.
This is the workaround the design of this course names for lesson 10: **the team without a Mac rents
one by the minute, through somebody else's service.**
