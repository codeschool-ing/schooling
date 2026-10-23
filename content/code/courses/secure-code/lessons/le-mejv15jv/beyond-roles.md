---
title: What roles do not answer
version: 1
---

A role answers *may this kind of person do this kind of thing?* Three questions are left over, and
each is a common place for access control to break after the roles are right.

### Which record?

carla may read clinical notes. May she read **every** patient's? In a chain of four clinics, a
physiotherapist sees the patients of her own clinic, or her own agenda. The route
`/patients/<name>/notes` takes the patient from the address, and the decorator never looks at it.
**A role check plus an ownership check** is the shape of most real rules, and the ownership half is
the one forgotten more often, because the role check makes the route look protected. Lesson 13 is
about exactly that, from the patient's side.

### Which way through?

Every way in needs the same check. A route that reads notes as HTML and another that returns them
as JSON for the mobile app are two routes; an export, a search and a "recent activity" panel each
show notes too. **Data leaks out of the side door**: the notes route is locked and the search results
quote the first line of every note. The deny-by-default test catches a route with no rule; it
cannot catch a route whose rule is too generous. Review each new way to the same data against the
table in the last section.

### Who changed what?

The most sensitive routes are the ones that change who may do what: granting a role, resetting
someone's password, disabling an account. Three habits apply to them beyond the role check.

- **Record the actor.** Every administrative change writes who made it, when, and what changed, in a
  log nobody can edit. Lesson 15 lists it among the security events worth a line.
- **End the sessions it affects.** A role removed from bruno takes effect now, not when his
  session expires, as lesson 10 said.
- **Refuse the change to yourself** where it matters. An administrator who can grant themselves any
  role has every role; a second person approving the grant is the usual answer in a team large
  enough to have one.

### Where checks go wrong in frameworks

Flask leaves checks to you, which is why this lesson could show them as plain code. Larger frameworks
offer permission systems, and the same three rules apply to them. The most common failure is a
permission system configured for the views and not for an API added later beside them, or for the
admin panel switched on by default. **Whatever the framework, the test of the fourth section is
portable**: list every route the application serves, and fail on any that does not declare who may
use it.
