---
title: An inventory of the entry points
version: 1
---

A threat model starts as a list. For Tarefa's assistant it is `data/surface.json`, written by the
course: one entry per place where text comes in or goes out, with three facts about each.

```
ana@lab:~/guard$ head -15 data/surface.json
[
 {
  "id": "client-chat",
  "what": "a client's message in the chat",
  "enters": "prompt",
  "trusted": false,
  "controls": [
   "guard check-in",
   "guard moderate"
  ],
  "lessons": [
   19,
   16
  ]
 },
ana@lab:~/guard$ guard surface
entry point     goes to  trusted?           controls in the lab
client-chat     prompt   no                 guard check-in, guard moderate
helpdesk        prompt   written by Tarefa  guard ground
ticket-text     prompt   no                 guard minimise
uploaded-files  prompt   no                 NONE
system-prompt   prompt   written by Tarefa  canary in guard filter
model-reply     screen   no                 guard check-out, guard filter
tool-calls      tools    no                 guard gate
partner-api     prompt   no                 guard onboard, guard drift, guard ratelimit
call-log        storage  Tarefa's own       guard redact, guard sweep
provider        outside  by contract        guard minimise, guard enduser
10 entry points, 1 with no control in this lab
```

Read the columns as three questions:

- **goes to** is what the text reaches: the prompt, the screen, the tools, storage, or outside Tarefa
  altogether. Text that goes to the tools is the most dangerous, because it becomes an action.
- **trusted?** is who wrote it. Only two entries are trusted outright, the system prompt and the help
  centre, both written by Tarefa. The log is Tarefa's own and the provider is trusted by contract,
  which lesson 12 said is a trust with conditions.
- **controls in the lab** names the commands from this course that cover the entry. Every one of them
  was built in a lesson, and the lesson numbers are in the file.

The list is short because Tarefa's assistant is small. A larger application has more rows, not more
columns: each new feature adds an entry point, and **a feature is not finished until its row is
written**, with its trust and its control. A row added after an incident is a row somebody found the
hard way.

## Two rows worth reading closely

`model-reply` is marked untrusted, though Tarefa runs the model. The model's output is shaped by every
untrusted input that reached it, so it inherits their trust level. That is why lesson 9 checks every
reply against a schema and lesson 5 filters it before a client sees it.

`tool-calls` are untrusted for the same reason, and they go to the tools. A proposal is text the model
wrote after reading things nobody at Tarefa wrote, so it is checked like any other untrusted input,
by the gate of lesson 10, before it becomes an effect.
