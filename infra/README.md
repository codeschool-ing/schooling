# The project this runs in

Everything in `aleogr-schooling` is declared here, with three deliberate
exceptions. Each one is listed below with the reason it is not code — "somebody
did it in the console once" is not among them.

The roadmap's phase 0 asks that *Terraform owns the project services, registry,
service accounts, IAM, Cloud SQL, secret containers, the identity federation and
the alert policies*, and that *the deploy pipeline owns which revision runs;
Terraform never manages the image*. That is the division this directory
implements, and `lifecycle { ignore_changes }` on the service and the job is
where the second half stops being a promise.

---

## What is not here, and why

**The state bucket.** Terraform would have to write its state somewhere in order
to create the place it writes its state. Created once by hand, versioned so that
a truncated write is recoverable.

**Every secret value.** This declares that `schooling-database-url` exists and
who may read it. Setting a version through Terraform would put the value in the
plan output, in the state file, and in every version of that state the bucket
keeps — a second home for a secret whose whole point is having one.

**The database role.** It needs a password, which is a secret value, so it
follows the same rule.

---

## Defaults are stated, not inherited

Three of the first four failures here were the same failure: a field left out,
the provider or the API filling it in, and the answer being wrong in a way that
costs data, money or an afternoon.

| left out | filled in as | what it would have cost |
|---|---|---|
| `google_sql_database.deletion_policy` | `DELETE` | dropping the database and every row, while the protected instance stood |
| `settings.edition` | `ENTERPRISE_PLUS` | the tier refused, and the error suggesting a machine several times the agreed bill |
| `deletion_protection` on the Cloud Run pair | `true` | a failed create becoming a deadlock, cleared only by editing the configuration |

None of them was a mistake in what was written. All three were things nobody
wrote, and the defaults are not stable — the edition one changed under this
project's feet between somebody learning `db-f1-micro` and using it.

**So: if behaviour is being relied on, it is in the file.** Not because the
default is wrong today, but because a default is a decision made somewhere else
by somebody who does not know what this project is.

---

## The bootstrap, once

```sh
gcloud projects create aleogr-schooling --name="schooling"

gcloud billing accounts list
gcloud billing projects link aleogr-schooling --billing-account=XXXXXX-XXXXXX-XXXXXX

gcloud config set project aleogr-schooling

# Only what Terraform itself needs in order to act. It enables the rest.
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  serviceusage.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  storage.googleapis.com

gcloud storage buckets create gs://aleogr-schooling-tfstate \
  --project=aleogr-schooling \
  --location=us-central1 \
  --uniform-bucket-level-access \
  --public-access-prevention

gcloud storage buckets update gs://aleogr-schooling-tfstate --versioning
```

## The first apply

```sh
terraform -chdir=infra init
terraform -chdir=infra plan      # read it. It creates a database.
terraform -chdir=infra apply
```

The service and the job come up on Google's placeholder container. They are
supposed to: there is no image yet, and the first deploy replaces it.

## The database role and the secret, once

The instance and the database exist after the apply; the role does not.

```sh
# A password that was never typed and is not in a shell history.
PASSWORD="$(openssl rand -base64 30)"

gcloud sql users create schooling \
  --instance=schooling \
  --password="$PASSWORD"

# The connection name the socket is addressed by.
CONNECTION="$(terraform -chdir=infra output -raw database_connection_name)"

# THE HOST IS A UNIX SOCKET, not a hostname. Cloud Run mounts the instance at
# /cloudsql/<connection name>, and `pgx` reads that from `host=`.
printf 'postgres://schooling:%s@/schooling?host=/cloudsql/%s' \
  "$PASSWORD" "$CONNECTION" \
  | gcloud secrets versions add schooling-database-url --data-file=-

unset PASSWORD
```

Rotating it later is the same two commands: `gcloud sql users set-password`,
then a new secret version. The service reads `latest` and picks it up on the
next revision.

## Monitoring

`alert_email` is empty by default and nothing watches anything. That is
deliberate while `schooling.lab.aleogr.dev` does not resolve: a check against a
name nobody has published fails on its first run and every run after, and all it
teaches anybody is to ignore the alert.

Set the address once the DNS record exists, and apply again.

## The address

The service answers on its own `run.app` URL as soon as it is deployed. Pointing
`schooling.lab.aleogr.dev` at it — and `*.schooling.lab.aleogr.dev`, because a
school is a subdomain — is the piece that decides between a Cloud Run domain
mapping and a load balancer in front. **A wildcard is the requirement**, and
support for one differs between those two paths; it is the first thing to check
rather than the thing to discover after building one of them.

Whichever it is, the certificate needs **both** names: a wildcard covers
`code.schooling.lab.aleogr.dev` and does not cover
`schooling.lab.aleogr.dev` itself. That gap presents as "every school works and
the platform's own page does not".

## What is checked, and what is not

`terraform fmt` and the HCL parser pass. **The provider schema is unverified** —
this repository has no network route to `registry.terraform.io`, so
`terraform init` and `terraform validate` have not run against the real Google
provider. `plan` in Cloud Shell is the first honest check, and the places most
likely to argue are the artifact registry cleanup policy, the uptime alert's
aggregation, and whether `db-f1-micro` is still offered for Postgres 16 in this
region — `db-g1-small` is the next size if it is not.
