---
title: Where production keeps its secrets
version: 1
---

An environment variable is how a secret **reaches** a process. It is not where a secret is **kept**.
In production, the source of the variable should be a **secret manager**: a service whose only job
is to hold secrets, hand them to the processes allowed to have them, and record each time it does.

| what a secret manager gives | why it matters |
|---|---|
| **access per process** | the reminder worker can read the SMS key and not the database owner's password |
| **an audit log** | every read is recorded with who and when, which a `.env` file on a server cannot do |
| **rotation without a deploy** | a key changes in one place, and the process picks it up on its next start or read |
| **short-lived credentials** | some managers issue a database password valid for an hour, so a copy that leaks expires by itself |

Common ones are HashiCorp Vault, which a team runs itself, and the managed services of each cloud
provider: AWS Secrets Manager, Google Secret Manager and Azure Key Vault. Container platforms such
as Kubernetes have a `Secret` object that delivers values to a process, and is only as safe as the
cluster's own access control. None of these was run for this course; each is configured in its own
way, and all of them end where this lesson's code begins, with a variable the process reads at
start-up and refuses to start without.

::: track devsecops
Your track's `secure-pipeline` and `cloud-security` courses run a secret manager and wire it to a
pipeline and a cloud account. This lesson's part is the application's: never hold a secret in code,
and refuse to start without one.
:::

::: track security
Your track's `cloud-security` course looks at how cloud providers store and grant secrets. This
lesson's part is the application's: never hold a secret in code, and refuse to start without one.
:::

::: track *
Whatever holds the secrets, the application's part is the same: never hold a secret in code, and
refuse to start without one.
:::

### A short list to keep

- **Every secret has an owner and a rotation date.** A key nobody remembers creating is a key nobody
  will rotate.
- **One secret per purpose.** The reminder worker and the portal do not share a database password,
  so revoking one does not stop the other, and a leak from one does not open the other.
- **Secrets never appear in logs or error pages.** Lesson 15 is about what an error page and a log
  line may show.
