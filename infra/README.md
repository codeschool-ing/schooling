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

Five failures here have been the same failure: a field left out, the provider,
the API or the shell filling it in, and the answer being wrong in a way that
costs data, money or an afternoon.

| left out | filled in as | what it would have cost |
|---|---|---|
| `google_sql_database.deletion_policy` | `DELETE` | dropping the database and every row, while the protected instance stood |
| `settings.edition` | `ENTERPRISE_PLUS` | the tier refused, and the error suggesting a machine several times the agreed bill |
| `deletion_protection` on the Cloud Run pair | `true` | a failed create becoming a deadlock, cleared only by editing the configuration |
| the provider's `billing_project` | whatever `gcloud config set project` last wrote | every call for this project charged to another project's quota, and refused |
| the service-level `scaling` block | zeros the provider then wants to remove | every plan proposing a change nobody wrote, forever |

None of them was a mistake in what was written. All five were things nobody
wrote, and the defaults are not stable — the edition one changed under this
project's feet between somebody learning `db-f1-micro` and using it, and the
`billing_project` one is not even a default: it is whatever the shell happened
to hold, so it changed when a Cloud Shell session restarted.

The `billing_project` one is worth reading twice, because the error names two
projects and puts the wrong one in the advice:

```
Error when reading or editing Project "aleogr-schooling": Cloud Resource
Manager API has not been used in project codeschool-ing before or it is
disabled. Enable it by visiting …?project=codeschool-ing
```

Following it would have enabled an API on a project with no business in this
configuration, and it would have worked — which is how a wrong fix becomes
permanent.

The `scaling` row is the cheapest and the most instructive, because it costs
nothing at all except noise. The apply succeeds, the field comes back, and the
next plan proposes it again. A plan that always shows one change is a plan that
stops being read — and the change it shows on the day it matters, a database
being replaced or a service destroyed, arrives in the same shrug.

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

## The address

The service answers on its own `run.app` URL as soon as it is deployed. A school
answers on a name a student types, and that is a **Cloud Run domain mapping**:
one per school, no load balancer, nothing charged by the hour.

The load balancer was the other candidate, and the argument for it was a
wildcard — `*.schooling.lab.aleogr.dev`, one certificate covering every school
that will ever exist. Domain mappings do not do wildcards; each host is mapped
by name. **That is the right trade while creating a school is a runbook anyway.**
A school is already two rows written by hand and a directory in `content/`;
adding one line to that runbook costs nothing, and a managed certificate per
name costs nothing either. The load balancer's forwarding rule is billed per
hour whether anybody visits or not. When schools become self-serve the wildcard
becomes worth paying for — and not before.

The domain has to be verified once for the account, which for a domain on
Cloudflare is Domain Connect and takes a minute:

```sh
gcloud domains verify aleogr.dev            # opens the browser flow
gcloud domains list-user-verified           # aleogr.dev should be listed

gcloud beta run domain-mappings create \
  --service=schooling \
  --domain=code.schooling.lab.aleogr.dev \
  --region=us-central1
```

It answers with the DNS record to create — a `CNAME` to `ghs.googlehosted.com.`.
**At Cloudflare that record is DNS only, the grey cloud.** Proxying it hides the
name Cloud Run needs to see, and the certificate never issues.

Then it is a wait, and the wait is visible:

```sh
gcloud beta run domain-mappings describe \
  --domain=code.schooling.lab.aleogr.dev --region=us-central1 \
  --format="table(status.conditions[].type, status.conditions[].status, status.conditions[].reason)"
```

`CertificatePending` is the normal path and not a fault. **It took forty
minutes here**, which is worth writing down because every page that mentions it
says "a few minutes" and the gap between the two is spent wondering what is
broken. Google admits up to 24 hours; the usual cause of a long one is negative
DNS caching — a resolver asked for the name before the record existed, cached
the absence, and nothing moves until that expires.

While it is pending there is exactly one thing that can be wrong on this side,
and it fails silently forever rather than reporting anything: a **CAA** record
that does not name Google's certificate authority. CAA is inherited down the
tree, so every level has to be checked, not just the host:

