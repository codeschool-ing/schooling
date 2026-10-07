---
title: Drift, and how it is found
version: 2
---

**Drift** is the difference that accumulates between environments, or between an environment and
its definition, when changes are made outside the pipeline. A setting edited on one server during an
incident, a package upgraded by hand, a "temporary" fix nobody undid. Each one turns an environment
into a unique object, and a release tested on one no longer says anything about the other.

Here is drift made deliberately. During a sales weekend somebody edits staging's deployed copy by
hand to lower the free-shipping threshold to R$ 190,00, intending to try a promotion, and restarts
it. Nothing goes through the pipeline. Do the same, with one `sed` on the deployed file and the
restart script:

```sh
sed -i 's/FREE_FROM = 19900 /FREE_FROM = 19000 /' ~/envs/staging/current/shipquote/quote.py
ops/restart.sh staging
```

Then the two environments are asked the usual questions:

```
ana@laptop:~/shipquote$ for port in 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done
{"version": "1.5.0", "env": "staging", "carrier": "http://127.0.0.1:9091"}
{"version": "1.5.0", "env": "production", "carrier": "http://127.0.0.1:9092"}
ana@laptop:~/shipquote$ for port in 8200 8300; do curl -s "http://127.0.0.1:$port/quote?cep=69005-010&weight=5000&subtotal=19800"; echo; done
{"cep": "69005-010", "zone": "N", "cents": 0, "price": "R$ 0,00"}
{"cep": "69005-010", "zone": "N", "cents": 3000, "price": "R$ 30,00"}
ana@laptop:~/shipquote$ diff -r -x __pycache__ ~/envs/staging/current ~/envs/production/current
diff -r -x __pycache__ /home/ana/envs/staging/current/shipquote/quote.py /home/ana/envs/production/current/shipquote/quote.py
8c8
< FREE_FROM = 19000         # an order of R$ 199,00 or more ships free
---
> FREE_FROM = 19900         # an order of R$ 199,00 or more ships free
ana@laptop:~/shipquote$ ops/deploy.sh staging dist/shipquote-1.5.0.tar.gz && diff -r -x __pycache__ ~/envs/staging/current ~/envs/production/current && echo "no differences"
smoke: http://127.0.0.1:8200 is up and running 1.5.0
no differences
```

**Both say they are version 1.5.0**, and they are not running the same code: for an order of
R$ 198,00 to Manaus, staging charges nothing and production charges R$ 30,00. `/version` cannot see
the difference, because the stamp comes from the artifact and the edit came after it. Comparing the
two deployed trees can: `diff` names the file and the line. Deploying the artifact again **through
the pipeline** puts staging back, and the same comparison then finds no difference.

## Why drift is dangerous

Drift is invisible from the outside, as the identical `/version` answers show. A team that tests in
staging and finds a different behaviour in production starts debugging the code, when the code is
the one thing that is the same. Worse, the hand edit is lost the next time anybody deploys, so a fix
somebody relied on disappears without a commit to say it ever existed.

## How teams prevent and find it

- **Make the pipeline the only way to change an environment.** The deployed files should not be
  writable by people at all; on container platforms, the image is read-only by construction.
- **Rebuild rather than repair.** An environment that can be recreated from its definition in
  minutes can be recreated whenever it is suspected of drifting.
- **Compare against the definition, routinely.** The `diff` above is the idea; tools for
  infrastructure as code do the same at scale, reporting what differs from what is declared. In the
  `devops` track, `iac` and `gitops` build on exactly this.
- **Report more than the version.** A deployed program can report the hash of its own artifact as
  well as the tag, so two environments claiming the same version can be checked for the same bytes.
