---
title: Rolling back, and the one thing it cannot undo
version: 1
---

A rollback in blue/green moves the production listener back to the blue target group, and it happens
three ways: **an alarm in the group goes into `ALARM`**, the deployment fails on its own (a hook
reports failure, green never becomes healthy), or **a person stops it** with `stop-deployment
--auto-rollback-enabled`. In each case the traffic returns to tasks that were serving a few minutes
earlier and never stopped. None of this was run here; moto runs no deployment.

That speed is real, and it covers less than people assume. **A rollback moves traffic. It does not
move data.** Whatever 1.4.1 wrote while it served stays written, and 1.4.0 has to be able to read it.

## The database is the hard part

The common case is a schema change. Release 1.4.1 renames the column `customer_name` to `name` in the
same deployment that starts using it. The canary goes out, the alarm fires, the traffic moves back to
1.4.0, and 1.4.0 asks for `customer_name`, which no longer exists. **The rollback worked and the
service is down**, now in both versions.

The way out is to never ship a change the previous version cannot survive. A rename becomes three
releases, called **expand and contract**:

1. **expand**: add the new column, and write to both; old code ignores the new column;
2. **migrate**: copy the old values across, and switch reads to the new column;
3. **contract**: once no running version reads the old column, drop it.

At every step, the version before can still run against the database as it now is, so every step
can be rolled back. The same rule covers messages on a queue, files in a bucket and the shape of an
API response: **a release has to accept what the previous release produces, and produce what the
previous release accepts**.

## Configuration is part of the version

A rollback restores the old task definition, which names the old image, which is the reason lesson 2
made the tags immutable. It does not restore a parameter in Parameter Store, a secret's new value or a
feature flag somebody switched at the same time. **What changes with a release should travel inside
it**, in the task definition, or be changed in a separate step that can be reverted on its own.

## After a rollback

The rollback ends the incident's first phase and starts its second: finding out what went wrong while
the old version carries the traffic. The deployment's own record keeps which alarm stopped it and at
what share, and that record is the first line of the timeline lesson 13 builds.
