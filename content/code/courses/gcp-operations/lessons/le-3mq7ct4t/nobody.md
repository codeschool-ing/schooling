---
title: The resource nobody owns
version: 1
---

**Every bill has a remainder that belongs to no team, and it is where the waste is.** A resource with an owner gets
looked at, because somebody's budget pays for it. A resource with no label gets looked at by nobody, and keeps being
billed. The shop's 22.4% is that remainder, and the export says exactly what is in it:

```
ana@laptop:~/gcp$ python3 q.py "SELECT project_id, service, resource_name, round(sum(cost), 2) FROM export WHERE label_team IS NULL GROUP BY 1, 2, 3 ORDER BY 4 DESC"
planner-prod	Compute Engine	old-migration	43.49
planner-prod	Cloud Logging	_Default	38.17
planner-dev	Compute Engine	sandbox-ana	32.94
planner-prod	Compute Engine	disk-restore-test	25.26
```

Four lines, and each is a different kind of nobody:

- **`old-migration`**, 43.49 USD: lesson 22's idle machine. Created by hand for a one-off migration, never labelled,
  never deleted. The four-step deletion of lesson 22 is the answer, and the audit log entry that created it is how to
  find the person to ask.
- **`_Default`**, 38.17 USD: Cloud Logging's default bucket. Nobody labels a log bucket, and its cost is the sum of
  everybody's logging. It is attributed by reading lesson 9's sinks: routing each team's logs to a bucket of its own
  makes each bucket's cost that team's.
- **`sandbox-ana`**, 32.94 USD: a person's sandbox, in the `sandbox` folder. It has an owner, by name, and no label.
  Labelling it `team=ana` would at least make it visible; a monthly budget on the sandbox folder (lesson 24) keeps it
  honest.
- **`disk-restore-test`**, 25.26 USD: a disk left behind by a restore rehearsal. Nobody's machine uses it; lesson 22's
  idle-disk recommender would find it, and the snapshot-then-delete procedure removes it.

Two of the four are waste (the idle machine and the forgotten disk, 68.75 USD a month), one is shared infrastructure
to be split, and one is a person's experiment. **The remainder is not one problem; it is a list, and the list is what
a monthly review reads.**

## Keeping the remainder small

- **Labels at creation, not later.** Terraform's `default_labels` (lesson 5) label everything it creates; resources made
  by hand are where labels go missing, which is one more reason to make them in Terraform.
- **A check that refuses an unlabelled resource.** No built-in organisation policy requires a label, but a pipeline can:
  a step that reads the Terraform plan and fails when a resource has no `team` is cheap, and catches the omission before
  apply.
- **Showback, monthly.** Each team receives the export's total for its label, with the remainder shown beside it as its
  own line. Nobody is charged; everybody sees. A team's number moving without explanation is a question asked within a
  month instead of a year.
