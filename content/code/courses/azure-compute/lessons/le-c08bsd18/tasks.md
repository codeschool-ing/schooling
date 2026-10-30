---
title: Tasks, and the clean-up nobody remembers
version: 1
---

ACR Tasks is easy to take for a CI service with a registry attached, a rival to whatever runs the
shop's tests. **It is narrower than that: a task builds images, runs containers and pushes, on
Microsoft's machines, beside the registry it belongs to.** There is a quick task, which is
`docker build` and `docker push` done in Azure; a triggered task, which runs on a commit, on a
timer, or when a base image changes; and a multi-step task, a YAML file of builds, containers and
pushes. Nothing in this section can run without a subscription, so it is read from Microsoft's
documentation, with two exceptions: the CLI's help, and a deletion on the registry of section 03.

## The quick task

From the directory above `shop/`, this sends the directory to the registry, builds it there and
pushes the result. It was not run in this course:

```sh
az acr build --registry shopregistry --image shop:1.1 shop
```

No Docker is needed on the machine that types it, and **a task builds for Linux on `amd64` unless
told otherwise**, which settles lesson 7's warning about images built on an Arm laptop. Three of the
command's options deserve their help text:

```
ana@laptop:~/azure$ az acr build --help | awk '/^    --/{p=0} /^    --(build-arg|image|platform) /{p=1} p'
    --build-arg              : Build argument in '--build-arg name[=value]' format. Multiples are
                               supported by passing '--build-arg name[=value]' multiple times.
                               IMPORTANT: This parameter should not include passwords, access
                               tokens, or sensitive information of any kind. This parameter value
                               will be visible to the ACR team for debugging purposes.
    --image -t               : The name and tag of the image using the format: '-t repo/image:tag'.
                               Multiple tags are supported by passing -t multiple times.
    --platform               : The platform where build/task is run, Eg, 'windows' and 'linux'. When
                               it's used in build commands, it also can be specified in
                               'os/arch/variant' format for the resulting image. Eg, linux/arm/v7.
                               The 'arch' and 'variant' parts are optional.
```

Read the `--build-arg` warning twice. **A build argument is visible to the ACR team**, so a token
passed that way is a token handed to Microsoft's support engineers; `--secret-build-arg` exists for
secrets and is kept out of what they see. Microsoft's documentation adds that anything on a task's
command line or in a URL may end up in the registry's diagnostic logs. Two facts about money belong
here too: a task's running time is billed on top of the registry, and on 30 October 2026 the
documentation says task runs are paused for subscriptions paid with Azure's free credits.

## A task written down

A multi-step task is a YAML file. This one builds the shop, starts it, checks it answers, and only
then pushes. Save it as `~/azure/acr-task.yaml`:

```schooling-example
{"language": "yaml", "file": "acr-task.yaml", "parts": [{"code": "# acr-task.yaml\nversion: v1.1.0\nstepTimeout: 600\n", "note": "`version` is the format of the file, and `v1.1.0` is the one that allows the short aliases below. `stepTimeout` is the seconds any step may take before it is stopped; 600 is also the default."}, {"code": "steps:\n  - id: build\n    build: -t $Registry/shop:$ID -t $Registry/shop:latest shop\n", "note": "`build` takes the arguments of `docker build`. `$Registry` becomes the registry the task runs in, `shopregistry.azurecr.io`, and `$ID` the run's id, which is different every run: **a tag nobody will ever reuse**, beside the `latest` that moves."}, {"code": "  - id: shop\n    cmd: $Registry/shop:$ID\n    detach: true\n", "note": "`cmd` runs a container. `detach: true` leaves it running while the next steps go on. A step's `id` is also its container's name, and the other steps reach it by that name."}, {"code": "  - id: smoke\n    cmd: curl --retry 5 --retry-connrefused -fsS http://shop:8080/healthz\n", "note": "`curl` is an alias ACR Tasks defines for one of Microsoft's images. It asks the shop for its health by the name `shop`, retrying while the server starts. `-f` makes a 404 or a 500 an error, and an error fails the run."}, {"code": "  - id: push\n    push:\n      - $Registry/shop:$ID\n      - $Registry/shop:latest\n", "note": "Steps run in order unless a `when` says otherwise, so the push happens only after the check passed. An image that does not answer `/healthz` never reaches the registry."}]}
```

Run once by hand, against the directory or a Git repository, the file goes to `az acr run`. Made
into a task, it can be triggered:

```sh
az acr run --registry shopregistry --file acr-task.yaml .
az acr task create --registry shopregistry --name shop-build --file acr-task.yaml \
  --context https://github.com/shop-sp/shop.git#main --git-access-token "$GITHUB_TOKEN"
```

Neither was run. The repository is an invented one, and `--git-access-token` takes a personal access
token that lets the task install a webhook on it. What a new task listens for by default is in its
help:

```
ana@laptop:~/azure$ az acr task create --help | awk '/^    --/{p=0} /^    --(base-image-trigger-enabled|commit-trigger-enabled|pull-request-trigger-enabled|schedule) /{p=1} p'
    --base-image-trigger-enabled            : Indicates whether the base image trigger is enabled.
                                              Allowed values: false, true.  Default: True.
    --commit-trigger-enabled                : Indicates whether the source control commit trigger is
                                              enabled.  Allowed values: false, true.  Default: True.
    --pull-request-trigger-enabled          : Indicates whether the source control pull request
                                              trigger is enabled. The trigger is disabled by
                                              default.  Allowed values: false, true.
    --schedule                              : Schedule for a timer trigger represented as a cron
                                              expression. An optional trigger name can be specified
                                              using `--schedule name:schedule` format. Multiples
                                              supported by passing --schedule multiple times.
```

## Triggers, and the one that moves your tags

