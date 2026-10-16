---
title: When a build fails
version: 1
---

Kustomize and Helm move part of the failure from the cluster to the build: many mistakes now show
up as an overlay or a chart that does not render, before anything is applied. Not all of them. Each
case here was produced on purpose, on a working copy that was then thrown away, and the first one is
the kind that renders.

## A patch with nothing to patch

The staging overlay's patch selects its target by kind and name. Here the name has a typo, so the
patch selects nothing:

```
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/staging | grep -c nodePort
1
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-    name: bulletin
+    name: bulletn
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/staging | grep -c nodePort
0
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/staging | kubeconform -strict -summary -kubernetes-version 1.37.0
Summary: 4 resources found parsing stdin - Valid: 4, Invalid: 0, Errors: 0, Skipped: 0
```

**Kustomize built the overlay without a word.** A patch whose selector matches no object is applied
to no object, and that is not an error: the Service came out with the base's ports and no
`nodePort`, so the cluster would pick a port at random and `localhost:8080` would stop answering.
`kubeconform` passed it too, because a Service without a `nodePort` is a perfectly valid Service.

Neither check can know that the patch was meant to match. A check that can is one that asserts
something about the output: here, that staging's Service carries port 30080. One line in
`validate.sh` would do it:

```sh
kubectl kustomize "$work/fleet/apps/bulletin/staging" | grep -q 'nodePort: 30080' || state=failure
```

This course does not add it, because every assertion like this is one more thing to keep true; but
the lesson is the general one. **A build that succeeds proves the files are well formed, not that
they say what you meant.**

## A value the chart requires

The chart says `image.tag` is required, and a values override that sets it to nothing:

```
ana@laptop:~/fleet$ helm template preview charts/bulletin --set image.tag=null
Error: execution error at (bulletin/templates/deployment.yaml:17:50): image.tag is required

Use --debug flag to render out invalid YAML
```

`required` turns a missing value into an error with a message somebody wrote, instead of a
Deployment with the image `localhost:5001/bulletin:`, which would render and apply and fail in the
cluster, one pod at a time.
