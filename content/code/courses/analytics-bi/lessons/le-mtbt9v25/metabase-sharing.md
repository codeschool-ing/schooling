---
title: Collections, permissions and links
version: 1
---

A question that only its author can find is a draft. Metabase organises saved work into
**collections**, which are folders: a personal collection per person, and shared collections for
teams. Somebody finding Lantern's revenue questions should find them in one shared collection with a
name, not in eleven personal ones.

Who may see what is decided in the admin settings, under **Permissions**, by **groups** of people,
and it has two layers that are easy to confuse:

- **data permissions** decide which databases, schemas and tables a group may query at all, and
  whether it may write SQL or only use the editor;
- **collection permissions** decide which saved questions and dashboards a group may open or edit.

The two combine. A group with access to a collection but not to the data behind a question opens the
question and is refused its result. Lantern's arrangement from lesson 3 helps here: Metabase reaches
the database through a role that reads only the layer, so even the most generous data permission
inside Metabase stops at `semantic`.

## Public links

Metabase can share a question or a dashboard through a **public link**: an address anybody can open
without logging in. In the version this course runs, public sharing is **enabled on a fresh
installation**, as its settings showed when this course was recorded; an administrator can turn it
off in the admin settings, and on a Metabase holding customers' data that is the first thing to do.
Treat a public link as publishing: whoever has the link sees the data, the link travels in e-mails
and chat, and revoking it later does not unsee what was seen. For anything with customers' data in
it, the answer is no.

Dashboards — several questions on one page, with filters that drive them together — are Metabase's
other kind of saved work, and lesson 6 is about building one well.
