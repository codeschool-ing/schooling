---
title: Protecting the state
version: 1
---

The state is now one object in one bucket, which is what it should be, and it is also the single
most valuable file this configuration produces. Three things can go wrong with it, and each has its
own defence: somebody reads it who should not, somebody writes a bad version of it, or it is lost.

## Who can read it

**Reading the state is reading everything Terraform knows about the account**: every id, every
ARN, every attribute a provider returned, for every resource. For the shop's network that is a map
of the infrastructure. For a configuration that creates a database, it is also the database's
password, in plain text, whatever `sensitive = true` hides on the screen; lesson 12 shows it there
and the ways to keep it out.

So the bucket's permissions are the state's permissions. The blocked public access from
"remote-backend" is the floor. Above it, the people and pipelines that run Terraform on this
configuration need to read and write that key, and nobody else needs anything; a policy that lets
"all developers" list the bucket is a policy that hands them every secret in every state in it.
`encrypt = true` protects the object on S3's disks, and does nothing against somebody the bucket
lets in. It is the access policy that does the work.

## A bad write, and the history that undoes it

Versioning was switched on before the first state was written, and every write since is still in
the bucket. The migration and two applies have written this state, and S3 kept all three:

```
ana@laptop:~/shop$ aws s3api list-object-versions --bucket shop-tfstate-123456789012 --prefix shop/terraform.tfstate --query "Versions[?Key=='shop/terraform.tfstate'].[LastModified,Size,IsLatest]" --output text
2026-10-02T03:52:52.000Z	5979	True
2026-10-02T03:52:26.000Z	5907	False
2026-10-02T03:51:41.000Z	5835	False
```

Any of those can be fetched by its version id. Ana takes the oldest, the one `-migrate-state`
wrote, and compares it with the current one:

```
ana@laptop:~/shop$ aws s3api get-object --bucket shop-tfstate-123456789012 --key shop/terraform.tfstate --version-id 9049e965-1e0c-4ffe-b897-74c3fb7f9ff8 old.tfstate > /dev/null
ana@laptop:~/shop$ jq "{serial, lineage}" old.tfstate
{
  "serial": 1,
  "lineage": "68edf607-1653-46e5-9a24-69e2860acf13"
}
ana@laptop:~/shop$ terraform state pull | jq "{serial, lineage}"
{
  "serial": 3,
  "lineage": "68edf607-1653-46e5-9a24-69e2860acf13"
}
```

**Same lineage, different serial**: two points in one history, the old one two writes behind. This
is what "lineage" and "serial" from the first section are for. Suppose Ana, or a script, tried to
put the old one back as the current state:

```
ana@laptop:~/shop$ terraform state push old.tfstate
Failed to write state: cannot import state with serial 1 over newer state with serial 3
```

Terraform refuses to replace a newer state with an older one. That refusal is what keeps a stale
copy on somebody's disk from quietly undoing a week of applies, and a state with another lineage is
refused the same way. `terraform state push -force` overrides both checks, and it is the right tool
on exactly one occasion: the current state is damaged, an older version is known to be good, and
nothing else is running. Then you also run a plan straight after and read it, because every change
made since that version is now unknown to the state again.

## The rules, in short

Keep the state in a remote backend with locking, never in git and never only on a laptop. Turn on
versioning before the first write, so there is a history to go back to. Block public access, and
give the bucket a policy naming who may use it rather than one naming who may not. Never edit the
JSON by hand; `terraform state` does the edits that are needed, and lessons 4 and 6 do most of them
from the configuration instead. And treat the bucket that holds it as part of the infrastructure:
created first, destroyed last, and by nobody in a hurry.

One question this lesson has left open is how big a single state should be. The shop has one for
everything, which means one lock for everything and one file whose loss costs everything. Lesson 8
splits it.
