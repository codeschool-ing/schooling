---
title: What reduces it, starting with the free things
version: 1
---

The remedies for a cold start are usually listed with the paid ones first, because they are
products with names. **Most cold starts are shortened most cheaply by changing what the module
does at import**, and the order below goes from what costs nothing to what is billed by the second,
which is the order to try them in.

## Find out where the time goes

Before removing anything, measure what the import is made of. Python can time every import it
does, with `-X importtime`, and the Lambda image has the same interpreter and the same `boto3` as
the function runs with. The last column is the module, indented by depth.
The middle one is
the total time in microseconds including everything that module imported in turn:

```
ana@laptop:~/aws$ docker run --rm --entrypoint python3 public.ecr.aws/lambda/python:3.12 -X importtime -c 'import boto3' 2>&1 | sort -t'|' -k2 -n | tail -5
import time:       248 |     123203 |         botocore.waiter
import time:       784 |     154090 |       botocore.client
import time:       821 |     160525 |     botocore.session
import time:       578 |     166905 |   boto3.session
import time:       399 |     221273 | boto3
```

**`import boto3` alone is 221,273 microseconds, about 221 ms**, and most of
it is `botocore`, the layer underneath that knows every AWS API. The rest of the
301 ms that `eager` spent in the previous section was building the client. The same
command on your own module, run inside the image, points at the import that is slow, which is
nearly always one somebody did not know was there.

## Import less, and import it once

Three changes cost nothing but care.

- **Import what the function uses.** A module that imports a whole framework to call one helper
  pays for the framework on every cold start. The same goes for a data library imported "in case".
- **Build clients and connections at the top of the file**, as the previous section measured:
  paid once in the init phase, reused by every warm request.
- **Keep the package small.** On AWS the code is fetched during the init phase, so megabytes the
  function never imports still have to arrive. The emulator mounts the code from your disk and
  cannot show this part; it is AWS's documented behaviour and not run here.

That last point has a trade-off inside it, visible in the image itself:

```
ana@laptop:~/aws$ docker run --rm --entrypoint python3 public.ecr.aws/lambda/python:3.12 -c 'import boto3; print(boto3.__version__)'
1.35.92
ana@laptop:~/aws$ docker run --rm --entrypoint du public.ecr.aws/lambda/python:3.12 -sh /var/lang/lib/python3.12/site-packages/boto3 /var/lang/lib/python3.12/site-packages/botocore
1.6M	/var/lang/lib/python3.12/site-packages/boto3
27M	/var/lang/lib/python3.12/site-packages/botocore
```

The runtime ships `boto3` 1.35.92, and `botocore` beneath it is 27 MB
on disk. A function that relies on it carries nothing extra. AWS's own advice is nevertheless to
package the SDK version you tested with, because the runtime's copy is updated by AWS on its own
schedule, and a function whose behaviour changes when somebody else upgrades a library is a
function nobody can reproduce. **Packaging the SDK buys a fixed version at the price of about
27 MB more to download on every cold start**; which matters more is a decision about
the function, not a rule.

## Memory, which is also CPU

The previous section showed init slowing as the CPU shrank, and on Lambda the CPU comes with the
memory setting. Raising memory therefore shortens a CPU-bound cold start, and **it does not
necessarily cost more, because the price is per gigabyte-second.** The sheet's on-demand price
for x86 in sa-east-1 is 0.0000166667 USD per GB-second, so a request of 800 ms at 512 MB uses
0.5 × 0.8 = 0.4 GB-seconds, and the same request at 1,024 MB, if the extra CPU halves it to
400 ms, uses 1 × 0.4 = 0.4 GB-seconds: the same 0.0000066667 USD. That only holds while the work
speeds up in proportion. A function that spends its time waiting on a database gains nothing from
more CPU and pays twice as much per second.

**Arm** is the other line on the sheet: 0.0000133334 USD per GB-second for Graviton against
0.0000166667 for x86, a fifth less for every second of init and of handler. AWS does not promise
a faster cold start on Arm, and nothing here can measure one, because the laptop and the image
are x86; a library with compiled parts also needs its Arm build. Lesson 14 sets the architecture
and lesson 23 weighs the price.

## What these leave

Done well, the free changes bring a Python cold start close to the runtime's own, the
48 ms of the bare handler on this laptop plus what AWS adds to place the
environment and fetch the code. **For a queue consumer or a nightly job that is the end of the
matter**: nobody is waiting on the first request. For an API where a person is, the remaining
cold start is what the next section pays to remove.