```sh
for n in code.schooling.lab.aleogr.dev schooling.lab.aleogr.dev lab.aleogr.dev aleogr.dev; do
  echo "== $n"; dig +short CAA "$n"
done
```

Nothing at any level means any authority may issue, which is the case here. If
a level does answer, it has to include `pki.goog` — otherwise the request is
refused and the only symptom is a pending certificate.

`curl` against the name is the other useful reading: `SSL_ERROR_SYSCALL` with
`ssl_verify_result=1` is the front end dropping the handshake because it has no
certificate to present yet, which matches the status rather than contradicting
it.

`schooling.lab.aleogr.dev` itself is deliberately **not** mapped. Nothing serves
it: there is no platform page, and the tenant resolver answers 404 for a host it
does not know rather than falling into a default. A name that resolves to a 404
is worse than a name that does not resolve, because it looks like a broken
deployment.

### The console's address

`console.<platform domain>` is a mapping like a school's, and it is the only
address that is not a school's — *a host is a school's, or the console's, or a
404* (`K-17`). The binary already answers there; the mapping is what lets anybody
reach it.

```sh
gcloud beta run domain-mappings create \
  --service=schooling \
  --domain=console.schooling.lab.aleogr.dev \
  --region=us-central1
```

**No row anywhere.** A school is two rows and a mapping; the console is a
mapping and nothing else, because it belongs to no school and `tenant_domains`
is the table that says which school a host is. Adding it there would make the
console a school, which is the one thing the design refuses.

The name is on the reserved list (`migrations/0025`), so a school cannot be
created at it. That went in before the mapping did, on purpose: the other order
ends with a school and the console at one address, fixed by renaming the school.

## Monitoring

`alert_email` and `uptime_host` are both empty by default and nothing watches
anything. Both are needed, and the second one is the lesson: the check used to
point at `platform_domain`, which is the unmapped name above. Cloud Run's front
end routes by hostname before anything reaches the container, so a check against
an unmapped host measures **Google's 404 page** — reporting the service down
while it is perfectly healthy.

Watch a school's host instead, where `/readyz` is reachable and answers only
when the process can open its database. Both values go in `terraform.tfvars`,
which is gitignored — copy `terraform.tfvars.example` and fill it in:

```sh
cp infra/terraform.tfvars.example infra/terraform.tfvars
$EDITOR infra/terraform.tfvars
terraform -chdir=infra apply
```

**Not `-var` on the command line.** It works, and then the next apply — run by
anybody who did not type the same flags — plans the monitoring away and removes
it. Nothing fails and nothing warns; the alerting is just gone, and the way you
find out is that it never fires. A `terraform.tfvars` beside the configuration
is read by every apply from this directory, which is the behaviour that
survives being forgotten.

The e-mail is not in the repository because this one is public and a committed
address is a scraped address. That is also the whole reason the file is
gitignored rather than tracked with the rest of the configuration.

## What is checked, and what is not

`terraform fmt` and the HCL parser pass. **The provider schema is unverified** —
this repository has no network route to `registry.terraform.io`, so
`terraform init` and `terraform validate` have not run against the real Google
provider. `plan` in Cloud Shell is the first honest check, and the places most
likely to argue are the artifact registry cleanup policy, the uptime alert's
aggregation, and whether `db-f1-micro` is still offered for Postgres 16 in this
region — `db-g1-small` is the next size if it is not.

### And `plan` is not the last honest check either

The uptime alert's aggregation did argue, and it is worth knowing HOW, because
it is the failure mode this whole section underestimates. It did not fail the
plan. It did not fail the apply. It was created, and then it **fired fourteen
minutes later on a service answering 200** — because the comparison was written
against the metric's name rather than against what the reducer had turned it
into. See `monitoring.tf`, where the arithmetic is now written out.

`terraform apply` proves that Google accepted the configuration. It proves
nothing about whether the configuration says what somebody meant, and an alert
policy is precisely the kind of object where those two are far apart: it is
correct only in circumstances that have not happened yet, so the first honest
check is the first time it should have spoken — or, as here, the first time it
should have stayed quiet.
