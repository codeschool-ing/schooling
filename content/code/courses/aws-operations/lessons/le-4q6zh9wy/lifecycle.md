---
title: A lifecycle policy, before the bill grows
version: 1
---

Every build pushes an image, and nothing deletes one by itself. A pipeline that runs thirty times a
working day for a year leaves some 6,600 images in the repository, and **almost all of them will
never run again**. ECR charges for each by the gigabyte, so the repository grows into a line on the
bill that nobody chose. The answer is a **lifecycle policy**: rules that expire images, written once
and applied by ECR every day.

## Two rules

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "untagged images go after 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": { "type": "expire" }
    },
    {
      "rulePriority": 2,
      "description": "keep the 30 newest dev builds",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["dev-"],
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": { "type": "expire" }
    }
  ]
}
```

Each rule **selects** images and **expires** what it selected. The first selects untagged images,
which is what a mutable tag leaves behind when it moves, and expires those pushed more than seven
days ago. The second selects images with a tag starting with `dev-` and keeps the 30 newest,
expiring the rest. Images that match neither rule, such as `1.4.0` and the commit-tagged images, are
never touched.

`rulePriority` decides the order, lowest first, and **an image is judged by the first rule that
selects it** and by no later one. That matters when rules overlap: an image tagged both `dev-17` and
`1.4.0` is selected by the second rule and could be expired by it, even though `1.4.0` is a release.
Keep releases and developer builds in separate repositories, or under prefixes no rule shares.

```
ana@laptop:~/aws/ecr$ aws ecr put-lifecycle-policy --repository-name shop/web --lifecycle-policy-text file://lifecycle.json --query repositoryName
"shop/web"
ana@laptop:~/aws/ecr$ aws ecr start-lifecycle-policy-preview --repository-name shop/web 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the StartLifecyclePolicyPreview operation (reached max retries: 2): <!doctype html>
```

moto stores the policy and fails, with an internal error, when asked for a **preview**. On ECR the
preview is the step to take before a policy goes live: `start-lifecycle-policy-preview` evaluates the
rules against the images that exist and lists what would be expired, without expiring anything. A
rule written slightly wrong can expire the image production runs on, and a running task keeps
working until it restarts and finds its image gone. **That preview was not run for this course**, and
it is the one command in this lesson to never skip on a real repository.

## How much it saves

ECR stores each layer once per repository, so a build costs only the layers its predecessors did not
have. If each of the shop's builds adds 40 MB of those (the code and the dependencies that changed;
the base image is shared), 6,600 builds add some 264 GB, about 26 USD a month at ten cents a
gigabyte, and growing every month; under the two rules above the repository holds a few dozen
images. The number is small next to the services that run them. **It is the shape that matters**: a cost that grows by itself every day, from a default
nobody looked at, is what lesson 23 will call an idle resource.
