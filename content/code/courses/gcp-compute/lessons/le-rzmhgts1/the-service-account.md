---
title: The machine's own identity
version: 1
---

A program on the shop's web server needs to read a bucket and write to Pub/Sub. **The wrong way
is a key file: a JSON file holding a service account's private key, copied onto the machine.** It
works, it never expires, and a copy of it works from anywhere in the world for as long as nobody
notices it was taken. Compute Engine offers something better, and it is already running.

## A service account attached to the machine

Every instance can carry one **service account**, named in its `service_account` block. The
metadata server then hands any process on the machine an access token for that account at
`instance/service-accounts/default/token`. The token is short-lived, about an hour, and the
metadata server replaces it before it expires. Google's client libraries and gcloud ask for it on
their own; your code never sees a key.

The `meta/main.tf` of section 02 already creates a dedicated account, `shop-web`, and attaches it:

```
ana@laptop:~/gcp/meta$ terraform plan -no-color | grep -E '# google|email|member|auth/'
  # google_compute_instance.web will be created
          + email  = "shop-web@planner-dev.iam.gserviceaccount.com"
              + "https://www.googleapis.com/auth/cloud-platform",
  # google_service_account.web will be created
      + email           = "shop-web@planner-dev.iam.gserviceaccount.com"
      + member          = "serviceAccount:shop-web@planner-dev.iam.gserviceaccount.com"
```

**The email is known at plan time**, because it is built from the account id and the project:
`shop-web@planner-dev.iam.gserviceaccount.com`. The `member` line is the same identity written the
way IAM bindings name it, which `gcp-foundations` covers and lesson 15 uses again.

Why not the default? A new project has a **Compute Engine default service account**, named
`PROJECT_NUMBER-compute@developer.gserviceaccount.com`, and an instance created without a
`service_account` block gets it. In older projects that account was granted the Editor role on the
whole project, which means every machine could change almost anything. Organisations created
since 2024 block that grant by policy, but plenty of projects predate it. **One dedicated account
per kind of machine, with only the roles that machine needs**, is the rule that survives an
incident: a stolen token from `web-1` reads what a web server reads, and nothing else.

## How a library finds its credentials

Google's libraries follow one search order, called **Application Default Credentials**, and it is
the same on a laptop and on a machine. This program asks for it and prints what it found. Save it
as `meta/adc.py`:

```python
# meta/adc.py
import google.auth
from google.auth.exceptions import DefaultCredentialsError

try:
    credentials, project = google.auth.default()
    print('found', type(credentials).__name__, 'for project', project)
except DefaultCredentialsError as e:
    print('no credentials:', e)
```

`google-auth` arrived with the Pub/Sub client in lesson 1's virtual environment. Run it twice, the
second time pointing at a key file that does not exist:

```
ana@laptop:~/gcp/meta$ time python3 adc.py
no credentials: Your default credentials were not found. To set up Application Default Credentials, see https://cloud.google.com/docs/authentication/external/set-up-adc for more information.

real	0m3.044s
user	0m0.171s
sys	0m0.008s
ana@laptop:~/gcp/meta$ GOOGLE_APPLICATION_CREDENTIALS=~/gcp/meta/key.json python3 adc.py
no credentials: File /home/ana/gcp/meta/key.json was not found.
```

The order shows in what each run says. **First**, the variable `GOOGLE_APPLICATION_CREDENTIALS`:
when it is set, the library reads that file and nothing else, which is why the second run failed on
the file rather than searching further. **Second**, the file `gcloud auth application-default
login` writes in your home directory, which this lab never has. **Third**, the metadata server: the
library tries to reach it, and only when that fails does it give up. On this laptop the whole
search took about three seconds, most of it spent on the metadata server that is not there.

On a Compute Engine machine with an attached account, the first two find nothing and the third
answers: the same `google.auth.default()` returns the machine's credentials with no file
anywhere. That is the point of the order: **code written this way needs no change between a
laptop and a machine**, and it never needs a key file on either.
