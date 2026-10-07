---
title: Requirements in the backlog
version: 1
---

A requirement in a CSV file is a promise. **It becomes work when it reaches the place the team
plans work from**, and that place is the backlog, with the same priority rules as every other item
on it. Security requirements that live in a separate document get done in a separate time, which
in practice means after everything else.

### Three shapes a requirement takes there

| shape | when it fits | at Vereda |
|---|---|---|
| **a story of its own** | the requirement is a feature somebody will use | R17, patients see and end their open sessions |
| **acceptance criteria on an existing story** | the requirement constrains a feature being built anyway | R13 on the story that redesigns the upload page |
| **a rule in the definition of done** | the requirement applies to every story of a kind | R10's ownership check, for every story that returns a patient's data |

The third shape is the most powerful and the least used. A rule in the definition of done is
checked on every story without anybody having to remember the threat behind it: "any new endpoint
that returns patient data checks that the data belongs to the signed-in patient, and has a test
that asks for somebody else's."

### Keeping the thread

Each backlog item carries the requirement's id, and the requirement carries the threat's. That is
all the thread needs. When daniel asks why a story about phone numbers is above a story about the
booking calendar, the answer is R19, which answers T17, which is the abuse case where a former
partner takes over a patient's account. A priority with a reason behind it survives the planning
meeting better than one without.

### Who decides the order

The product owner orders the backlog, and security items are no exception. What the threat model
contributes is the information to order them well: which objective each threat endangers, from
PASTA's stage 1, and how large the risk is, which lessons 9 to 11 put numbers on. A security
person who wants a requirement done first should be able to say why in those terms. If they cannot,
the order the product owner chose is probably right.
