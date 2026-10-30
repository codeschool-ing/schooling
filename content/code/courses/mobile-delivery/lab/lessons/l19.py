LESSON = "le-ek6avnz4"
TITLE = "Forced update, remote config and feature flags"
SECTIONS = [
    ("intro", "video", 75, """
Lesson 8 ended with a problem. {{problem}} A bad version on a thousand phones, and no way to reach into them. The tools of this lesson are how you reach them, as long as you built them in before the bad version shipped.

The first is a minimum version. {{minimum}} The app asks the server, at start-up, which versions are still allowed. Below the minimum, it asks the person to update before going on.

The second is remote configuration. {{config}} Values the app reads from a server instead of from its own code, with a cached copy and safe defaults for the day the server cannot be reached.

And the third is the feature flag. {{flags}} A switch per feature, on for a share of installs, and a kill switch that turns it off for everybody in minutes. Today you run all three, against a small server on your own computer.
"""),
    ("forced-update", "reading"),
    ("remote-config", "reading"),
    ("feature-flags", "reading"),
    ("the-cost-of-a-flag", "reading"),
    ("drill", "practice"),
]
