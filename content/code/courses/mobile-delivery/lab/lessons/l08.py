LESSON = "le-9v0sybsc"
TITLE = "Staged rollout, and halting a release that is crashing"
SECTIONS = [
    ("intro", "video", 75, """
On the web, a bad release is undone in a minute. {{web}} You deploy the previous version and everybody has it. On a phone, the release is already installed. You cannot take it back.

So the release goes out slowly instead. {{stages}} One per cent of people on the first day, then two, then five. Google Play lets you choose the steps; Apple runs a seven-day schedule.

Today you simulate one, day by day. {{simulate}} A version that crashes on older Android phones, a rule that compares it with the version before it, and the day the rule says halt.

And you will see the part that surprises people. {{halt}} Halting stops new installs. Everybody who already has the bad version keeps it, until a fix reaches them.
"""),
    ("two-ramps", "reading"),
    ("no-rollback", "reading"),
    ("deciding-to-halt", "reading"),
    ("after-the-halt", "reading"),
    ("drill", "practice"),
]
