---
title: Rotation, and who actually changes the password
version: 1
---

**Rotation in Secret Manager is a reminder, not an action.** When `next_rotation_time` arrives, Secret Manager
publishes a message with the event type `SECRET_ROTATE` to the secret's topic, moves `next_rotation_time` forward
by `rotation_period`, and does nothing else. The password is unchanged until something subscribed to the topic
changes it. This section is from Google's documentation; nothing in it ran.

## The rotation job, step by step

The shop's job is a Cloud Run function subscribed to `shop-secret-rotation`. For the database password it does
four things, in an order chosen so that nothing breaks halfway:

1. **Create the new password in the database**, as a second credential for the same user, or as a new user with
   the same grants, while the old one still works.
2. **Add it as a new version** of `shop-db-password`. From now on, `latest` is the new password.
3. **Wait** until every instance has picked it up: the mounted file changes, and the API reconnects with the new
   value the next time a connection fails or is recycled.
4. **Revoke the old password** in the database, and **disable** the old version in Secret Manager. Destroy it a
   week later, once nothing has asked for it.

The order is the whole design. Revoking first (step 4 before step 2) breaks every running instance at once;
skipping the wait breaks the instances that have not reloaded. **Disable before destroy** for the same reason: a
disabled version that somebody still needed can be enabled again in seconds, and a destroyed one cannot.

## Access is audited

Every access to a version is recorded in Cloud Audit Logs as a data-access entry, once data-access logging is on
for Secret Manager: which account read which version, when. That is how "who read the database password last
month?" has an answer, and how a version that nobody has read in thirty days can be destroyed with confidence. A
log-based alert (lesson 10) on access by any account other than the API's own turns that record into a
notification.

## When a secret has leaked

A password found in a log, a repository or a chat is treated as known to everybody, whatever anybody thinks of
the chance. The steps are the rotation above, run now rather than on schedule: a new version, the instances
reloaded, the old password revoked in the database and its version disabled. Removing the password from where it
leaked comes after, and does not replace any of it: a repository's history, a log bucket's retention and a chat's
search keep copies long after the line is deleted.
