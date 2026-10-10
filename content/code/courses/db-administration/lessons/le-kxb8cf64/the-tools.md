---
title: The tools that do this at scale
version: 1
---

`provision.sh` is about sixty lines and builds one kind of server. That is the right size to learn
the idea on, and it is the size at which writing your own stops paying. Somewhere past a handful
of machines, or a second kind of server, the checks become most of the code and every team's
script grows the same features badly. Two tools are what most teams reach for instead, one for
servers you run and one for services somebody else runs. Neither is run in this course; this
section names them so that you recognise what you are looking at, and the configuration below
was not executed here.

## Ansible, for servers you can log in to

**Ansible** does what `provision.sh` does, over SSH, to a list of machines at once. Each step is a
**task** that calls a **module**, and every module is written to check before it acts, so a
playbook is idempotent without anybody writing `cmp -s` by hand. Its output is the same promise as
the script's: each task reports `ok` when nothing needed doing and `changed` when something did,
and a second run that reports a `changed` is the same warning as before.

The modules for PostgreSQL are in a collection called `community.postgresql`:
`postgresql_db`, `postgresql_user`, `postgresql_pg_hba` and `postgresql_set` among them. One task,
to give a sense of the shape:

```yaml
- name: work_mem for the shop's nightly report
  community.postgresql.postgresql_set:
    name: work_mem
    value: 32MB
  become: true
  become_user: postgres
```

**Read what a module does before trusting it with a file.** `postgresql_set` works through
`ALTER SYSTEM`, so with it the managed file is `postgresql.auto.conf` rather than a file in
`conf.d`. Either arrangement is sound. Mixing them is not: if Ansible owns `postgresql.auto.conf`,
a person running `ALTER SYSTEM` by hand is editing the tool's file, and the next run takes it back.

## Terraform, for a managed service

A managed service has no shell and no `conf.d` (lesson 3). Its parameters are a form in the
provider's console, and a form edited by hand drifts exactly like a file edited by hand. **Terraform**
describes the service itself as code: the instance, its size, its version and its parameters, each
as a resource in a file under version control. On AWS, the parameters of an RDS PostgreSQL are a
**parameter group**:

```hcl
resource "aws_db_parameter_group" "shop" {
  name   = "shop-pg16"
  family = "postgres16"

  parameter {
    name  = "work_mem"
    value = "32768"
  }
}
```

The value is in kilobytes, because that is what the service expects; the provider's parameter list
says each one's unit. Google Cloud SQL calls the same thing `database_flags` on the instance, and
Azure has a resource per parameter. `terraform plan` compares what the files say with what the
provider reports, and lists every difference before changing anything — the managed-service
version of `diff` against the repository.

## What does not change with the tool

Whatever writes the configuration, the three habits of this lesson stay the same. **One source**,
in a repository, with a reason on every change. **The server made from it**, by something that can
be run again safely. **The running server checked against it**, with `pg_settings` for what is
applied, `pg_file_settings` for what the files say, and `\drds` for what lives in the catalogue —
none of which knows or cares which tool did the writing.
