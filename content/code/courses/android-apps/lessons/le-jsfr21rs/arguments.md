---
title: Arguments: an id, and never the object
version: 1
---

**A route with properties is a destination with arguments.** `CourseDetail("kotlin")` is the course
screen for Kotlin, and `entry.toRoute<CourseDetail>()` in section 02's graph turns the back stack
entry back into a `CourseDetail` with its `courseId` filled in. The compiler checks both ends: a
route that needs a `courseId` cannot be navigated to without one, and the screen receives a
`String`, not something it has to cast.

Under the type, Navigation still works with strings, and section 04's test prints them. Here is what
the stack held after tapping Kotlin, and the argument the entry on top carries:

```
ana@vm:~/planner$ grep -h -e 'tap Kotlin' -e 'argument' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.NavigationTest.xml
tap Kotlin             Courses  >  CourseDetail/{courseId}
courseId argument: kotlin
```

`CourseDetail/{courseId}` is the pattern Navigation generated from the class: the route's name, and
a placeholder for each property. The entry fills the placeholder with `kotlin`, and that is what
`toRoute` reads back. Before version 2.8 apps wrote these strings by hand, `"course/{courseId}"`,
and a typo in one of them was a crash at run time rather than an error at compile time.

## Pass the id, look up the rest

**The argument is `courseId`, not the `Course`.** It is tempting to pass the whole object, the
name, the colour, the sessions, so that the next screen has everything at once. Three reasons it is
the wrong habit:

- **Arguments are saved with the back stack**, in the same `Bundle` lesson 8's keys had to fit,
  so that the stack survives the system taking the process away. A `Bundle` is meant for small
  values; a list of sessions in it is the kind of thing that fails with `TransactionTooLargeException`
  on somebody's phone.
- **A copy goes stale.** The course screen showing a session list passed as an argument shows the
  list as it was when the user tapped; a session added on the next screen is not in it.
- **The id is enough to find the rest**, and finding it is the next screen's job. In lesson 10 that
  job moves into a `ViewModel` that reads the course by its id; in lesson 16, a repository answers.

So the planner's routes carry ids, and only ids.
