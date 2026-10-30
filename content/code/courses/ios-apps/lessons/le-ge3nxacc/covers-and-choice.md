---
title: Full-screen covers, and choosing between the three
version: 1
---

**A full-screen cover is a sheet that takes the whole screen and cannot be swiped away.** It is for a
mode the person has to leave deliberately: a camera, a video, an onboarding the app needs finished
before anything else makes sense. It is written the same way as a sheet, with
`fullScreenCover(isPresented:onDismiss:content:)`, and the screen inside it must offer its own way
out, because there is no gesture to fall back on. Nothing here was run; it is written from Apple's
documentation for `fullScreenCover` and the *Human Interface Guidelines* on modality.

```swift
.fullScreenCover(isPresented: $timing) {
    StudyTimer(sessionID: session.id)   // has its own "Stop" button that calls dismiss()
}
```

The planner has a candidate: a timer that runs while the person studies a session and marks it done
when they stop. It is a mode, it should not be lost to a swipe, and nothing behind it matters until
it ends.

## Which one

| the person is… | use | because |
|---|---|---|
| going deeper into what they are looking at: a course, then a session | a push, `NavigationLink(value:)` | it belongs in the back history, and back undoes it |
| doing a short task that returns them here: add a session | a sheet | it is not a place to go back to, and a swipe or *Cancel* abandons it |
| in a mode they must end on purpose: a study timer | a full-screen cover | nothing behind it is reachable, and the way out is a button |
| answering one question: delete this course? | an alert or a confirmation dialog | it is a decision, not a screen |

**The test is what *back* should do.** If going back should return to the screen before, it is a
push. If the screen is a detour that closes, it is a sheet or a cover, and the difference between
those two is whether a swipe may abandon it. Apple's guidelines put it the other way round: present
modally only when the person needs to finish or dismiss a task before going on, which is why the
form, the timer and the question are modal and the course and session screens are not.

**Presentation is state like any other**, and it has one owner. `adding` lives in the course screen,
the path lives in the model. A sheet the model needs to open from elsewhere, say a notification
asking to add tomorrow's session, would move its flag into the model beside the path, for the same
reason section 04 moved the path.
