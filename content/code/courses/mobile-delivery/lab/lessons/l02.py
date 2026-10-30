LESSON = "le-k6jkkjjp"
TITLE = "Signing on iOS: certificates, provisioning profiles, and the expiry that stops the build"
SECTIONS = [
    ("intro", "video", 75, """
On Android, you made your own key and nobody checked it. {{android}} On an iPhone it works the other way round. Apple is the authority, and nothing runs unless Apple signed something first.

So an iOS build carries a chain. {{chain}} A certificate that says who you are. An App ID that says which app. And a provisioning profile that ties them together, with the devices it may run on.

Each link has a date on it. {{expiry}} And the morning a certificate expires is the morning the release build stops working, usually on the day you needed it.

This lesson is read, because it needs a Mac. {{mac}} But one part runs anywhere: a small script that reads certificates and warns you a month before one runs out. You write it today, and lesson 10 puts it in the pipeline.
"""),
    ("the-chain", "reading"),
    ("development-and-distribution", "reading"),
    ("who-signs", "reading"),
    ("watching-the-expiry", "reading"),
    ("drill", "practice"),
]
