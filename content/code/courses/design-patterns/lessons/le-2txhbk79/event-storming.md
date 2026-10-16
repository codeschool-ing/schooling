---
title: "Event storming: finding the model in a room"
version: 1
---

**Event storming is a workshop in which the people who know the business and the people who will
build the software cover a long wall with sticky notes, one for each thing that happens, and put
them in order.** Alberto Brandolini devised it around 2013 as a fast way to do the strategic work
of this lesson: find the language, find where it changes, and find what nobody understands yet.

The wrong way to start, and the usual one, is a requirements document written by one side and read
by the other. It arrives in the developers' vocabulary or the business's, never both, and its gaps
are invisible because a document reads as complete. A wall of notes in time order makes a gap look
like a gap: two notes with nothing between them, and somebody asking "and then what?".

## The notes

Each colour is a different kind of thing, and the convention is worth keeping because it lets a
room read the wall at a glance:

| colour | what it is | from the library |
|---|---|---|
| orange | a domain event: something that happened, in the past tense | *Copy returned*, *Hold lapsed* |
| blue | a command: what somebody asked for | *Place hold*, *Renew loan* |
| small yellow | the actor who gave the command | member, librarian |
| lilac | a policy: "whenever this happens, do that" | whenever a copy is returned with holds against its title, shelve it |
| pink | a hotspot: a question, a disagreement, a pain | "what if the member at the front owes more than 1000 cents?" |

The orange notes come first and matter most. **Past tense is the rule that does the work**:
*Hold lapsed* is a fact somebody can confirm or deny, where *lapsing* or *the lapse process* is
already a design. Lesson 9 stored exactly these facts as events, and lesson 12 raises them from
inside the model.

## A stretch of the library's wall

An afternoon with three librarians and two developers produced, among a few hundred notes, this
stretch, in time order:

| | the orange note | said by |
|---|---|---|
| 1 | *Copy ordered* | the person who deals with suppliers |
| 2 | *Copy received* | the person who deals with suppliers |
| 3 | *Title catalogued* | the cataloguer |
| 4 | *Hold placed* | the lending desk |
| 5 | *Copy returned* | the lending desk |
| 6 | *Copy shelved for hold* | the lending desk |
| 7 | *Hold collected* | the lending desk |
| 8 | *Loan started* | the lending desk |
| 9 | *Loan overdue* | the lending desk |
| 10 | *Fine charged* | the lending desk |
| 11 | *Hold lapsed* | the lending desk |
| 12 | *Fine paid* | the lending desk |

Look at where the vocabulary shifts. *Copy ordered* and *Copy received* are said by the person who
deals with suppliers, about money and quantities. *Title catalogued* is the cataloguer's, about
descriptions. From *Hold placed* on, every note is the lending desk's, about members and dates.
**Those shifts are candidate boundaries**: the three bounded contexts of the earlier sections came
off this wall, with the word *book* meaning a different thing on each side of them.

The pink notes were the other harvest. One sat between *Copy returned* and *Copy shelved for hold*:
what happens when the member at the front of the queue owes more than the 1000-cent limit? One
librarian said the copy waits for her; another said it goes to the next member. Nobody had written
it down, because each of them had been doing it her own way for years. A requirements document would
have stated one answer and hidden the disagreement. The wall made it a question for the library to
decide, before anybody wrote the code.

## How it runs

The format has variations, and a common sequence for a first session goes like this:

1. everybody writes orange notes at once, with no order and no debate;
2. the room arranges them into one timeline and removes duplicates;
3. pink notes mark every disagreement and question;
4. blue commands, actors and lilac policies are added where they explain an event;
5. the group draws lines where the language changes, and names the parts.

Two hours and a long roll of paper will do for a first pass on a domain the size of the library's.
What comes out is the vocabulary, a first context map and a list of questions. That falls short
of a design, and it is everything the first five sections of this lesson asked for.
