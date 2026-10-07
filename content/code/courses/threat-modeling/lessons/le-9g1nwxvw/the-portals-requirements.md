---
title: The portal's requirements
version: 1
---

ana and carla wrote the requirements in an afternoon, threat by threat, with daniel answering the
questions that were decisions rather than engineering: how many failed sign-ins are too many, how
large an exam can be, how long an unused staff account may stay open.

| id | threats | requirement | verified by |
|---|---|---|---|
| R01 | T01 | The portal accepts a payment webhook only when the gateway's signature over its body verifies. | test |
| R02 | T01 | The portal marks a booking paid only when the webhook's amount and booking match an open charge. | test |
| R03 | T02 | Patient sign-in allows at most 10 failed attempts per account per hour. | test |
| R04 | T02 | Sign-up and password changes refuse passwords found in known breach lists. | test |
| R05 | T03 | Staff sign-in requires a second factor every time. | test |
| R06 | T15 | A staff account unused for 30 days is disabled automatically. | test |
| R07 | T04 | The portal's storage credential can create exam files and cannot overwrite or delete them. | review |
| R08 | T05 | Every change to a clinical note is kept as a new version with its author and time. | test |
| R09 | T06 | Every cancellation records the account that made it and when. | test |
| R10 | T07 | The portal returns an exam only to the patient it belongs to and answers any other request as if it did not exist. | test |
| R11 | T08 | A reminder text contains only the date and time and how to cancel. | review |
| R12 | T09 | The receptionist role cannot open clinical notes or exams. | test |
| R13 | T10 | An upload larger than 20 MB or not a PDF is refused. | test |
| R14 | T11 | An account triggers at most 5 reminder messages a day. | not yet |
| R15 | T12 | The staff console answers only requests from the clinics' network. | review |
| R16 | T13 | The reminder worker's database account can read bookings and nothing else. | review |
| R17 | T16 | Patients see their open sessions and can end any of them. | not yet |
| R18 | T16, T17 | Signing in from a new device or changing the phone number sends the patient an e-mail. | test |
| R19 | T17 | Changing the phone number needs a code sent to the old number. | test |

Nineteen requirements for seventeen threats, and four things about the list are worth noticing.

**T14 has none.** The crafted PDF that attacks the viewer on a clinic computer needs either a new
viewer or a rule that staff never download exams, and neither could be decided in an afternoon.
The threat stays on the list without a requirement, which is allowed, and lesson 12 is where it
gets a decision with a name and a date on it.

**Two requirements have no verification yet.** R14 limits reminder messages and R17 shows a
patient their open sessions. Both are clear and testable; nobody has written the test, because
neither feature exists yet. Saying "not yet" in the column is the honest state, and it is the one
a later lesson can check has changed.

**Four are verified by review, not by test.** R07, R11, R15 and R16 are about a storage
permission, a message template, a network rule and a database account. A unit test in the portal's
code cannot see any of them. A review is weaker than a test, because it happens when somebody
remembers to do it, and lesson 15 turns some of these into checks that run on every change.

**R02 came from a dependency, not from STRIDE.** The amount check exists because lesson 6 asked
what happens if the gateway itself is compromised. It covers T01 in a way the signature cannot, and
it would have been missed by a model that only asked about the webhook's sender.

### Kept in the repository

The table lives in `requirements.csv`, beside `threats.csv`, with the same columns. The
`threats` column names one or more threat ids separated by spaces, which is the join the next
section uses.
