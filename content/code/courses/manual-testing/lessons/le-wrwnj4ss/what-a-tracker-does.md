---
title: What any tracker does
version: 1
---

This lesson names four products, and none of them was run for this course. That is deliberate:
products change their screens every year, and **what a tracker does has not changed in twenty**.
A tester who understands the five things below can sit down at any of the four, or at whatever a
new employer uses, and be useful by lunchtime. A tester who learnt one product's buttons has to
start again.

The common mistake is to think the tool is the process: that installing Jira gives a team a defect
lifecycle. It gives them a default one, written by somebody who has never seen their product. The
lifecycle of lesson 16 is a decision the team makes; the tracker is where it is written down and
enforced.

## The five things

**An issue.** One record per thing to be done or decided: a defect, a feature, a task. It gets an
id the moment it is created, and that id is how everybody refers to it from then on, in a commit
message, a chat, a test case. Lesson 15's report becomes one issue. An id is also why one defect
per report matters: two defects in one issue share one id, one state and one history, and cannot be
closed separately.

**Fields.** The structured parts of an issue: a summary, a description, a priority, a state, the
person it is assigned to, the version it was found in, labels, attachments. Some fields come with
the product; most trackers let an administrator add more. **Which fields exist decides what the
team can search for and count**, so a severity that lives only in the description's prose cannot be
used to list every open critical defect.

**A workflow.** The states an issue can be in and the moves allowed between them, which is lesson
16's figure turned into configuration. A strict workflow refuses a move it does not allow: an issue
cannot jump from *new* to *closed* without passing through the states between. A loose one lets
anybody drag anything anywhere, and relies on the team's habits instead.

**A board.** The workflow drawn as columns, one per state, with an issue as a card in the column it
is in. A board answers *what is happening right now* at a glance: three cards in *ready for retest*
is three things waiting for the tester.

**Search.** A way to ask for every issue that matches some conditions, and to save the question:
*every open defect in boxoffice with severity critical, oldest first*. Saved searches are where the
numbers of lesson 16 come from. The age of open critical defects is a search and a date; the reopen
rate is two searches and a division.

## And what comes with them

Every tracker in this lesson also keeps **a history** of each issue, who changed which field and
when, which is what lets a reopened defect carry its past. It **notifies** the people involved when
something changes. It **links** issues to each other, so a duplicate points at its original and a
regression points at the change that caused it. And it **restricts who can see an issue**, which
is where lesson 15's security report goes.

None of this is specific to defects. The same tracker usually holds the team's features and tasks
too, and a defect is one **issue type** among several. That matters to a tester in one way: a
defect filed as a task, or a task filed as a defect, disappears from the searches built for the
other, and the counts of lesson 16 are wrong without anybody noticing.
