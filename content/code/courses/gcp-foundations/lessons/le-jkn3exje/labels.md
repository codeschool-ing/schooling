---
title: Labels, and why they are for counting
version: 1
---

**A label is a key and a value attached to a resource, and its job is to be counted.** `team=planner`
on a topic, `env=prod` on a project, `cost-centre=cc-1040` on a disk. Labels travel into the billing
export of lesson 14, where they answer the question every finance team asks first: whose is this? A
resource without them is a line on the bill that nobody claims.

The rules are strict and the same across Google Cloud: keys and values are lowercase letters, digits,
hyphens and underscores, international letters included; a key starts with a letter; each is at most
63 characters; a resource carries at most 64 labels. The CLI checks them before it sends anything:

```
ana@laptop:~/gcp$ gcloud pubsub topics create reminders --labels=team=planner,env=dev
Created topic [projects/planner-dev/topics/reminders].
ana@laptop:~/gcp$ gcloud pubsub topics create invoices --labels=Team=planner 2>&1 | head -2
ERROR: (gcloud.pubsub.topics.create) argument --labels: Bad value [Team]: Only hyphens (-), underscores (_), lowercase characters, and numbers are allowed. Keys must start with a lowercase character. International characters are allowed. Key length must not exceed 63 characters.
Usage: gcloud pubsub topics create TOPIC [TOPIC ...] [optional flags]
ana@laptop:~/gcp$ gcloud pubsub topics create invoices --labels=team=Planner 2>&1 | head -2
ERROR: (gcloud.pubsub.topics.create) argument --labels: Bad value [Planner]: Only hyphens (-), underscores (_), lowercase characters, and numbers are allowed. International characters are allowed.
Usage: gcloud pubsub topics create TOPIC [TOPIC ...] [optional flags]
ana@laptop:~/gcp$ gcloud pubsub topics list --filter="labels.env=dev" --format="table(name,labels)"
NAME                                   LABELS
projects/planner-dev/topics/reminders  {'env': 'dev', 'team': 'planner'}
```

**Both refusals are `gcloud`'s own**, made on the laptop: a capital in the key, a capital in the value.
The first command shows a topic created with two labels, and the filter shows what they are for: one
expression picks out every topic of one environment, however many the project holds, and the
billing export of lesson 14 does the same across every project at once.

## Where the emulator stops

Labels change over a resource's life: a team is renamed, a cost centre is split. Google's Pub/Sub
accepts an update to a topic's labels. The emulator does not:

```
ana@laptop:~/gcp$ gcloud pubsub topics update reminders --update-labels=cost-centre=cc-1040
ERROR: (gcloud.pubsub.topics.update) INVALID_ARGUMENT: Invalid update_mask provided in the UpdateTopicRequest: labels is not a known Topic field. Note that field paths must be of the form 'schema_settings' rather than 'schemaSetings'.
ana@laptop:~/gcp$ gcloud pubsub topics describe reminders
labels:
  env: dev
  team: planner
name: projects/planner-dev/topics/reminders
```

**That `INVALID_ARGUMENT` is the emulator's gap, not Google's rule.** The emulator implements part of
the API, and updating labels is outside the part it implements; its own banner said, in lesson 1, that
its implementation *may be incomplete or differ from the real system*. Against Google the same command
updates the labels in place. This is the kind of difference the course promised to point at rather
than paper over: the command is right, and the lab cannot show it working.

## Labels, tags and network tags

Three things in Google Cloud are called something like a tag, and they do three different jobs:

| | what it is | what reads it |
|---|---|---|
| **label** | a key and value on a resource | the billing export, filters, the asset inventory |
| **tag**, from the Resource Manager | a key and value defined once on the organisation and bound to resources | IAM conditions and organisation policies, which can say "only where `env` is `prod`" |
| **network tag** | a bare word on a virtual machine | firewall rules and routes, lessons 16 and 17 |

The difference that matters is **who may change it**. Anybody who may edit a resource may edit its
labels, so a label must never decide access: a developer who wants production's permissions would
only have to write `env=prod`. A Resource Manager tag is defined centrally, and binding one needs its
own role, which is why IAM conditions read tags and never labels.
