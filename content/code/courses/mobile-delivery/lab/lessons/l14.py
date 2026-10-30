LESSON = "le-6hyt88rc"
TITLE = "ANRs, watchdog kills, and the crash that is not a crash"
SECTIONS = [
    ("intro", "video", 70, """
Some of the worst failures of a mobile app are not crashes. {{frozen}} The screen freezes. Taps do nothing. Five seconds later Android asks whether to close the app, and on iOS the system simply ends it.

These are hangs, and the system treats them as seriously as crashes. {{counted}} Google Play counts them against your app, and Apple's watchdog leaves its own code in the report: ate bad food.

Today you watch one happen. {{watch}} A main thread that stops answering, and a second thread whose only job is to notice. That is how the hang detectors in Crashlytics and Sentry work.

And then the kill that leaves nothing at all. {{jetsam}} When the system runs out of memory, it ends apps without warning, and no crash reporter can catch it. You learn what evidence is left, and where.
"""),
    ("the-anr", "reading"),
    ("watchdog-and-jetsam", "reading"),
    ("a-watchdog-you-can-watch", "reading"),
    ("off-the-main-thread", "reading"),
    ("drill", "practice"),
]
