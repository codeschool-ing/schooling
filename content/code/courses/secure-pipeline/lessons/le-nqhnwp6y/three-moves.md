---
title: Three moves, and when each is right
version: 1
---

Lesson 5 treated a dependency as a list of advisories: a scanner names a package and a version, and
the fix is the version the advisory says is fixed. That handles the finding in front of you. It
does not answer the question that decides most of a service's risk over a year: **what do we do with
this dependency from now on?** There are three moves, and each is right in a different situation.

| move | what it is | right when |
|---|---|---|
| **update** | take a newer version, deliberately, with its changelog read and the tests run | the project is healthy and the new version is what the maintainers support |
| **pin** | fix the exact version and the hash of every file, and change it only on purpose | always, as the base every other move starts from |
| **replace** | stop depending on it, for another package or for code of your own | the project has stopped fixing what matters to you |

**Pinning is not an alternative to updating; it is what makes an update a decision.** A service whose
dependencies float picks up whatever was published last night, in production, with nobody having
read a word of it. A service that pins updates when somebody chooses to, and the pipeline's checks
run on the change. The rest of this lesson does all three to linkbox: the pin with hashes, an update
of gunicorn across four major versions, and an argued replacement.

@@FIGURE moves@@

### Reading a package's health

Before choosing a move, look at the package as a project rather than as a version number. Four
questions, each with a place to read the answer:

- **Is it maintained?** The release history: how recently, how regularly, and whether old majors
  still get fixes.
- **Who maintains it?** The repository's recent commits: one person or many, and whether the people
  who wrote it are still the ones merging.
- **What does it pull in?** Its own dependencies, which are yours too.
- **What is open against it?** Advisories with no fixed version, and the maintainers' answer to them.

How many other projects depend on it matters as well, because a package with many dependants is
watched by many eyes and is also a bigger prize. Services such as deps.dev and libraries.io answer
that question; neither could be reached from the recording machine, so it is named here and not shown.

### What linkbox actually depends on

`requirements.txt` from lesson 5 names eight packages, and two of them are what linkbox asked for.
`uv pip tree` shows who pulls in what, in the virtual environment built from those pins:

@@CAPTURE tree@@

Two trees. Flask brings six packages, and **gunicorn brings `packaging`**, which is the package lesson
13's bill of materials found in the image although no requirements file ever named it. It got there
because gunicorn 22 declares it as a dependency, and lesson 5's flat list of pins could not say so.

### gunicorn as a project

PyPI answers the first question for any package with a JSON document. The last twelve releases of
gunicorn, by the date their first file was uploaded:

@@CAPTURE gunicorn-releases@@

Four major versions since the 22 that linkbox pins, the most recent in August, and regular minor
releases in between. That is a project moving, which is good news for its health and a cost for
whoever stays behind: **the further a pin falls behind, the larger the jump when an advisory forces
it.** The second command lists what each version requires outside its optional extras. gunicorn 22
requires `packaging` outright; gunicorn 26 requires nothing at all, and names `packaging` only under
extras linkbox does not install.

So an update of gunicorn would take one package out of the image as well as moving the server
forward four majors. That is a decision with a changelog to read, and a later section of this lesson
makes it. First the pins need to become something an update can be measured against.
