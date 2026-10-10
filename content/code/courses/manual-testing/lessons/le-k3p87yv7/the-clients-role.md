---
title: The client's afternoon
version: 1
---

The usual mistake about the client's part in UAT runs in one of two directions. Either the client
is treated as somebody to be shown a demonstration, kept away from anything that might go wrong, or
as a spare tester who will run the team's cases more slowly. **The client is in the room for what
only the client knows**: how the work is really done, on a busy night, by the people who do it. A
session is planned around getting that out of them.

This section follows one session. The theatre's manager has booked an afternoon to accept boxoffice
1.1, the build lesson 10 tested. Ana has prepared it.

## What the tester prepares

**The environment.** Version 1.1, started fresh a few minutes before the manager arrives, so the
seats are full and the orders start at 1001. A laptop she can use without Ana's shortcuts, and her
own phone, because half the theatre's customers book on one.

**The accounts and the data.** The member account, `member@example.org`, and its password on a card.
A sign-up done in advance for an account that has not been confirmed, so that the manager does not
spend ten minutes of her afternoon on the outbox.

**The cases, in her words.** The four criteria of section 03 of this lesson, printed one per page,
and five tasks written the way she would say them, such as "sell two tickets for Hamlet to a
student" and "a customer at the counter wants to cancel the order she made this morning". A task
says what to achieve and leaves the clicks to her, because how she goes about it is part of what
is being tested.

**A sheet for notes**, with columns for the time, the task, what she did, what she said and what
happened. The second-to-last column matters most.

## How the session runs

The manager drives and Ana sits beside her. Ana does not take the mouse, does not explain how the
screen works unless asked, and does not defend the product. When the manager hesitates, Ana writes
down where. A hesitation is data: a client who cannot find the student box in ten seconds has told
you something no system test measured.

Three things happened that afternoon, and they are the three kinds of finding UAT produces.

**A defect the team already knew.** On "sell two tickets for Hamlet to a student" she ticked the box,
pressed Book and read the order: 10% off, R$ 144,00. She said, "No. Students pay half; that's forty
reais each." It is the regression lesson 10 found and reported. Nothing new for the defect tracker,
and still worth writing down, because the manager has just given it a **business impact** in her own
words: "the school groups book on Tuesday; if this is live then, I am refunding sixty people by
hand."

**A requirement that is right as written and wrong for the theatre.** Reading the fourth criterion
aloud, the one where booking closes at 19:01, she stopped. "That's online. At the counter we sell
until the curtain goes up." The clerks sell at the counter through boxoffice too, so R4 closes the
counter as well, an hour before every show. The program does exactly what R4 says, so this is **not
a defect**. It is a gap in the requirement, found because the person who knows how the counter
works read the sentence, and it goes to the client and the developer as a **change request**.

**A question nobody can answer in the room.** On her phone, the table of shows ran off the right of
the screen, the defect lesson 7 found and reported. She asked whether the new season's
seven shows would make it worse. Ana did not guess. She wrote the question down for Rui with the
manager's name beside it.

## What Ana does with the notes

At the end, Ana reads the notes back and the manager confirms each one; a finding the client does
not recognise in the notes is a finding that will be disputed later. Then the notes become three
lists: defects, each one a report written the way lesson 15 teaches; change requests, each one a
sentence for the client and the developer to decide on; and questions, each one with somebody's name
against it.

**What Ana does not do is decide what any of it means for the release.** The student discount is a
defect the manager will not accept, in her words, and the counter closing is a change she wants. Two
findings, both of them hers to weigh. The next section is about how that weighing ends.
