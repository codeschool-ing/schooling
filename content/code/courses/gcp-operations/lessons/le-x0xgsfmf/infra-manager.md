---
title: Infrastructure Manager, Terraform run by Google
version: 1
---

**Infrastructure Manager runs your Terraform for you, inside Google Cloud, and keeps the state itself.**
The configuration is the same HCL as lesson 5's, with no provider block pointing at an emulator; what
changes is who runs `terraform apply`, where the state lives and who can read it. It answers lesson 6's
questions by taking them away: the state is in a bucket Google manages for the deployment, locked by the
service, and versioned with every revision. None of it ran here: there is no project to run it in.

## A deployment and its revisions

A **deployment** is one Terraform configuration managed by Infrastructure Manager. Each apply creates a
**revision**, which records the configuration it applied, the outcome, and the state after it. The shop's,
created from a directory in a Git repository:

```sh
gcloud infra-manager deployments apply projects/planner-dev/locations/southamerica-east1/deployments/shop \
  --service-account=projects/planner-dev/serviceAccounts/shop-infra@planner-dev.iam.gserviceaccount.com \
  --git-source-repo=https://github.com/example/shop-infra \
  --git-source-directory=tf/shop \
  --git-source-ref=main
```

A **preview** is the plan: `gcloud infra-manager previews create` runs `terraform plan` in the same
environment and stores the result, so a reviewer reads the plan Infrastructure Manager will apply rather than
one computed on somebody's laptop with different credentials.

The service account is the identity the deployment acts with, and the only one: nobody's laptop credentials
are involved after the deployment exists. That is the same move as lesson 5's impersonation, made permanent.

## What it does not do

- **It does not correct drift.** Between applies, a change made by hand stays until the next revision,
  exactly as with Terraform run anywhere else. Config Connector is the option that corrects.
- **It does not change what Terraform can do.** A resource the provider cannot import (lesson 6) is still
  impossible to import; a configuration that would destroy a bucket still destroys it. The plan is still the
  thing to read.
- **It pins a Terraform version** per deployment, chosen from the versions Google supports rather than
  whichever one is newest.

## No price here

Infrastructure Manager has a price of its own, for the time Terraform runs and the state it keeps. Its
pricing page could not be read from the machine this course was written on, so no number is quoted; read
the current page before choosing it on cost.
