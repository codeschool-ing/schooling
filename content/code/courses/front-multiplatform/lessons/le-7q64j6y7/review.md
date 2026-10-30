---
title: Before you call it done
version: 1
---

**Check your project against the list below before you show it to anybody.** Each line is a lesson of this
course, and each is something a reviewer, a store or a stranger with a download would find.

| check | lesson |
|---|---|
| the app runs on the platform, built from a tagged commit, and the tag is pushed | 15 |
| the decision note answers its four questions, and names what was not built | 10, 16 |
| at least one device or desktop feature, behind a check that it exists, as `device.ts` does | 4, 11, 12 |
| no `server.url`, no `cleartext`, no development address in what ships | 2, 13 |
| the icon is the app's own, in every size the platform asks for | 13 |
| the package carries only the app's files | 13 |
| the permissions asked for are the ones the app uses | 4 |
| no key, keystore or password in the repository, and `git check-ignore` proves it | 14 |
| the version is one number, moved by one command, with a build number that only grows | 15 |
| a second release, and the first one finds it, or the store shows it | 15 |
| `SHA256SUMS`, its signature and the public key are beside the packages, and verify | 14, 16 |
| the README says what it is, shows it, says how to install and check it, and how it was made | 16 |
| the keyboard and the screen reader still work in the app, as they did in the browser | 6 |

**Two of these are worth doing twice.** Verify the download as a stranger would, in a new folder, as the
previous section did; and install the app on a computer or a phone that never had it, from the release page,
following only your README. That last step finds the missing line in an install guide faster than any reading
of it.

**And know what the project does not prove.** A release that works on your machine has been tested on one
machine. Say which systems and versions you tried in the notes, as this course said what its recording
machine could and could not run, and the reader can judge the rest.
