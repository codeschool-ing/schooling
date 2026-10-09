---
title: The client can see it and delete it
version: 1
---

A memory is about a client, so the client has a say in it. Under the LGPD, lesson 12's subject, a
person may ask what data is held about them and have it corrected or deleted. For a memory that means
two things the application has to support from the first day: **showing the client what the assistant
remembers, in plain words, and deleting any line of it on request.**

`show` is the first already, since it prints what the assistant would use. `forget` is the second:

```
ana@lab:~/guard$ guard memory forget m4 --as ac-7Q2M
forgot m4 for ac-7Q2M
ana@lab:~/guard$ guard memory show --as ac-7Q2M --now 2026-07-01
ac-7Q2M on 2026-07-01, memories in use: 1
  m2  preference until 2027-03-02  dark blue logo color
ana@lab:~/guard$ guard memory forget m4 --as ac-7Q2M; echo "exit status $?"
memory: ac-7Q2M has no memory m4
exit status 1
```

The memory about weekly updates is gone, and asking to forget it again fails with a message and exit
status 1 rather than claiming a deletion that did not happen. A screen that says "forgotten" whatever
happened is a screen that lies on the day it matters.

## Forgetting reaches every copy

A memory is written in one place and copied to others. Deleting the line in the store does not remove:

- **the conversation it came from**, which sits in the call log of lesson 11 under that log's own
  retention;
- **prompts already sent with it**, which the provider keeps under the terms lesson 12 looked at;
- **anything derived from it**, such as a summary of the client written for staff.

An honest "forget" button says what it deletes and what it cannot. A request to erase everything
about a person is a different and larger operation, and the memory store is one of the places it has
to reach, which is a reason to keep the store simple enough to find a person in.

## A memory is text the client wrote

When the assistant recalls a memory, its text goes back into a prompt. **That text came from the
client's messages, through the model**, so in lesson 13's terms it carries client text, wherever it is
stored. It gets the treatment lesson 14 gave such text: short, in a closed shape, and read by a model
that answers rather than one that acts. The 120-character limit in the schema is part of that, and so
is the absence of any kind that holds an instruction. A memory says something about the client. It
never tells the assistant what to do.
