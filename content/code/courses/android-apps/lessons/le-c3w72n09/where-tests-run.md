---
title: Three places a test can run
version: 1
---

**An Android test is defined less by what it checks than by where it runs**, and the place decides
its cost. Lessons 18 to 20 have already written tests of all the kinds this course can run: a worker
answering three ways, a notification read back from the system, a permission refused twice. This
lesson names the kinds, writes one of each for the planner's week screen, and adds the one kind this
course could not run.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l21-layers\" aria-label=\"Three kinds of test side by side. Plain JUnit, in src/test, runs on your computer's JVM with no Android at all: it checks logic such as the week's total. Robolectric, also in src/test, runs on the same JVM with a stand-in for Android: it checks composables, notifications and permissions, and Roborazzi saves screenshots there. Instrumented tests, in src/androidTest, run on a phone or an emulator: they check the real system. An arrow from left to right says: closer to a real phone. An arrow from right to left says: faster, and runnable on any computer.\"><defs><marker id=\"l21-layers-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"16\" y=\"20\" width=\"216\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"124\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">plain JUnit</text><text x=\"124\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">src/test</text><text x=\"124\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">your JVM, no Android</text><text x=\"124\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">logic: the week's total,</text><text x=\"124\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the offer table</text><text x=\"124\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">run here</text><rect x=\"252\" y=\"20\" width=\"216\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Robolectric</text><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">src/test</text><text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">your JVM, a stand-in Android</text><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">composables, notifications,</text><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">permissions, screenshots</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">run here</text><rect x=\"488\" y=\"20\" width=\"216\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"596\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">instrumented</text><text x=\"596\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">src/androidTest</text><text x=\"596\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a phone or an emulator</text><text x=\"596\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the real system: dialogs,</text><text x=\"596\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the shade, a real GPU</text><text x=\"596\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">not run here</text><path d=\"M40 196 L680 196\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-layers-ah-wire)\"></path><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">closer to a real phone</text><path d=\"M680 232 L40 232\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-layers-ah-wire)\"></path><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">faster, and runs on any computer</text></svg>", "caption": "Each step to the right is closer to what a student holds and further from what a laptop can run. This course runs the first two on every lesson, and describes the third."}
```

- **Plain JUnit** runs on your computer's JVM with no Android in it at all. It can test anything
  that is only Kotlin: the week's total, lesson 20's table of offers, a date calculation. It lives in
  `app/src/test`.
- **Robolectric** runs on the same JVM, in the same folder, with a stand-in for the Android framework.
  It can test composables, notifications, permissions and workers, and Roborazzi saves screenshots
  from it. Most screenshots in this course came from one.
- **Instrumented tests** run on a phone or an emulator, from `app/src/androidTest`. They test the
  real system, including the parts Robolectric only imitates. Section 06 writes one and shows what
  happened when it was asked to run here.

## What each one costs

The difference is not a matter of opinion; it is in the test reports. After the whole lesson's
tests have been written, Gradle runs them all again with `--rerun`, and every result file records
how long each test took:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --rerun 2>&1 | grep -E '^BUILD|tests completed'
BUILD SUCCESSFUL in 21s
ana@vm:~/planner$ grep -ho 'testcase name="[^"]*" classname="[^"]*" time="[^"]*"' app/build/test-results/testDebugUnitTest/*.xml | sed -e 's/classname="com.example.planner.//'
testcase name="sundayBelongsToTheWeekThatEndsOnIt" data.WeekTest" time="0.002"
testcase name="theTotalCountsOnlyThisWeek" data.WeekTest" time="0.0"
testcase name="aWeekRunsMondayToSunday" data.WeekTest" time="0.0"
testcase name="tickingASessionMovesTheTotal" ui.WeekScreenTest" time="6.149"
testcase name="theWeek" ui.WeekShotTest" time="9.437"
```

The three tests of `WeekTest` are plain JUnit, and each took a few milliseconds or none that the
report could count. The Robolectric tests took seconds each, and **most of that is starting the
stand-in Android**, which a plain test never pays for. An instrumented test adds installing the app
on a device and starting it there, which is why teams keep them few.

**The rule that follows is the usual one: push each check as far left as it can go.** If a
calculation can be tested without Android, test it without Android, and keep the slower tests for
what only they can see. Section 07 returns to that rule with the planner's own tests as examples.
