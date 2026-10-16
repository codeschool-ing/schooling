---
title: Immutable tags, and a tag that says which commit
version: 1
---

A repository can refuse to move a tag. With **`IMMUTABLE`** tags, once `1.4.0` points at a digest it
points there for as long as the image exists, and a second push of `1.4.0` is refused. The shop's API
repository is created that way:

```
ana@laptop:~/aws/ecr$ aws ecr create-repository --repository-name shop/api --image-tag-mutability IMMUTABLE --query repository.imageTagMutability
"IMMUTABLE"
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/api --image-tag 1.4.0 --image-manifest file://build-a.json --query image.imageId.imageDigest --output text
sha256:f75f6a0bd9a18e062a99e28be6c7cfd04509c65060939669e110da25bf700ad3
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/api --image-tag 1.4.0 --image-manifest file://build-b.json

aws: [ERROR]: An error occurred (ImageAlreadyExistsException) when calling the PutImage operation: Image with digest 'sha256:f75f6a0bd9a18e062a99e28be6c7cfd04509c65060939669e110da25bf700ad3' and tag '1.4.0' already exists in the repository with name 'shop/api' in registry with id '123456789012'
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/api --image-tag 1.4.1 --image-manifest file://build-b.json --query image.imageId.imageDigest --output text
sha256:29c52796acf6ec53f1dd957d4a08f457f117c5935c785f7cf3cdc30cecd86a94
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/api --image-tag 3f9c2a1b7e40 --image-manifest file://build-b.json --query image.imageId.imageTag --output text
3f9c2a1b7e40
ana@laptop:~/aws/ecr$ aws ecr describe-images --repository-name shop/api --query 'imageDetails[].imageTags' --output text
1.4.0
1.4.1	3f9c2a1b7e40
```

The second push of `1.4.0` carried build B and was refused. moto names the error
`ImageAlreadyExistsException`; ECR calls it `ImageTagAlreadyExistsException`, and the meaning is
the same: **the name is taken, choose another**. Build B went in as `1.4.1` instead, and then took a
second tag, `3f9c2a1b7e40`, the first twelve characters of the commit it was built from, as the
buildspec in lesson 1 tags it. An immutable repository refuses to move a tag and has no objection to
an image carrying several.

That second tag is the useful one. A version number says what a person decided to call a release;
**a commit hash says which code is inside**, and it is what an incident needs at three in the
morning: the image running in production is `3f9c2a1b7e40`, so `git show 3f9c2a1b7e40` is the code
running in production, with nothing to look up. Deploy by that tag, or by the digest itself, and two
tasks of one service can no longer be running different code under the same name.

## When one tag should move

Some teams want one moving tag, for developers' own builds, while everything else stays fixed. ECR
allows that with `IMMUTABLE_WITH_EXCLUSION` and a filter naming the tags that may move:

```
ana@laptop:~/aws/ecr$ aws ecr create-repository --repository-name shop/worker --image-tag-mutability IMMUTABLE_WITH_EXCLUSION --image-tag-mutability-exclusion-filters filterType=WILDCARD,filter='dev-*' --query 'repository.[imageTagMutability,imageTagMutabilityExclusionFilters[0].filter]' --output text
IMMUTABLE_WITH_EXCLUSION	dev-*
```

Tags matching `dev-*` behave as mutable in this repository; every other tag is immutable. **Keep
the filter narrow**: a filter of `*` would make the setting a mutable repository with a longer name.

## Immutable tags and rollback

Immutable tags are also what make a rollback mean something. Rolling back to `1.4.0` is a
deployment that names `1.4.0`, and because the tag cannot have moved, it is the image that ran
before, byte for byte. Lesson 3 builds on exactly that: CodeDeploy's blue/green keeps the previous
task set alive, and the previous task set is defined by the image it names.
