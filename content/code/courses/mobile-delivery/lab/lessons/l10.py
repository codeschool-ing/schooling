LESSON = "le-5zytd679"
TITLE = "CI for mobile: a hosted Mac, caching, and signing inside the pipeline"
SECTIONS = [
    ("intro", "video", 80, """
Lesson 1 signed a package on your desk. {{desk}} A release should never depend on one desk. It should be built, checked and signed by a pipeline, the same way every time.

Mobile pipelines have three problems web pipelines do not. {{mac}} The iOS half needs a Mac, which costs more per minute than anything else you rent. {{cache}} Builds are slow, so caching decides whether a run takes six minutes or twenty. {{keys}} And the pipeline has to sign, which means it has to hold the keys.

Today you do the parts that run anywhere. {{local}} You compute a cache key from a lockfile and watch it change only when it should. You run the signing step of the pipeline on your own computer, with the keystore arriving as a secret.

And you read the whole workflow, {{workflow}} Android on Linux and iOS on a hosted Mac, with every check from the earlier lessons in it.
"""),
    ("the-hosted-mac", "reading"),
    ("caching", "reading"),
    ("signing-in-the-pipeline", "reading"),
    ("the-workflow", "reading"),
    ("drill", "practice"),
]
