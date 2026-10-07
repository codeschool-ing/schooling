---
title: Abuse cases at Vereda
version: 1
---

Crossing the portal's main use cases with the actors of this lesson gave the team ten abuse cases
in an hour. Each one names the threat it tells the story of, and three of them told a story no
threat on the list had told yet.

| | use case | actor | abuse case | threat |
|---|---|---|---|---|
| A1 | book a session | password-list runner | signs in with a leaked password and sees the patient's bookings and exams | T02 |
| A2 | book a session | any patient | books and cancels in a loop, sending an SMS each time | T11 |
| A3 | view my exams | signed-in patient | changes the exam number and downloads somebody else's report | T07 |
| A4 | upload an exam | signed-in patient | uploads files until the storage is full | T10 |
| A5 | receive a reminder | someone close to a patient | reads the reminder on the patient's phone and learns where they will be, and when | T08 |
| A6 | manage the agenda | curious receptionist | opens a neighbour's clinical notes | T09 |
| A7 | manage the agenda | former employee | signs in months after leaving, because the account still works | **new: T15** |
| A8 | view my bookings | someone close to a patient | signs in with the patient's password and watches the agenda week by week | **new: T16** |
| A9 | change my phone number | someone close to a patient | changes the number so that reminders, and password resets, go to their phone | **new: T17** |
| A10 | pay for a session | any patient | pays, then sends a forged webhook for the next booking | T01 |

**Three new threats**, and none of them needed new technology to find. Each came from putting an
actor next to a feature and asking what that person would do with it:

- **T15** (S, the console): accounts of staff who have left are not switched off.
- **T16** (I, sign in and book): a person who knows a patient's password keeps reading their
  agenda, and nothing tells the patient another session is open.
- **T17** (S, sign in and book): changing the phone number needs no second confirmation, so
  whoever holds a session can redirect everything that proves identity.

The three go into `threats.csv` with the next ids, filed against the elements the lesson names. A9
is the most serious of them, and it is a good example of what abuse cases are for: changing a
phone number is a feature nobody thinks of as security, and it is the one that hands over the
account.

### And one that is not

A10, paying and then forging the next webhook, is T01 told as a story. Abuse cases repeat threats
often, and that is fine: the repetition is the same flaw described in the words of the feature it
breaks, which is what a product owner needs to see before deciding where it goes in the backlog.
