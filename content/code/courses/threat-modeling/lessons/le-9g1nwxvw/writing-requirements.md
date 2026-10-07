---
title: Writing a requirement somebody can check
version: 1
---

"The portal must be secure" is a sentence nobody can disagree with and nobody can test. It is also
the most common security requirement in the world. **A good security requirement is one a person
who was not in the room can verify**, and four properties make that possible.

| property | the question | fails like this |
|---|---|---|
| **specific** | does it say which part of the system and which behaviour? | "access must be controlled" |
| **testable** | can somebody write a test, or a review step, that passes or fails? | "passwords must be strong" |
| **one thing** | does it say a single thing, so that half of it cannot be done and the whole ticked? | "uploads must be validated and scanned and limited" |
| **behaviour, not hope** | does it say what the system does, not what nobody will do? | "attackers must not be able to read exams" |

The last one deserves a second look. "Attackers must not be able to read exams" sounds like a
requirement and is a hope: it describes something the system cannot control. The version that
works describes what the portal does: *it returns an exam only to the patient it belongs to.* A
test can ask for somebody else's exam and check the answer.

### Numbers are decisions, write them

"Uploads must be limited in size" is not testable until somebody writes the number. **20 MB** in
R13 was a decision: the largest exam a patient had uploaded in a year was under 9 MB, and 20 left
room. Writing it down turns an argument into a value that can be changed later with a reason.
The same goes for R03's ten failed attempts an hour, and R06's thirty days.

### Using a standard as a catalogue

Nobody has to invent security requirements from nothing. The **OWASP Application Security
Verification Standard (ASVS)** is a catalogue of hundreds of them, grouped by area
(authentication, session management, access control, validation, logging and more) and graded in
three levels of rigour. Version 5.0, published in 2025, is the current one.

The ASVS is the right place to look for **how** to state a requirement and for requirements the
team forgot. It is the wrong place to start: adopting a whole level of it gives a list nobody can
trace back to a threat, and the model loses the reason each requirement exists. Vereda's habit is
the other way round: write the requirement from the threat, then look up the ASVS area it belongs
to and borrow its wording if it is clearer. The `secure-code` course (lesson 20) uses the ASVS from
the developer's side, as a checklist during the build.

### Verified by what

Every requirement says how it will be checked, and there are three honest answers:

- **a test**, automated, run on every change: R01, R10, R13;
- **a review**, a person checking a configuration or a design: R07, R15, R16, which are about
  cloud permissions and networks that no unit test can see;
- **nothing yet**, which is allowed as long as it is written down. It is a known gap, and the
  traceability program finds every one of them.
