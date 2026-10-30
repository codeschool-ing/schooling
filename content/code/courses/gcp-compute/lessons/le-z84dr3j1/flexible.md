---
title: The flexible environment
version: 1
---

The standard environment runs your code in Google's sandbox, on the runtimes Google offers.
**The flexible environment runs your code in a container, on Compute Engine machines that App
Engine creates and manages for you.** It was the answer, years ago, to everything the sandbox could
not do: any language, native libraries, background threads, writing to local disk.

## What changes in the file

The same `app.yaml`, with one line more and a different shape of scaling:

```yaml
# storefront-flex/app.yaml
runtime: python
env: flex
entrypoint: gunicorn -b :$PORT main:app
runtime_config:
  operating_system: ubuntu22
  runtime_version: "3.12"
resources:
  cpu: 1
  memory_gb: 1
automatic_scaling:
  min_num_instances: 1
  max_num_instances: 3
```

`env: flex` is the switch. `runtime: custom` instead would make App Engine build the `Dockerfile`
in the folder, which is how any language gets in. `resources` sizes the machine in vCPUs and GiB
rather than by class, and **`min_num_instances` cannot be zero**: a flexible service always has at
least one machine running. The application must listen on port 8080, which `$PORT` is set to.
None of this was deployed; the file is the documented shape.

## What it costs to be always on

Flexible instances are billed per vCPU-hour and per GiB-hour for as long as they run, with no
free allowance. Section 03 printed both rates from the sheet, and one instance of the size above, all month, is
their sum over 730 hours:

```
ana@laptop:~/gcp$ python3 -c 'print(round((0.0526 * 1 + 0.0071 * 1) * 730, 2))'
43.58
```

**About 44 dollars a month for one small machine that never scales to zero**, before its disk, and
twice that at the default minimum, which is two instances unless the file says otherwise. Against the standard
environment's free 28 hours a day, the difference is the whole argument: flexible is for an
application that needs it, not a default.

## Why it is mostly history

Everything the flexible environment offered, a container with any language and any library on
Google-managed infrastructure, is what Cloud Run does, with scale to zero, per-request billing and
deployments measured in seconds rather than minutes. Google's own documentation points new
containerised work at Cloud Run and documents a migration path from flexible to it. **A flexible
app you inherit keeps working; a new one has little reason to exist.** Lesson 8 begins Cloud Run.
