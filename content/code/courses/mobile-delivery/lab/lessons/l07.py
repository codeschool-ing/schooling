LESSON = "le-hrqpyrne"
TITLE = "Internal, closed and open testing; TestFlight"
SECTIONS = [
    ("intro", "video", 70, """
Before a release reaches everybody, it should reach somebody. {{testers}} A few colleagues first, then people who asked to try it, then a public beta. Both stores have a ladder for this.

On Google Play the ladder is a set of tracks. {{tracks}} Internal, closed, open, and production. On iOS it is TestFlight, with internal and external testers.

The rule that matters most is simple. {{same}} The build your testers tried is the build that ships. You promote it up the ladder. You never rebuild it at the top.

Today you model the tracks in a short script, {{script}} and watch which build each person actually gets. One case surprises people: a tester who is on two tracks at once.
"""),
    ("the-tracks-on-play", "reading"),
    ("testflight", "reading"),
    ("one-build-promoted", "reading"),
    ("who-tests", "reading"),
    ("drill", "practice"),
]
