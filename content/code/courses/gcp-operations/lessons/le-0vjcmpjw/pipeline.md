---
title: A delivery pipeline is an ordered list of targets
version: 1
---

**Cloud Deploy moves one release through an ordered list of environments, and each environment is
a target.** The build of lesson 1 ends with an image in the registry. Cloud Deploy starts there: it
takes that image, renders the manifests for the first target, deploys them, and waits until somebody
promotes the release to the next target. It does not build anything and it does not decide what is
good; it carries the same thing forward, in order, and records who moved it. **Nothing in this
section ran**: no emulator answers for Cloud Deploy, and the files below were written from Google's
documentation.

The shop has two targets, `dev` and `prod`, both Cloud Run services in São Paulo, in one file,
`clouddeploy.yaml`, with three documents in it:

```yaml
# clouddeploy.yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
  name: shop-api
serialPipeline:
  stages:
    - targetId: dev
      profiles: [dev]
    - targetId: prod
      profiles: [prod]
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: dev
run:
  location: projects/planner-dev/locations/southamerica-east1
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: prod
requireApproval: true
run:
  location: projects/planner-dev/locations/southamerica-east1
executionConfigs:
  - usages: [RENDER, DEPLOY]
    serviceAccount: shop-deploy@planner-dev.iam.gserviceaccount.com
```

Read it as three statements:

- **the pipeline** `shop-api` has two stages, in that order; a release starts in the first and can
  only reach the second by promotion. `profiles` names the Skaffold profile used to render each
  stage, which is where the two environments differ;
- **the target** `dev` is a place: here, Cloud Run in a region of a project. A target for GKE names a
  cluster instead;
- **the target** `prod` is the same kind of place with two more lines: `requireApproval`, which is the
  next section's subject, and the service account that renders and deploys there. A deployment to
  production acting as a different, narrower account from the one that deploys to `dev` is how a
  mistake in `dev` stays in `dev`.

The pipeline and its targets are registered once, and again whenever the file changes:

```sh
gcloud deploy apply --file=clouddeploy.yaml --region=southamerica-east1
```

## Skaffold, the part that renders

Cloud Deploy does not read Kubernetes or Cloud Run manifests itself. It hands them to **Skaffold**,
Google's open-source tool for rendering and deploying, through a file of Skaffold's own:

```yaml
# skaffold.yaml
apiVersion: skaffold/v4beta13
kind: Config
metadata:
  name: shop-api
profiles:
  - name: dev
    manifests:
      rawYaml: [run/service-dev.yaml]
  - name: prod
    manifests:
      rawYaml: [run/service-prod.yaml]
deploy:
  cloudrun: {}
```

Each `service-*.yaml` is a Cloud Run service whose container image is written as the bare name
`shop-api`. When a release is created, Cloud Deploy gives Skaffold the real image for that name, and
Skaffold writes it into the rendered manifest **as a digest**. The two files differ in what an
environment should differ in: the service's name, its minimum instances, the memory, the variables
that point at the environment's database. They do not differ in the image, and that is the point of
the next section.
