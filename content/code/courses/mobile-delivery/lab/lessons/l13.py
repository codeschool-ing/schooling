LESSON = "le-3yyk7fsq"
TITLE = "Reading a stack trace from a minified release build"
SECTIONS = [
    ("intro", "video", 75, """
The crash report from lesson 12 named a file and a line. {{readable}} That only happened because the code was not minified. A release build is.

Release builds are shrunk on purpose. {{shrink}} Names become single letters, functions are folded into each other, and the whole JavaScript bundle becomes one line. The app is smaller and faster, and its stack traces are unreadable.

Today you make one readable again, twice. {{twice}} A minified JavaScript bundle, the way React Native ships one, read back through its source map. And a Java program shrunk by R8, the tool every Android release goes through, read back with its mapping file.

Then the iOS version of the same idea, {{ios}} the dSYM, which you read about here because it needs a Mac. Three platforms, one rule: keep the file the build produced, or the crash cannot be read.
"""),
    ("what-minification-does", "reading"),
    ("a-minified-javascript-trace", "reading"),
    ("r8-and-retrace", "reading"),
    ("ios-and-the-dsym", "reading"),
    ("drill", "practice"),
]
