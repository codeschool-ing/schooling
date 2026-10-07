---
title: Docker Hub, GHCR, ECR, Artifact Registry and ACR
version: 1
---

**Every hosted registry speaks the same API as Ana's, so `docker push` and `docker pull` work
against all of them unchanged.** What differs is the address in the image's name and how you log in,
and the login is where each provider plugs in its own identity system. None of the logins below was
run for this course, because the lab has no account with any of these services; the commands are
the ones each provider documents, and their documentation is where to check them.

## The five you will meet

| registry | image name | how you log in |
| --- | --- | --- |
| Docker Hub | `docker.io/<user>/<repo>`, or just `<user>/<repo>` | `docker login`, with a Docker account and an access token |
| GitHub Container Registry | `ghcr.io/<owner>/<repo>` | `docker login ghcr.io`, with a GitHub token that may write packages |
| Amazon ECR | `<account>.dkr.ecr.<region>.amazonaws.com/<repo>` | `aws ecr get-login-password` piped into `docker login` |
| Google Artifact Registry | `<region>-docker.pkg.dev/<project>/<repo>/<image>` | `gcloud auth configure-docker <region>-docker.pkg.dev` |
| Azure Container Registry | `<name>.azurecr.io/<repo>` | `az acr login --name <name>` |

Written out, the ECR login shows the shape most cloud registries share: a short-lived password
produced by the cloud's own command-line tool, handed to `docker login` on standard input:

```sh
aws ecr get-login-password --region sa-east-1 \
  | docker login --username AWS --password-stdin 123456789012.dkr.ecr.sa-east-1.amazonaws.com
```

The account number there is the documentation's placeholder. The token lasts hours, not months, so
a leaked one is worth little, which is the reason for the design.

**This platform's own release pipeline is an example.** Its workflow logs in with `gcloud auth
configure-docker` and pushes five images to Artifact Registry under
`us-central1-docker.pkg.dev/…`; lesson 26 writes a smaller pipeline of the same shape for `shelf`.
Google's older Container Registry, `gcr.io`, was retired in 2025 and its contents moved to Artifact
Registry; the distroless images this course uses are still pulled by their `gcr.io` names.

## Choosing one

- **Use the registry next to where the images run.** Pulling from the same cloud and region is
  faster, usually free of transfer charges, and authenticated by the identity the server already
  has, so no password needs to live on it.
- **Mind Docker Hub's limits for anonymous pulls.** This course's own lab was refused with `429 Too
  Many Requests` on its first pulls, which is why lesson 6's `registry-mirrors` setting exists. A
  CI fleet pulling the same base images all day hits the same wall; logging in, or a mirror of your
  own, avoids it.
- **Decide who may push.** Pull access can be broad; push access is the ability to change what every
  server runs next. It belongs to the pipeline, through a short-lived token, and to as few people as
  possible.
- **Plan for clean-up.** Registries keep every image ever pushed until told otherwise, and storage
  is billed. Every hosted registry has retention rules, such as keeping the last fifty tags or
  deleting untagged images after a month; set them on the first day.
