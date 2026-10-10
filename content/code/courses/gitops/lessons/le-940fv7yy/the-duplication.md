---
title: Two files that are mostly the same file
version: 1
---

**Lesson 5 left staging and production as two complete files**, and the diff between them showed
what each environment is. It did not show what they share, which is most of both:

```
ana@laptop:~/fleet$ wc -l apps/bulletin/*/bulletin.yaml
  46 apps/bulletin/production/bulletin.yaml
  46 apps/bulletin/staging/bulletin.yaml
  92 total
ana@laptop:~/fleet$ diff apps/bulletin/staging/bulletin.yaml apps/bulletin/production/bulletin.yaml | grep -c '^<'
5
```

Two files of 46 lines each that differ in 5 of them, and the other 41 are written
twice. **Every line written twice is a line that will one day be changed once.** A
probe's path, a port, a label added to the Deployment in staging for a test and never carried over:
each one makes production differ from staging in a way nobody chose, and the diff that showed the
release in transit in lesson 5 fills up with them.

Two tools remove the duplication, from opposite directions:

- **Kustomize** starts from plain YAML, a **base**, and describes each environment as a set of
  changes to it, an **overlay**. Nothing is a template; every file in the base is a valid manifest
  on its own. It is built into `kubectl` and into both Argo CD and Flux.
- **Helm** starts from templates with holes in them, a **chart**, and fills the holes from values
  given per installation. It is also a package format and an installer: a chart is versioned and
  published, and an installation is a **release** that Helm tracks and can roll back.

This lesson converts `bulletin` to Kustomize, which suits a team's own application, and then writes
a small Helm chart of the same application, which is how most third-party software arrives.
