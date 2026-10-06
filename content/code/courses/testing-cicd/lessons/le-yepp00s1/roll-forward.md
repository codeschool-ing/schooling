---
title: Rolling back or rolling forward
version: 1
---

When a release misbehaves there are two ways out. **Rolling back** returns to the release before.
**Rolling forward** fixes the problem and ships a new release. Version 1.6.1 was a roll forward from
1.6.0: a one-character change, `range(40, 57)` to `range(40, 58)`, released as a new version.

## Roll back first, as a default

- It takes seconds, and the release it returns to is known to work: it ran in production until a
  few minutes ago.
- It stops the damage while the cause is still unknown. A fix written under pressure, without
  knowing the cause, is a guess, and a wrong guess shipped at speed is a second incident.
- It turns the incident into an ordinary bug: the fix can then be written, reviewed and tested the
  usual way, and shipped through the usual pipeline.

## When rolling forward is the better choice

- **The release before is also broken.** If the bug was introduced three releases ago and noticed
  only now, going back one release does nothing.
- **Going back would undo something that cannot be undone safely**, such as a migration the old
  release cannot read. The next section is about those.
- **The fix is small, understood and fast to ship**, and the pipeline is fast enough that the fix
  reaches production as quickly as a rollback would. For a one-line fix and a pipeline of a few
  minutes, this can be true.
- **A flag can turn the feature off.** That is neither rollback nor roll forward: the release stays,
  the feature leaves. If the new code is behind a flag, this is usually the quickest way out of all.

The choice should not be made by the person who wrote the change, in the moment, out of pride. A
team that agrees in advance that the default is "roll back first, investigate second" removes that
argument from every incident.
