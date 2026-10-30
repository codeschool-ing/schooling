---
title: In your portfolio
version: 1
---

**A release nobody can find is a folder on your disk.** The last step is putting it where people look, and
saying in a minute what it is. Three places, and each has a lesson elsewhere in the catalogue that goes deeper
than this one:

| where | what goes there | the lesson that covers it |
|---|---|---|
| the repository's README | what the app is, a screenshot, how to install, how to build | `portfolio-project`, lesson 16, "The README that gets the project understood in sixty seconds" |
| a release page | the seven files of the previous section, and the notes | GitHub Releases, below |
| your portfolio site | the app's name, one picture, a link to the release and to the code | `portfolio-project`, lesson 15, "Deploy: free tiers, a domain, and something that stays up" |

**GitHub Releases is the release page most projects use**: on the repository's page, **Releases, Draft a new
release**, choose the tag `v0.3.0`, paste `RELEASE-NOTES.md` as the description, and attach the files. Its
`gh` command line does the same, `gh release create v0.3.0 --notes-file RELEASE-NOTES.md` followed by the file
names. *Not run: the planner has no repository on GitHub.* Each file then has a permanent address, which is
also what the updater of lesson 15 can be pointed at, with electron-builder's `github` provider instead of
`generic`.

## What the README says about the app

A reader of a portfolio has a minute, and in that minute they want four things, in this order:

1. **what it is**, in one sentence a person who never saw it understands;
2. **a picture** of it running, on the platform you released for; `portfolio-project` lesson 17, "Screenshots, a
   demo video, and data that is not "test test"", is about making that picture worth looking at;
3. **how to get it**: the release link, the install line for each package, and how to check the signature;
4. **how it was made**: the route, linked to your decision note, and what was not built or tested.

**The fourth one is what an interviewer asks about.** "Why Capacitor and not React Native" is a question your
decision note already answers, and "what would you do differently" is a question a written retrospective
answers, which `portfolio-project` lesson 21 asks for.

## A store listing, if you made one

If the app is on Google Play or the App Store, the listing is a second front page: link it from the README,
and keep its screenshots and its description in step with the release. **The listing's privacy policy and
data forms of lesson 14 have to stay true**: a release that adds a feature which sends something off the
device changes what those forms must say, before the release goes out.