A **commit** to the branch runs the task, from the moment it is created. A **pull request** does
only when that trigger is switched on. A **schedule** is a cron expression in UTC, given as
`--schedule "0 3 * * *"`. And the **base image trigger** is the one that has no counterpart in
most build services: when the image named in `FROM` changes, the task rebuilds the image it makes
from it. That is how a security fix in Debian reaches the shop without anybody pushing a commit.

Four conditions in the documentation decide whether it fires. The task has to have run **once**,
because that run is when it records what the image was built from. The base image has to carry a
**stable tag**, such as `3.12-slim`, which its maintainer moves to each patched build; a new
release under a new version tag triggers nothing. Only the **final image's** base is tracked,
not the build stages before it in a multi-stage Dockerfile. And the delay depends on where the base
lives: a base in an Azure registry triggers at once, while one on Docker Hub or in Microsoft's public
registry is checked at a random interval of 10 to 60 minutes.

Beside section 03, the cost is plain. **The rebuild pushes under the tags the task
names**, so `latest` moves the way it moved there, and an image that only `latest` pointed at is left
with no tag at all, still stored, still billed. `$ID` is what keeps a release reachable: the rebuild
gets a new id, and the old one still names the old image.

## What nobody tags

Every moved tag leaves an untagged manifest behind, and a busy registry collects thousands. ACR has
two ways to clear them, and they are different tools.

A **retention policy** is a setting on a Premium registry, in preview, that deletes a manifest a
given number of days after it loses its last tag:

```
ana@laptop:~/azure$ az acr config retention update --help | awk '/^    --/{p=0} /^    --(days|type) /{p=1} p'
    --type        [Required] : The type of retention policy.  Allowed values: UntaggedManifests.
    --days                   : The number of days to retain an untagged manifest after which it gets
                               purged (Range: 0 to 365). Value "0" will delete untagged manifests
                               immediately.  Default: 7.
```

Three details in the documentation limit it. It counts only manifests untagged **after** the policy
was enabled. It skips a manifest locked against deletion. And **it handles only Docker's own media
types**, `application/vnd.docker.distribution.manifest.v2+json` and the Docker list type, and not
the OCI ones. Section 03 showed what the shop's image is: an OCI index of OCI manifests, because that
is what Docker 29 writes. The policy would leave every untagged copy of it in place, indefinitely.

**`acr purge` covers the rest**, and it runs as a task. This removes every tag in `shop` older than
thirty days, and then every manifest left without one, with `--dry-run` first to list what would go:

```sh
az acr run --registry shopregistry --cmd "acr purge --filter 'shop:.*' --ago 30d --untagged --dry-run" /dev/null
az acr task create --registry shopregistry --name shop-purge --cmd "acr purge --filter 'shop:.*' --ago 30d --untagged" --schedule "0 4 * * Sun" --context /dev/null
```

`/dev/null` is the task's context: there is nothing to build. Neither was run, and the second needs
thought before it is. A filter of `shop:.*` matches the release tags as well, so a release older
than thirty days goes too, unless its tag is locked. **Lock what is deployed**, as Microsoft's
tagging guidance recommends, and purge skips it:

```sh
az acr repository update --name shopregistry --image shop:1.1 --write-enabled false
```

## Deleting by digest, on the laptop

Deletion is the one thing both tools above do, and the registry of section 03 can show it. The
distribution registry deletes only when its configuration allows it, and the image ships with that
switched on:

```
ana@laptop:~/azure$ docker exec registry grep -A1 "delete:" /etc/distribution/config.yml
    delete:
      enabled: true
ana@laptop:~/azure$ curl -s -X DELETE -o /dev/null -w '%{http_code}\n' localhost:5000/v2/shop/manifests/$D
202
ana@laptop:~/azure$ curl -s localhost:5000/v2/shop/tags/list
{"name":"shop","tags":["1.1","latest"]}
ana@laptop:~/azure$ docker pull localhost:5000/shop@$D
Error response from daemon: failed to resolve reference "localhost:5000/shop@sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676": localhost:5000/shop@sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676: not found
```

**The `202` deleted the manifest, and the tags that named it went with it**: `1.0` is gone from the
list, and a pull of the digest that worked a few minutes ago fails, though the image is still on this
laptop, because a pull always asks the registry first. ACR's `az acr repository delete --name
shopregistry --image shop@sha256:…` does the same to a manifest, its tags, and the layers no other
image uses. A deployment that named that digest would now fail to start a new replica, which is why
Microsoft's warnings about both tools tell you not to purge untagged images that something pulls by
digest. Pin a digest that still carries a tag, and lock the tag.

Now switch deletion off with the environment variable that overrides that line of the
configuration. The volume outlived the container, so the data is still there, and the registry
refuses:

```
ana@laptop:~/azure$ docker rm -f registry
registry
ana@laptop:~/azure$ docker run -d --name registry -p 5000:5000 -v shop-registry:/var/lib/registry -e REGISTRY_STORAGE_DELETE_ENABLED=false registry:3 | cut -c1-12
a0aed46776f8
ana@laptop:~/azure$ curl -s localhost:5000/v2/shop/tags/list
{"name":"shop","tags":["1.1","latest"]}
ana@laptop:~/azure$ L=$(curl -s -o /dev/null -w '%header{docker-content-digest}' -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/latest)
ana@laptop:~/azure$ curl -s -w '\n%{http_code}\n' -X DELETE localhost:5000/v2/shop/manifests/$L
{"errors":[{"code":"UNSUPPORTED","message":"The operation is unsupported."}]}

405
```

`405` and `UNSUPPORTED` is the protocol's way of saying the registry does not do this. ACR decides the
same question with roles rather than a file: pulling and pushing are granted separately from
deleting.
