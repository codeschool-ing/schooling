---
title: Tags, digests and the lifecycle policy
version: 1
---

A tag reads like a version number, and people treat it as one: `shop/web:1.0.0` sounds like a
fixed thing. **A tag is a pointer to a digest, and in a mutable repository any push may move it.**
The digest is the identity. This section moves tags on purpose, shows what each move leaves behind,
then locks the tags and writes the policy that clears up after them.

## A second name for the same image

The previous section put the manifest under `1.0.0`. Putting the same manifest under `latest`
adds a tag and nothing else:

```
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest.json --query image.imageId.imageTag
"latest"
ana@laptop:~/aws$ aws ecr describe-images --repository-name shop/web --query 'imageDetails[].imageTags'
[
    [
        "1.0.0",
        "latest"
    ]
]
```

One image, two tags. On AWS the manifest would come from `aws ecr batch-get-image` rather than a
file, and this is how a release is promoted without pulling or rebuilding anything.

## A tag that moves

The next build changes the page and becomes `1.0.1`, and `latest` follows it:

```
ana@laptop:~/aws$ echo '<h1>shop 1.0.1</h1>' > web/index.html
ana@laptop:~/aws$ docker build -q --provenance=false -t shop/web:1.0.1 web
sha256:b3818ff0782665bab0107a72df92fd0499ff2f18a00c6c64730782287b09adf1
ana@laptop:~/aws$ docker save shop/web:1.0.1 | tar -xO "blobs/sha256/$(docker image inspect --format '{{.Id}}' shop/web:1.0.1 | cut -d: -f2)" > manifest-1.0.1.json
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag 1.0.1 --image-manifest file://manifest-1.0.1.json --query image.imageId.imageTag
"1.0.1"
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest-1.0.1.json --query image.imageId.imageTag
"latest"
ana@laptop:~/aws$ aws ecr describe-images --repository-name shop/web --query 'imageDetails[].[imageDigest,imageTags]'
[
    [
        "sha256:11e030171210d110509505b40732d187e3f6d9523af5a3083263a644563ce41f",
        [
            "1.0.0"
        ]
    ],
    [
        "sha256:f97a4ccc6fcc7520cd5cb6cfcd5e23b61df187e430696c419d7c5822fc062a8d",
        [
            "1.0.1",
            "latest"
        ]
    ]
]
```

**`latest` moved and `1.0.0` stayed**, so there are two images, each with its own digest. Nothing
announced the move. Whoever pulls `latest` tomorrow gets a different program from whoever pulled
it this morning.

Then the case that causes incidents. A fix is built and pushed under the tag that already exists,
`1.0.0`, because the version number "has not changed":

```
ana@laptop:~/aws$ echo '<h1>shop 1.0.0, fixed</h1>' > web/index.html
ana@laptop:~/aws$ docker build -q --provenance=false -t shop/web:1.0.0 web
sha256:51d03afb43cca596ac040a6f522c3bb1b4880cf9f0ce2b28f9ce3d0bff69bd2d
ana@laptop:~/aws$ docker save shop/web:1.0.0 | tar -xO "blobs/sha256/$(docker image inspect --format '{{.Id}}' shop/web:1.0.0 | cut -d: -f2)" > manifest-fixed.json
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag 1.0.0 --image-manifest file://manifest-fixed.json --query image.imageId.imageTag
"1.0.0"
ana@laptop:~/aws$ aws ecr describe-images --repository-name shop/web --query 'imageDetails[].[imageDigest,imageTags]'
[
    [
        "sha256:f97a4ccc6fcc7520cd5cb6cfcd5e23b61df187e430696c419d7c5822fc062a8d",
        [
            "1.0.1",
            "latest"
        ]
    ],
    [
        "sha256:bab3641ecfd1419a8eb5fb8695a638c3888d72ad6a60746c01be2a0e581b78f5",
        [
            "1.0.0"
        ]
    ]
]
```

