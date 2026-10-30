LESSON = "le-zd9c3bkx"
TITLE = "Crash reporting with Crashlytics or Sentry, and uploading symbols"
SECTIONS = [
    ("intro", "video", 75, """
When an app crashes on somebody's phone, it simply disappears. {{vanish}} Nobody sees an error. Most people do not write to you. Without a crash reporter, the crash never happened, as far as the team knows.

A crash reporter is small, and it always works the same way. {{shape}} It catches the crash, writes a report to the phone's disk, and sends it the next time the app opens. Not at the moment of the crash, because a crashing app cannot be trusted to finish anything.

Today you build one, {{build}} in a few dozen lines, with a server that receives what it sends. You will read every field it carries, and decide which ones should be there.

Then the real products, side by side. {{products}} Crashlytics and Sentry, on Android, on iOS and in React Native. And the step people skip, uploading the symbols, without which every report is a list of addresses.
"""),
    ("what-a-reporter-does", "reading"),
    ("a-reporter-you-can-read", "reading"),
    ("crashlytics-and-sentry", "reading"),
    ("grouping-and-the-numbers", "reading"),
    ("drill", "practice"),
]
