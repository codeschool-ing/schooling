---
title: A boundary this repository already draws
version: 1
---

The platform this course is published on is run by two people, and its rules for them, in its `CLAUDE.md`, are a worked example of the three questions. Three of them, in the words of that file:

> **Staff is a role on an account, not a second account.** [...] Three roles, totally ordered — `owner` > `operator` > `read-only` — because a permission matrix is a screen nobody can hold in their head.

> **Mandatory MFA is enforced on the SESSION, not on the account.** [...] **Revoking a role ends every session that held it**, because otherwise removing access is only scheduling it.

> **Every administrative write records the actor.** Two people operate this.

Each answers one of the questions. The ordered roles answer *what may this person do*, in a form small enough to reason about. Checking the second factor on every request, at the door, answers *what if a password is all an attacker has*. And the audit answers *what happens when somebody is wrong*: there is a record of who did it.

The audit is the part an agent needs most, and the package that implements it, `internal/audit`, makes the actor impossible to leave out. An entry's actor can only be built by one of two constructors:

```go
// Actor is who took the action. Unexported fields, and two constructors: an
// entry cannot be assembled with the actor left out, because there is no way to
// write one down that does not name somebody.
type Actor struct {
	id    uuid.UUID
	kind  string
	label string
}

// Staff is a person. The label is their name AT THE TIME, copied in rather than
// joined later: people are renamed and people leave, and an entry that reads
// "changed a plan, actor 9f2c…" a year afterwards is not an answer.
func Staff(id uuid.UUID, label string) Actor {
	return Actor{id: id, kind: KindStaff, label: label}
}

// System is the platform acting on its own — a scheduled job, a webhook, a
// retry. It is a real actor and not an absent one, which is precisely why it
// has a name of its own rather than an empty column.
func System(label string) Actor {
	return Actor{id: systemActor, kind: KindSystem, label: label}
}
```

An agent acting for a business is a third kind of actor: neither a person nor a scheduled job, and it should be named as itself in every record of what it did. The rest of this lesson builds a host that does that, and draws the agent's boundary the way this file draws the staff's.