**The tag now names a third image, and here moto and AWS part ways.** moto deleted the first image
when its last tag left it; it is gone from the list. AWS keeps it, **untagged**: still stored,
still billed, and still pulled by anything that names its digest. Untagged images are where most
of a registry's forgotten storage comes from.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Three pushes to a mutable repository, drawn as three columns, with one row per image. First push: image A tagged 1.0.0 and latest. Second: image B tagged 1.0.1 and latest, and A keeps only 1.0.0. Third: a rebuilt 1.0.0 is image C; A is left untagged on AWS, and moto deletes it.\"><defs><marker id=\"ecr-tags-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"262\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">push 1.0.0, then latest</text><text x=\"432\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">push 1.0.1, move latest</text><text x=\"602\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">rebuild and push 1.0.0</text><path d=\"M180 52 L700 52\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">image A</text><text x=\"20\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">first build</text><text x=\"20\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">image B</text><text x=\"20\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">second build</text><text x=\"20\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">image C</text><text x=\"20\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the rebuilt 1.0.0</text><rect x=\"187\" y=\"79\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"262\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1.0.0  latest</text><rect x=\"357\" y=\"79\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"432\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.0.0</text><rect x=\"527\" y=\"71\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"602\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">untagged, still stored</text><text x=\"602\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">moto deletes it instead</text><rect x=\"357\" y=\"149\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"432\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1.0.1  latest</text><rect x=\"527\" y=\"149\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.0.1  latest</text><rect x=\"527\" y=\"219\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"602\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1.0.0</text></svg>", "caption": "A tag is a pointer, and in a mutable repository every push may move one. The image a tag leaves behind stays on AWS with no tag at all: still billed, and still pulled by anything that names its digest."}
```

Picture a Kubernetes Deployment, the subject of lesson 11, whose pods name `shop/web:1.0.0`. A
node that pulled the tag before the overwrite keeps its copy, because for any tag but `latest`
Kubernetes pulls only when the image is not on the node already; a node added afterwards pulls the
third image. Two programs answer behind one Service, under one version number, and no log says so.
ECS guards against the same thing inside one deployment: since 2024 it resolves the tag to a
digest when a deployment starts, so every task of that deployment runs one image. The next
deployment, even one started only to restart the tasks, picks up whatever the tag points at by
then.

There are two ways out, and they work together:

- **Make tags immutable**, so a tag, once pushed, names one image forever.
- **Deploy by digest**: `shop/web@sha256:` followed by the 64 characters. A task definition and a
  Kubernetes manifest both accept that form, and a digest cannot move, because it is computed from
  the bytes.

## Locking the tags

```
ana@laptop:~/aws$ aws ecr put-image-tag-mutability --repository-name shop/web --image-tag-mutability IMMUTABLE
{
    "registryId": "123456789012",
    "repositoryName": "shop/web",
    "imageTagMutability": "IMMUTABLE"
}
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag 1.0.1 --image-manifest file://manifest-fixed.json

aws: [ERROR]: An error occurred (ImageAlreadyExistsException) when calling the PutImage operation: Image with digest 'sha256:f97a4ccc6fcc7520cd5cb6cfcd5e23b61df187e430696c419d7c5822fc062a8d' and tag '1.0.1' already exists in the repository with name 'shop/web' in registry with id '123456789012'
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest-fixed.json

aws: [ERROR]: An error occurred (ImageAlreadyExistsException) when calling the PutImage operation: Image with digest 'sha256:f97a4ccc6fcc7520cd5cb6cfcd5e23b61df187e430696c419d7c5822fc062a8d' and tag 'latest' already exists in the repository with name 'shop/web' in registry with id '123456789012'
```

Both pushes were refused, and the tags stay where they were. AWS refuses them too, **with a
different error name**. ECR's API reference answers a tag that already exists in an immutable
repository with `ImageTagAlreadyExistsException`. It keeps `ImageAlreadyExistsException`, the name
moto used, for pushing the same manifest under the same tag a second time. A pipeline that
matches on the error name has to match AWS's.

Locking `latest` as well is sometimes too much: some tools expect a tag that moves. **ECR now accepts
exclusion filters**, tags that stay mutable inside an immutable repository:

```
ana@laptop:~/aws$ aws ecr put-image-tag-mutability --repository-name shop/web --image-tag-mutability IMMUTABLE_WITH_EXCLUSION --image-tag-mutability-exclusion-filters filterType=WILDCARD,filter=latest
{
    "registryId": "123456789012",
    "repositoryName": "shop/web",
    "imageTagMutability": "IMMUTABLE_WITH_EXCLUSION"
}
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest-fixed.json --query image.imageId.imageTag
"latest"
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag 1.0.1 --image-manifest file://manifest-fixed.json

