LESSON = "le-5r87c7e1"
TITLE = "Analytics: events, funnels, and measurement that is not surveillance"
SECTIONS = [
    ("intro", "video", 75, """
A crash report says what broke. {{events}} Analytics says what people did: how many opened the planner, how many added a course, how many finished a session.

The unit of analytics is an event. {{event}} A name, a time, a few numbers, and an identifier for the installation. Put events in order and you get a funnel: where people arrive, and where they stop.

Today you build both, in SQLite, with a week of installs. {{funnel}} And you watch a quarter of the people who opened the app never finish a single session.

And one line is drawn on purpose. {{line}} Measuring the product is not watching the person. You will write a schema that refuses any property nobody decided to collect, and see it refuse the name of somebody's course.
"""),
    ("an-event", "reading"),
    ("a-funnel", "reading"),
    ("not-surveillance", "reading"),
    ("the-tools", "reading"),
    ("drill", "practice"),
]
