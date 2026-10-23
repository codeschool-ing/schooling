---
title: Why the design system becomes a package
version: 1
---

**The day a second product needs the planner's tokens and components, they have to live somewhere both
can depend on, with a version that says which state of them each one has.** Until that day, a design
system inside its one product is fine. After it, there are three ways to share it, and only one of them
keeps it one design system.

## Three ways to share

| | how | what happens in a year |
|---|---|---|
| **copy** the folder into the second app | `cp -r` | two design systems that started equal; a fix in one never reaches the other |
| **a monorepo**, with both apps and the library in one repository | npm workspaces link the library into each app | every app always uses the library's latest commit, and a change to it is tested against all of them at once |
| **a published package** with a version | the library is published to a registry; each app installs a version | each app moves to a new version when it chooses, and the version says what changed |

**Copying is the default and the trap.** It costs nothing on the first day, and every day after it costs
a little, invisibly, until two buttons that were meant to be the same are not.

**A monorepo** is a strong choice when one team owns every app: a change to a component is a single pull
request that updates the library and every screen that uses it, and CI tests them together. npm supports
it with **workspaces**, a `workspaces` list in the root `package.json` that links each package into the
others' `node_modules`. Its cost is that every app is always on the newest library, whether it was ready
or not.

**A published package** is what this lesson builds, and what most organisations with several teams end up
with: the library has its own repository and its own releases, and each product upgrades on its own
schedule. The price is the subject of the rest of the lesson: versions that mean something, a registry to
publish to, and the discipline of saying what each release changed.

## The second product

Imagine the school behind the planner wants a second app, for teachers, with the same look. That is the
case this lesson serves: the tokens, the type scale, the themes and the three components move into a
package called `@planner/ui`, the planner installs it like any other dependency, and the teachers' app
could install the same version tomorrow.
