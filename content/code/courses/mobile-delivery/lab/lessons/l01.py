LESSON = "le-cxeq662t"
TITLE = "Signing on Android: keystore, Play App Signing, and the key that cannot be lost"
SECTIONS = [
    ("intro", "video", 80, """
This course starts after the build works. {{build}} The app compiles, the tests pass, and nobody outside your desk has it yet. Everything between that moment and a phone in somebody's pocket is what this course is about, in twenty lessons.

The first thing between them is a signature. {{signature}} Android will not install an app that nobody signed. And it will not install an update signed by somebody else. So the key you sign with becomes the app's identity, for as long as the app exists.

Today you make one. {{keytool}} A keystore, a key inside it, and a small app signed with it on your own computer. Then you ask the tools to prove what they did.

Then the part that saves people. {{play}} Google Play keeps the key that phones check, and you keep a second one for uploading. Lose your upload key and Google can replace it. Lose the other one, without Play holding it, and the app is gone.

And one thing is said now, before anything costs money. {{fees}} Both stores charge for an account. This lesson tells you which lessons you can practise without one.
"""),
    ("the-boundary", "reading"),
    ("your-computer", "reading"),
    ("what-a-signature-proves", "reading"),
    ("a-signed-apk", "reading"),
    ("play-app-signing", "reading"),
    ("when-setup-fails", "reading"),
    ("drill", "practice"),
]
