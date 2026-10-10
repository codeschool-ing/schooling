---
title: Jira, and the Atlassian products around it
version: 1
---

**Jira is the tracker a tester is most likely to meet in a software company**, and one that
job advertisements for testers name often. It is made by Atlassian, an Australian company, and sold
both as a hosted service and as software a company runs on its own servers. It was not run for
this course, and this section describes what kind of tool it is rather than where its buttons are.

## How Jira holds a defect

Work in Jira lives in **projects**, and every issue gets a key made of the project's short name and
a number: if the theatre's project were called BOX, the traceback report of lesson 15 might be
`BOX-42`. That key is what everybody types, in a commit message, in a chat, in a test case, and
Jira turns it into a link.

Each issue has an **issue type**, and a software project usually has at least *bug*, *story*,
*task* and *epic*. A defect is a bug. Its fields include a summary, a description, priority,
environment, attachments, labels, the components of the product it touches, and the versions it
affects and is fixed in. An administrator can add custom fields, and **severity is the usual
one**: Jira's own priority field is there from the start, and
a severity field is something each team adds and defines. A team that does not add it ends up
writing severity into the priority, which is the one confusion lesson 15 spent a section untangling.

**Workflows** are configured per project, by an administrator: the states, the transitions between
them, who may make each one, and what must be filled in on the way. That is where a team writes
lesson 16's rules into the tool. For example, *only the reporter or a tester can move an issue from
ready for retest to closed*, or *a rejected issue must carry a resolution saying why*. A team that
never touches the workflow is using somebody else's lifecycle.

Jira's search has its own query language, JQL, which reads like a sentence of conditions. A search
for boxoffice's open defects, most urgent first, looks like
`project = BOX AND issuetype = Bug AND status != Closed ORDER BY priority DESC`. The query was not
run here, and the field and state names in a real project are whatever its administrator called
them. A saved query becomes a **filter**, and filters feed the **boards** and **dashboards**
where the numbers of lesson 16 are drawn.

## The rest of Atlassian, where a tester meets it

Atlassian sells several products that are often bought together, and three of them reach a
tester's day.

**Confluence** is the company's wiki: pages, edited in the browser, linked to each other and to Jira
issues. Test plans like lesson 1's, requirements like boxoffice's R1 to R9, and the notes of an
exploratory session often live there, with a link from each defect back to the requirement it
breaks.

**Bitbucket** hosts code. When a developer's commit message carries an issue key, the issue shows
the commit, which lets a tester retesting `BOX-42` see exactly what changed.

**Jira Service Management** handles requests from people outside the team, such as customers or
staff writing to a help desk. A request that turns out to be a defect is linked to, or turned into,
a bug in the software project. For a tester that is the front door of the *escaped defects* lesson
16 counted.

**Trello**, a much simpler board tool, also belongs to Atlassian, and section 03 of this lesson
treats it on its own terms.

Jira is also a platform: other companies sell add-ons that run inside it, and several test-case
tools work that way. Lesson 18 names one of them, Zephyr.