aws: [ERROR]: An error occurred (ImageAlreadyExistsException) when calling the PutImage operation: Image with digest 'sha256:f97a4ccc6fcc7520cd5cb6cfcd5e23b61df187e430696c419d7c5822fc062a8d' and tag '1.0.1' already exists in the repository with name 'shop/web' in registry with id '123456789012'
```

`latest` moved, and `1.0.1` is still refused. `MUTABLE_WITH_EXCLUSION` is the mirror image: a
mutable repository with a list of tags that may not move.

## The lifecycle policy

Every push stores layers, and nothing in ECR deletes them on its own. A repository that a pipeline
pushes to ten times a day for a year holds thousands of images, almost none of which anybody will
pull again. **A lifecycle policy is the repository's own rule for what to delete.** This one keeps
the recent releases, gives the builds of pull requests two weeks, and removes untagged images after
a week:

```schooling-example
{"language": "json", "file": "lifecycle.json", "parts": [{"code": "{\n  \"rules\": [\n", "note": "A lifecycle policy is one JSON document per repository: a list of rules. ECR reads them in order of `rulePriority`, lowest first, and **an image is expired by one rule at most**."}, {"code": "    {\n      \"rulePriority\": 1,\n      \"description\": \"Untagged images go a week after they were pushed\",\n      \"selection\": {\n        \"tagStatus\": \"untagged\",\n        \"countType\": \"sinceImagePushed\",\n        \"countUnit\": \"days\",\n        \"countNumber\": 7\n      },\n      \"action\": { \"type\": \"expire\" }\n    },\n", "note": "Untagged images are what a moved tag leaves behind. `sinceImagePushed` counts their age in `countUnit` days. A week gives somebody time to notice that a deployment still names one of them by digest."}, {"code": "    {\n      \"rulePriority\": 2,\n      \"description\": \"Pull request images go after 14 days\",\n      \"selection\": {\n        \"tagStatus\": \"tagged\",\n        \"tagPatternList\": [\"pr-*\"],\n        \"countType\": \"sinceImagePushed\",\n        \"countUnit\": \"days\",\n        \"countNumber\": 14\n      },\n      \"action\": { \"type\": \"expire\" }\n    },\n", "note": "Tags beginning `pr-` are the throwaway builds of pull requests. `tagPatternList` takes wildcards, and `*` stands for any run of characters."}, {"code": "    {\n      \"rulePriority\": 3,\n      \"description\": \"Keep the 30 most recent releases\",\n      \"selection\": {\n        \"tagStatus\": \"tagged\",\n        \"tagPatternList\": [\"*.*.*\"],\n        \"countType\": \"imageCountMoreThan\",\n        \"countNumber\": 30\n      },\n      \"action\": { \"type\": \"expire\" }\n    }\n", "note": "The releases: every tag shaped like `1.4.2`. `imageCountMoreThan` keeps the 30 most recently pushed and expires the rest, oldest first, however young they are."}, {"code": "  ]\n}\n", "note": "Nothing else is touched. An image whose only tag is `latest` matches none of the three rules and stays. A rule with `tagStatus` `any` would catch it, and AWS requires such a rule to have the highest `rulePriority` of all, so that it is read last."}]}
```

Save it as `~/aws/lifecycle.json` with the copy button, and attach it to the repository:

```
ana@laptop:~/aws$ aws ecr put-lifecycle-policy --repository-name shop/web --lifecycle-policy-text file://lifecycle.json --query repositoryName
"shop/web"
ana@laptop:~/aws$ aws ecr get-lifecycle-policy --repository-name shop/web --query lifecyclePolicyText --output text | jq -c '.rules[] | [.rulePriority, .selection.tagStatus, .selection.countType, .selection.countNumber]'
[1,"untagged","sinceImagePushed",7]
[2,"tagged","sinceImagePushed",14]
[3,"tagged","imageCountMoreThan",30]
ana@laptop:~/aws$ aws ecr start-lifecycle-policy-preview --repository-name shop/web

aws: [ERROR]: An error occurred (500) when calling the StartLifecyclePolicyPreview operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

moto stored the policy and read the three rules back, and then could not preview it: the internal
error is moto's own failure, and not something AWS answers. **On AWS the preview is the step to
take before applying a policy to a repository with real images in it.**
`start-lifecycle-policy-preview` evaluates the rules without expiring anything, and
`get-lifecycle-policy-preview` lists the images they would remove. Once a policy is attached, AWS
documents that a matching image expires within 24 hours.

Expiring is deleting. The storage stops, and so does every pull of that image, including a
deployment that names it by digest. That is why the first rule waits a week rather than a day.
The images it removes are exactly the ones a tag has left behind, and a service pinned to one of
them by digest would fail to start a new task the day after.
