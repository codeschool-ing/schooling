---
title: Two people will judge the wrapper
version: 1
---

**A wrapped app is judged twice before it succeeds**: once by a store's reviewer, who decides whether
it may be published, and then by every person who installs it, who decides whether to keep it. Both
are asking the same question in different words, which is whether this is an app or a website in a
frame. Lessons 2 to 5 built the frame. This lesson is about the answer, and it is the most expensive
one in the course to get wrong, because it is usually found out late: at the review, or in the first
week of ratings.

## What the stores say

**Apple says it in its App Store Review Guidelines, section 4.2, "Minimum Functionality"**: an app
should include features, content and interface that take it beyond a repackaged website, and one that
is not useful, unique or "app-like" does not belong in the store. The next rule, 4.2.2, names the
cases it means: apps that are mostly marketing, web clippings, content aggregators or a collection of
links. Neither rule mentions Capacitor or WebViews. **The test is what the app does, not how it is
built**: plenty of wrapped apps are published, and plenty of native ones are refused under the same
rule.

**Google Play says it in its spam policy**, which covers apps whose main purpose is to show a website
in a WebView, and in particular a website the developer does not own or run, or that copies content
from elsewhere. An app that is the developer's own service, doing things there for its user, is not
what that rule is about.

*Both documents change, and the reviewers apply them with judgement rather than by a checklist. Read
the current version of each before you submit; the summary above is what they said when this course
was written.*

## What a person notices

A reviewer spends minutes with an app; the people who install it spend weeks. What they notice is not
the WebView, it is the places where the app does not behave like the others on their phone:

- **the back gesture or button does nothing**, or leaves the app when it should go back a screen;
- **text can be selected and a page can be zoomed** where nothing else on the phone allows it;
- **a tap waits**, because the screen is drawn by a slow page, and a list stutters when it scrolls;
- **nothing works offline**, because the app expected the network that a website always has;
- **the app forgets** where the person was each time the system closes it in the background.

**Every one of these can be fixed inside the WebView**, and each fix is web work you know how to do. The
back button is handled with Capacitor's `App` plugin; then come a stylesheet that turns off selection and zoom
where they make no sense, a smaller page, a cache, and saving state as lesson 4 did. The planner has some
of them right already and some not, and the next sections find out which before a reviewer does.
