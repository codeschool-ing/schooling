---
title: Refusals that help, and confirmations that can be read
version: 1
---

The other two failures in the draft are about moments when the assistant stops: a refusal, and a
confirmation before an action.

## A refusal says why and what next

`refusal-budget` is the screen a client sees when lesson 18's budget runs out. It says *something
went wrong, please try again* and offers one button, `retry`. Each half is wrong in its own way:

- **"something went wrong" hides a decision behind an error.** Nothing went wrong; a limit Tarefa set
  was reached. A client told it is a fault waits for it to be fixed, or reports a bug.
- **"try again" against a limit is the loop of lesson 18**, now driven by a person pressing a button.
  The retry cannot succeed until tomorrow, and every press costs a refusal.

`refusal-scope`, by contrast, passed: it says what the assistant can do, that something else is
outside it, who can help instead and how soon. **A refusal that names the next step turns a dead end
into a route.** It does not have to give the reason in detail, and a refusal triggered by a safety
filter should not describe the filter, but it always says what the client can do now.

## A confirmation shows the action

`confirm-refund` says *the assistant wants to issue a refund. Allow?* Lesson 10 held the refund for
a person precisely so that somebody would check it, and **a person can only check what the screen
shows**. Without the account, the job and the amount, "Allow?" asks for trust, and the person
confirming is a click in the path rather than a check on it. The rule takes the arguments of the
tool and refuses a confirmation that shows fewer.

## The draft, corrected

A second version of the same six screens, also written by the course, rewrites each failing one. The
welcome says it is automated, every reply can be reported, the budget refusal says the assistant
cannot answer more today and offers a person, and the confirmation shows the account, the job and
the amount. Paste it:

```sh
cat > ~/guard/data/ui-copy-fixed.json <<'EOF'
[
 {"id": "chat-welcome", "kind": "chat",
  "text": "Hi! I'm Tarefa's automated assistant. I can help with your jobs, payments and account, and a person on our team is one click away.",
  "actions": ["talk-to-a-person"]},
 {"id": "reply", "kind": "reply",
  "text": "{reply}",
  "actions": ["copy", "report"]},
 {"id": "refusal-budget", "kind": "refusal",
  "text": "I cannot answer more questions today. A person on our team can help now, or I will be back tomorrow at 00:00.",
  "actions": ["talk-to-a-person"]},
 {"id": "refusal-scope", "kind": "refusal",
  "text": "I can only help with jobs, payments and accounts on Tarefa. For anything else, a person on our team can help: they reply within one business day.",
  "actions": ["talk-to-a-person"]},
 {"id": "confirm-refund", "kind": "confirm", "tool": "issue_refund",
  "text": "Refund {cents} to account {account} for job {job}, the amount paid. This cannot be undone.",
  "shows": ["account", "job", "cents"],
  "actions": ["allow", "cancel"]},
 {"id": "memory-panel", "kind": "memory",
  "text": "What the assistant remembers about you, and until when.",
  "actions": ["delete-one", "delete-all"]}
]
EOF
```

```
ana@lab:~/guard$ guard uxcheck data/ui-copy-fixed.json; echo "exit status $?"
chat-welcome    chat     ok
reply           reply    ok
refusal-budget  refusal  ok
refusal-scope   refusal  ok
confirm-refund  confirm  ok
memory-panel    memory   ok
6 screens, 0 breaking a rule
exit status 0
```

Every screen passes and the exit status is 0, so the same check can run in the build and fail the
pull request that drops the word *automated* from the welcome. What it cannot judge is whether the
words are kind, clear and in the client's language; that review is a person's, with the screen in
front of them.
