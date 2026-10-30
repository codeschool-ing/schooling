---
title: The night it fails
version: 1
---

**A pipeline is judged by its worst night, and Data Factory's part in that night is to fail
visibly.** This section is taught from Microsoft's documentation and was not run.

## What a failure looks like

**Every run of a pipeline, and every activity inside it, is recorded with its status, its inputs, its
outputs and its error**, and the portal's monitoring view shows them. Microsoft documents that the
factory keeps this history for 45 days; a team that needs longer, or wants to query it, sends it to a
Log Analytics workspace through the factory's diagnostic settings, which is `azure-operations`
territory. For Quitanda's copy, the error of a failed run says which side failed, source or sink, and
why: the file was not there, the identity was refused, the CSV had a row with eleven fields where the
dataset expected ten.

**A failure nobody hears about is the same as no load.** Data Factory can raise an alert through Azure
Monitor when a pipeline run fails, and the alert reaches a phone through an action group. A factory
without one has a monitoring view that shows the red row to whoever opens it, and the first person to
open it is usually the analyst who found yesterday missing from a dashboard.

## The three ways out

**Retry, in the activity's policy**, for what passes on its own: a network blip, a database that was
busy. The pipeline in the fourth section retries its copy twice, five minutes apart.

**Rerun, by hand or by the trigger**, once the cause is fixed. Data Factory can rerun a pipeline from
the activity that failed, keeping what succeeded before it, and a tumbling window can rerun one
window. Either way the pipeline runs a second time for the same day.

**Branch, in the pipeline**: an activity's arrows can say "on failure", so that a pipeline sends its
own message or writes its own row to a log table when a step fails, with the error in it.

## Safe to run twice

**A rerun is only safe if running the pipeline twice for the same day gives the same result as running
it once.** The copy in this lesson writes the day's Parquet into `orders/dt=<day>/`; if it replaces
what is there, a rerun after a half-finished night leaves one copy of the day, and if it adds files
beside what is there, a rerun leaves the day twice. Data Factory does not choose for you. For a Delta
table, lesson 18's commits make the choice explicit: an overwrite of one day's partition is one commit
that removes the old files and adds the new, and readers see either the old day or the new one.

Every trigger in the previous section reruns windows, every activity retries, and a person reruns
nights; a pipeline that is not safe to run twice turns each of those into a duplicate in the lake.
Lesson 24 gives the property its name and its consequences for streams.
