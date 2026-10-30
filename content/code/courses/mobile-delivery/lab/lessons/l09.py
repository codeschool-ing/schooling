LESSON = "le-knmjpj5g"
TITLE = "Versioning: version name, build number, and the semantics people read"
SECTIONS = [
    ("intro", "video", 70, """
Every release carries two numbers, and they are for different readers. {{two}} One is for people: one point five point zero. The other is for machines: a plain integer that only ever goes up.

People read the first one in the store. {{people}} Machines use the second one to decide whether an update is newer, and the stores refuse one that is not.

Today you write the rule that turns the first into the second. {{derive}} One version name and a build counter in, one version code out, the same on Android and iOS.

And you will see why the rule matters. {{hotfix}} A hotfix for an older line, with a perfectly sensible name, that no phone would ever be offered.
"""),
    ("two-numbers", "reading"),
    ("only-up", "reading"),
    ("deriving-the-code", "reading"),
    ("what-people-read", "reading"),
    ("drill", "practice"),
]
