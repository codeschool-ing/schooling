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

Four failures here have been the same failure: a field left out, the provider,
the API or the shell filling it in, and the answer being wrong in a way that
costs data, money or an afternoon.

| left out | filled in as | what it would have cost |
|---|---|---|
| `google_sql_database.deletion_policy` | `DELETE` | dropping the database and every row, while the protected instance stood |
| `settings.edition` | `ENTERPRISE_PLUS` | the tier refused, and the error suggesting a machine several times the agreed bill |
| `deletion_protection` on the Cloud Run pair | `true` | a failed create becoming a deadlock, cleared only by editing the configuration |
| the provider's `billing_project` | whatever `gcloud config set project` last wrote | every call for this project charged to another project's quota, and refused |

None of them was a mistake in what was written. All four were things nobody
wrote, and the defaults are not stable — the edition one changed under this
project's feet between somebody learning `db-f1-micro` and using it, and the
last one is not even a default: it is whatever the shell happened to hold, so
it changed when a Cloud Shell session restarted.

That one is worth reading twice, because the error names two projects and puts
the wrong one in the advice:

```
Error when reading or editing Project "aleogr-schooling": Cloud Resource
Manager API has not been used in project codeschool-ing before or it is
disabled. Enable it by visiting …?project=codeschool-ing
```

Following it would have enabled an API on a project with no business in this
configuration, and it would have worked — which is how a wrong fix becomes
permanent.

**So: if behaviour is being relied on, it is in the file.** Not because the
default is wrong today, but because a default is a decision made somewhere else
by somebody who does not know what this project is.

### Turning deletion protection off does not unblock a replacement

Not in the same apply, and the reason is the order a replacement happens in: the
destroy runs FIRST, against the object as it currently is, and the provider
reads the flag from that. The new value only exists on the create half, which is
never reached. So

```
Error: cannot destroy service without setting deletion_protection=false
       and running `terraform apply`
```

survives the very apply that sets it to false, and says so in a way that reads
like the change did not land.

The way out, when the resource holds nothing and is going to be rebuilt anyway,
is to delete it and let the next apply create it:

```sh
gcloud run services delete schooling --region=us-central1 --quiet
gcloud run jobs delete schooling-migrate --region=us-central1 --quiet
terraform -chdir=infra apply
```

That is not configuring by hand — no setting is chosen outside this directory,
and the configuration rebuilds both immediately. The pure-Terraform route is
`untaint` both, `apply` to flip the flag in place, `taint` both, `apply` again:
four commands and two applies to arrive at the same place.

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

## Applying takes two passes, and the reason is the secret

**The first apply cannot finish, and that is the design working.** Cloud Run
resolves `secretKeyRef … versions/latest` while it creates the service, and the
secret this configuration makes is an empty container — Terraform never writes
what goes in it. So the service and the job are refused with

```
Secret projects/…/schooling-database-url/versions/latest was not found
```

after everything they depend on has been built. That is the right failure: a
service that came up pointing at a database it cannot reach would be a green
apply and a broken deployment, and the readiness check would be the thing that
told you, later.

The alternative — a placeholder version written by Terraform — buys a
single-pass apply and pays for it by putting a value in the state file and
starting a service that cannot work. Not existing is a better state than
existing and lying.

```sh
terraform -chdir=infra init
terraform -chdir=infra plan      # read it. It creates a database.
terraform -chdir=infra apply     # stops at the two Cloud Run resources
```

## Then the database role and the secret, once

The instance and the database exist after that first pass; the role does not.

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

`terraform output` has nothing to give until an apply completes, so before the
second pass take the connection name from the instance itself:

```sh
CONNECTION="$(gcloud sql instances describe schooling --format='value(connectionName)')"
```

## And the second pass

```sh
terraform -chdir=infra apply     # the service, the job, the invoker binding
```

The service and the job come up on Google's placeholder container. They are
supposed to: there is no image yet, and the first deploy replaces it.

Rotating the password later is the same two commands as above:
`gcloud sql users set-password`, then a new secret version. The service reads
`latest`, and a running revision keeps the value it resolved at creation — the
new one is picked up by the next deploy.

## The school, once

**A directory in `content/` does not create a school**, and `cmd/load` refuses
to write for one that does not exist — a school is also an address and a domain
mapping, which are decisions rather than derivations. Until the console can make
one, it is two rows, made once.

Through the Auth Proxy, or from Cloud Shell with `gcloud sql connect`:

```sql
INSERT INTO tenants (slug, name, accent)
VALUES ('code', 'Programming', '#2F6F4E');

INSERT INTO tenant_domains (host, tenant_id)
SELECT 'code.schooling.lab.aleogr.dev', id FROM tenants WHERE slug = 'code';
```

The slug is a **host label** and the database checks it: lowercase letters,
digits and hyphens, never starting or ending with one. It is also the subdomain
the school answers on, which is why those are the same rule and not two.

The host is stored already normalised — lowercase, no port — and it is the whole
of how a request finds its school. A host nobody mapped is a 404 and never falls
into a default, so until this row exists the deployment answers `/version` and
nothing else. That is the design and not an outage.

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
