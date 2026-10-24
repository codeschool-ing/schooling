---
title: A checklist for the wrapper
version: 1
---

**Before an app goes to a reviewer, run through it as a person would on a phone**, and write down what
happens. Each row below is one of the complaints of this lesson's first section, turned into a check,
with what the planner does today:

| check | why it matters | the planner today |
|---|---|---|
| the system's back gesture goes back one screen | on Android it closes the app otherwise | **no**: Android's back leaves the app from a course page |
| no text selection or page zoom where an app would have none | it is the first tell of a page | **no**: the defaults of a page apply |
| every tap answers within a frame or two | a slow tap is tapped again | **yes** at the demonstration's size, not at thousands |
| it opens and works with no network | a person opens it on a train | **yes**: everything it needs is inside the app |
| it comes back where it was after the system closed it | phones close apps in the background | **partly**: the plan survives, the open course does not |
| permissions are asked at the moment of use, with a reason | an early or unexplained question gets a no | **yes**, since lesson 4 |
| every control works with a screen reader and a keyboard | a person who cannot see the screen still uses the app, and the law asks for it in many places | **yes**: real buttons and labels since lesson 1 |
| it does something a website could not | Apple's rule 4.2 | **yes**: reminders, the camera, a screen kept on |

**Two of the "no" answers have one-line causes and short fixes**, and both are web work. Android's back
button reaches the app through Capacitor's `@capacitor/app` plugin, whose `backButton` event the
planner can handle by going back to the list of courses, and leaving the app only from there. Selection
and zoom are a few lines of CSS and the viewport's `user-scalable` setting, applied to the app's chrome
and not to the content somebody may want to copy.

*The planner leaves these as they are, so that the lesson can show a real "no"; your own app should
not. The checks are the ones this course could run in a browser; on a phone, the behaviour of the back
gesture and of the system closing the app has to be seen on the phone.*

## The row that decides

**The last row is the one a reviewer applies**, and the only one that no amount of polish fixes. If the
honest answer is that the app shows the same thing the website shows, the question is no longer how to pass review. It is whether the app should exist, or whether the website, installable as a Progressive
Web App, already does the job without any store at all.
