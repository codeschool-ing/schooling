---
title: A shared vocabulary, not a checklist
version: 1
---

OWASP, the Open Worldwide Application Security Project, is a community that documents how software
fails and publishes its findings openly. Its best known list is the Top 10 for web applications.
Since 2023 it has published a separate **Top 10 for LLM Applications**, and the current edition, the
one this lesson uses, is from 2025.

The list is easy to misuse in two opposite ways.

**As a checklist.** A team reads the ten names, confirms that each sounds like something they have
thought about, and marks the application as covered. The list does not support that. Each entry
describes a family of failures, and whether an application is exposed depends on what it does: an
assistant with no tools has little to fear from *excessive agency* and a great deal from *misinformation*.

**As trivia.** A course or an interview asks which number a category has. The numbers order the
entries roughly by how often and how badly they occur, they changed between the 2023 and 2025
editions, and they will change again.

What the list is good for is **a vocabulary**. When a reviewer writes *improper output handling*
beside a pull request, everyone who has read the list pictures the same thing: a model's reply used by
other code without being checked. A shared name turns a vague worry into a question that can be asked
of a specific feature, and that is how this course uses it.

Every entry is a failure this course has already met, under a name of its own. The next section puts
the two names side by side.
