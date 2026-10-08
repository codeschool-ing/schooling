---
title: Closing an incident
version: 2
---

An incident ends when **users are no longer affected and the system is stable**, not when the cause is
understood. Those are often hours or days apart, and keeping the incident open until the cause is
known holds people in a response mode that no longer helps anybody.

What closing involves:

- **A condition, checked.** The page resolved, the burn rate is back under 1, and the error ratio is
  where it was before. Each is a number, and the IC reads them out before declaring the end.
- **A last update**, in the same shape as the others, saying it is over, what users should know, and
  that a review will follow.
- **The follow-ups written down, with owners.** During the response, people say *we should* many
  times: add an alert, fix the retry, document the rollback. Each becomes a ticket before the channel
  goes quiet, because by the next morning nobody remembers half of them.
- **A postmortem scheduled**, for any SEV-1 or SEV-2, and for a SEV-3 that taught something. Lesson 18
  is about writing it.

One more decision belongs at the close: **whether the fix that ended the incident can stay.** A
rollback is safe; a hand-edited configuration, a scaled-up cluster or a disabled feature is a
temporary state that somebody has to undo or make permanent, and it needs an owner like any other
follow-up.

Before the next lesson, take lesson 16's rules and override away again:

```sh
rm prometheus/rules/burn.yml compose.override.yaml
curl -s -X POST localhost:9090/-/reload
docker compose up -d alertmanager
```
