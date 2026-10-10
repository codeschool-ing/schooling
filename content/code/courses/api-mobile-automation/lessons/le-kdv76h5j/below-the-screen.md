---
title: The layer below the screen
version: 1
---

**A screen shows what a server decided.** When a ticket app says *"2 seats left"*, the phone did not
count anything: it asked a server, the server answered with a small piece of text, and the app
drew that text. If the count is wrong, the defect is in the answer, and the screen only repeats it.
Every app in this course works that way, and so do most apps you will ever test.

The conversation between the two has a name. An **API**, an application programming interface, is
the set of questions a program agrees to answer and the shape of each answer. The ones this course
tests speak HTTP, the protocol of the web: the app sends a request to an address, the server sends
back a response. Nothing about it is visual, which is exactly why it is worth testing on its own.

## Why test there first

Three reasons, and each one is a measurement rather than a taste.

- **It is faster.** A request to an API answers in milliseconds: section 06 times one at under a
  hundredth of a second. The same check through the app means starting it, waiting for a screen,
  finding a button and reading a label, which takes seconds even when a machine does it.
- **It is steadier.** A screen test fails for reasons that have nothing to do with the defect: an
  animation that had not finished, a keyboard covering a button, a phone that went to sleep.
  Lesson 19 lists the ways an emulator misleads. A request has none of those; when it fails, it
  failed because the answer was wrong.
- **It reaches what the screen hides.** An app that never sends seven seats cannot show you what
  the server does with seven. The API can be asked directly, and a server that accepts seven when
  the rule says six is a defect no screen test was going to find.

None of this makes the app's own tests unnecessary. A server can answer perfectly and the app can
still draw the wrong number, lose the answer when the phone rotates, or freeze on a slow
connection. That is lessons 14 to 22. **The course is two halves on purpose**: lessons 1 to 13 test
the API, lessons 14 to 22 test the app on a phone, and lesson 14 says where the line between them
falls.

## What an API test is

The test cases you designed by hand in `manual-testing` carry over unchanged in their thinking: an
input, an expected result, a reason. What changes is who performs them. An API test is a program
that sends a request and checks the response against what was expected:

| | a manual case | the same case against the API |
|---|---|---|
| **step** | choose 3 seats for the 8 November show and press *Buy* | `POST /v1/orders` with `{"show_id": "sh-103", "seats": 3}` |
| **expected** | a confirmation with the total, R$ 195,00 | status `201`, and `"total_cents": 19500` in the body |
| **evidence** | a screenshot | the response, saved as text |

The second column can be run a thousand times a day by a machine, and lessons 4 to 8 do exactly
that with four different tools. Before any of them, you need to read a response yourself, which is
what the rest of this lesson is for.
