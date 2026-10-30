---
title: Format and filter
version: 1
---

**Every gcloud command that prints a resource can print it in any shape**, and every one that lists resources
can filter them. Both are flags common to all commands, `--format` and `--filter`, and they are what turns
gcloud from something read by a person into something read by a script. The emulator gives this section
something to list. Make four topics, three of them labelled with the team that owns them:

```
ana@laptop:~/gcp$ gcloud pubsub topics create orders invoices --labels=team=planner
Created topic [projects/planner-dev/topics/orders].
Created topic [projects/planner-dev/topics/invoices].
ana@laptop:~/gcp$ gcloud pubsub topics create metrics --labels=team=data
Created topic [projects/planner-dev/topics/metrics].
ana@laptop:~/gcp$ gcloud pubsub topics create scratch
Created topic [projects/planner-dev/topics/scratch].
```

## Format

The default for a list is a table of whatever the command's authors chose. `--format` chooses instead:

```
ana@laptop:~/gcp$ gcloud pubsub topics list --format="table(name.basename(), labels.team)"
NAME      TEAM
invoices  planner
metrics   data
orders    planner
scratch
```

`table(...)` names the columns, and each column is a **projection**: a field of the resource, `labels.team`,
or a field with a transform applied to it, `name.basename()`, which keeps what follows the last slash. A topic
with no label shows an empty cell rather than an error. The other shapes that matter:

| format | gives | for |
|---|---|---|
| `json`, `yaml` | the whole resource, as the API returned it | reading every field, or a program |
| `value(...)` | the projected fields, tab-separated, no header | a shell loop |
| `csv(...)` | the projected fields with a header | a spreadsheet |
| `table(...)` | aligned columns | a person |

`gcloud topic formats` lists them all, with the transforms.

## Filter

```
ana@laptop:~/gcp$ gcloud pubsub topics list --filter="labels.team=planner" --format="value(name)"
projects/planner-dev/topics/invoices
projects/planner-dev/topics/orders
```

**A filter is an expression over the same fields a format projects**: `labels.team=planner`,
`name:invoices` for *contains*, `NOT labels.team:*` for *has no team label*, joined with `AND` and `OR`.
gcloud sends what the API can filter on to the API, and applies the rest itself on what comes back, so a
filter always works and is not always cheap: against an API that cannot filter, the whole list is fetched
first.

The two together are how a script asks a precise question. The topics nobody has claimed:

```
ana@laptop:~/gcp$ gcloud pubsub topics list --filter="NOT labels.team:*" --format="value(name.basename())"
scratch
```

And the whole resource, the first one only, to see what fields there are to project and filter on:

```
ana@laptop:~/gcp$ gcloud pubsub topics list --format=json --limit=1
[
  {
    "labels": {
      "team": "planner"
    },
    "name": "projects/planner-dev/topics/invoices"
  }
]
```

**A script that parses gcloud's default table is a script that breaks** the day the table gains a column.
`--format=json` or `value(...)` is a contract the script chose; the default is a display somebody else did.
