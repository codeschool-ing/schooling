---
title: Comments that get a flaw fixed
version: 1
---

Finding a flaw is half of a review. The other half is a comment that gets it fixed, by a colleague
who is busy and believes the change is fine. **A comment that works says what happens, shows it,
proposes a way out and says how much it matters.** One that only says *"insecure"* starts an
argument instead.

### Four parts

| part | what it does | for finding 1 |
|---|---|---|
| **what happens** | a concrete consequence, in one sentence | "Any signed-in patient can read any message by changing the number in the address." |
| **the evidence** | the line, and how to see it | "`read_message` never compares `MESSAGES[number]['patient']` with `patient()`." |
| **a way out** | a fix, or the test that would pin it | "Answer 404 when it is not the caller's, like the cancel route does, and add a test that lucia cannot read message 2." |
| **how much it matters** | blocking, or not | "Blocking: it exposes other patients' messages." |

Written that way, the comment can be acted on without a meeting, and the author can disagree with
something specific.

### Ask about intentions, state facts

Some findings are certain and some depend on what the author meant. "This exposes other patients'
messages" is a fact about the code; say it plainly. "Was the `patient` field in the form meant for
staff sending on someone's behalf?" is a question about intention; ask it. If the answer is yes,
the fix is different (a staff route with its own check) and the comment saved a wrong fix.

### Say what is blocking, and keep it short

A review with twenty comments of equal weight hides the two that matter. Mark the ones that must
change before merging, and label the rest as suggestions. Finding 1 blocks; the duplicate message
number is a suggestion. **The author reads blocking comments first**, and so should a reviewer
deciding whether to approve.

### Approving is a statement

"Looks good to me" on a change with a route that reads other people's data is a statement the
reviewer made, not only the author. Approve what you read, say what you did not read ("I did not
check the template changes"), and leave the change unapproved if a blocking finding is open.
