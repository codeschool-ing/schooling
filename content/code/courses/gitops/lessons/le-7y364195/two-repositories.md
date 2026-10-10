---
title: The application's repository and the cluster's
version: 1
---

**`bulletin`'s source has lived in `~/bulletin` since lesson 1, in no repository at all.** That was
fine while the course was about the cluster's side. It is not fine for a real application, and
where it should go is the first decision of a layout: in `fleet`, or in a repository of its own?

## Two repositories, and why

The common answer, and this course's, is **two**: one for the application's source, one for the
desired state of the cluster. The reasons are the axes of the last section.

- **They change at different speeds.** A busy application gets dozens of commits a day; the cluster's
  repository gets one when a release is promoted. Mixed in one history, every promotion is buried
  under code changes, and every code change wakes the agent for nothing.
- **They have different owners.** Developers write the application; the people who run production
  approve what reaches it. Lesson 2's protection rule on `fleet` is a rule about production, and it
  should not slow down every commit to the application's code.
- **They meet at one point, the image.** The application's CI builds an image from a tagged commit
  and pushes it to a registry. Promoting that image is a pull request to `fleet` that changes one
  reference. That is the whole interface between them, and it is narrow on purpose.

A single repository for both, a monorepo, works for small teams and is a legitimate choice. Its
cost is that the separation above has to be made by paths and rules inside one repository rather
than by the repository boundary.

## `bulletin` gets its repository

Same steps as `fleet` in lesson 2, without the protection rule, which a code repository may or
may not want:

```
ana@laptop:~/bulletin$ git init --quiet
ana@laptop:~/bulletin$ git add index.cgi Dockerfile
ana@laptop:~/bulletin$ git commit --quiet -m "bulletin 1.0"
ana@laptop:~/bulletin$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"name": "bulletin", "private": true}' http://localhost:3000/api/v1/user/repos | jq .full_name
"ana/bulletin"
ana@laptop:~/bulletin$ git remote add origin http://localhost:3000/ana/bulletin.git
ana@laptop:~/bulletin$ git push --quiet -u origin main
ana@laptop:~/bulletin$ git tag v1.0
ana@laptop:~/bulletin$ git push --quiet origin v1.0
ana@laptop:~/bulletin$ git ls-remote --tags origin
9f0914e23a1b50d15524e840ebeb3d09d8c2bb2a	refs/tags/v1.0
```

The tag `v1.0` is the commit the image `bulletin:1.0` was built from. **A tag in the application's
repository, an image tag in the registry, and a reference in `fleet`, all saying 1.0**: from any one
of the three you can find the other two, and lesson 12 follows that chain backwards.
