LESSON = "le-km13xvqf"
TITLE = "Supporting versions in the wild: the API contract and the app that never updates"
SECTIONS = [
    ("intro", "video", 75, """
A website has one version: the one on the server. {{one}} An app has every version anybody ever installed, and some of them will be opening your API for years.

That is the subject of the last lesson. {{tail}} First you count them: which versions are still in use, and how many people a new minimum would send to the update screen.

Then the contract. {{contract}} Every field an old version reads is a promise the server keeps, and the safe way to change an API is to add, never to rename or remove.

You will write a test that holds the server to those promises, {{test}} one file per supported version, and watch it fail on a rename that looked harmless.

And at the end, how a promise is withdrawn on purpose. {{sunset}} A date announced in a header, a minimum version raised, and an answer that tells an old app to update instead of breaking it.
"""),
    ("the-app-that-never-updates", "reading"),
    ("the-api-contract", "reading"),
    ("a-contract-test", "reading"),
    ("retiring-an-endpoint", "reading"),
    ("drill", "practice"),
]
