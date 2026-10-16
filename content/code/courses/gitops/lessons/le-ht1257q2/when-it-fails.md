---
title: When an artefact cannot be found
version: 1
---

Each of these was produced on purpose against the course's registry.

## A digest that does not exist

A digest that matches nothing, here sixty-four zeros, which is what a digest copied from the wrong
place looks like to the registry:

```
ana@laptop:~/fleet$ docker pull localhost:5001/bulletin@sha256:0000000000000000000000000000000000000000000000000000000000000000
Error response from daemon: failed to resolve reference "localhost:5001/bulletin@sha256:0000000000000000000000000000000000000000000000000000000000000000": localhost:5001/bulletin@sha256:0000000000000000000000000000000000000000000000000000000000000000: not found
```

`not found`. The registry has nothing under that name, and the reason is never a network
problem: a digest either matches content the registry holds or it does not. A pod given that
reference stays in `ErrImagePull` until the reference is fixed.

## A registry without TLS

`helm push` without `--plain-http` against this registry:

```
ana@laptop:~/fleet$ helm push bulletin-0.1.0.tgz oci://localhost:5001/charts
Error: failed to perform "Exists" on destination: Head "https://localhost:5001/v2/charts/bulletin/manifests/sha256:6fcc8b2304d203065ad70cd24737552e697e4a45fe54555d5356e1b1e92f1aa3": http: server gave HTTP response to HTTPS client
```

The client spoke HTTPS and the registry answered in plain HTTP. **The fix here is the flag, because
the registry is on `localhost`.** For anything reachable over a network, the fix is TLS on the
registry, never a client told to skip the check.
