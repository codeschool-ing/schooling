---
title: A repository is a place, a format and a region
version: 1
---

**Artifact Registry keeps artifacts in repositories, and a repository has three properties that
never change after it is created: its format, its location and its name.** The format says what it
holds: Docker images, Python packages, npm packages, Maven artifacts, Debian or RPM packages, and a
few more, one format per repository. The location is a region, such as `southamerica-east1`, or a
multi-region, such as `us`. The name is yours. Together they make the address the last lesson built
an image under:

```localised
southamerica-east1-docker.pkg.dev / planner-dev / shop / api : v1
└──── location and format ──────┘   └project┘   └repo┘ └image┘ └tag┘
```

So an image cannot be moved to another region by editing anything. A repository in the wrong region
is a new repository and a copy, and every deployment that names the old address has to change. The
shop's images live in São Paulo because the services that pull them run there: a pull from the same
region carries no transfer charge, and one from another continent does.

The shop's repository, as `gcloud` creates it:

```sh
gcloud artifacts repositories create shop \
  --repository-format=docker \
  --location=southamerica-east1 \
  --description="The shop's container images"
```

It was not run: no emulator answers for Artifact Registry. There are three **modes**, and the
command above makes the first, the default:

| mode | what it does |
|---|---|
| standard | stores what you push to it |
| remote | a cache in front of another registry, such as Docker Hub, kept in your project |
| virtual | one address in front of several repositories, searched in an order you give |

A **remote** repository is the answer to the limit on anonymous pulls the last lesson avoided with
`mirror.gcr.io`: the build pulls from your own cache in your own region, and only the first pull of
each image goes to Docker Hub.

## A registry on your computer

What a Docker repository does on the wire is the registry protocol, the same one Docker Hub and every
other registry speak. The open-source registry that defines it runs as a container, and it is what
this lesson pushes to. It stores and serves images, and that is all: it has no repositories with a
format, no regions, no permissions, no immutable tags, no scanning. Everything in this lesson beyond
the push and the pull is taught from Google's documentation.

```
ana@laptop:~/gcp/shop$ docker run -d --rm --name registry -p 5000:5000 mirror.gcr.io/library/registry:3.0.0
4f7e2f37f36b54ddc3297709d5d9b6b5c47e9aa90599c9a2e6a7dc8661a22284
ana@laptop:~/gcp/shop$ curl -s localhost:5000/v2/_catalog; echo
{"repositories":[]}
```

`/v2/_catalog` is the list of images it holds, empty for now. Its address is `localhost:5000`, where
Artifact Registry's is `southamerica-east1-docker.pkg.dev`; the rest of the name works the same way.
The files of the shop from lesson 1 are still in `~/gcp/shop`: only the emulators forget, and your
own files stay where you wrote them.

## Who may pull

Access to a repository is IAM on the repository: `roles/artifactregistry.reader` to pull,
`roles/artifactregistry.writer` to push, granted to a service account rather than to the project.
The shop's build account from lesson 1 is a writer on `shop` and nothing else; the account that runs
the API is a reader. **A reader on the whole project can pull every image in every repository**,
which includes the ones that carry another team's code.
