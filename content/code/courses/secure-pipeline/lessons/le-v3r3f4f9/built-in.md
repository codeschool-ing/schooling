---
title: Trivy's built-in checks beside your own
version: 1
---

You did not have to write any of this from nothing. Trivy, which this course has used since lesson
8 for images, ships a library of configuration checks for Dockerfiles, Kubernetes manifests,
Terraform, CloudFormation and more, and `trivy config` runs them. They are written in Rego too, the
same language as your policy. **So the question is not which tool, but whose rules**: a library
written by people who have never seen your project, or a handful written by the people who made its
decisions.

### The built-in checks on linkbox, after the fix

```
ana@vm:~/linkbox$ trivy config --quiet --format json . | jq -r '.Results[] | .Target as $t | .Misconfigurations[]? | "\($t)  \(.ID) \(.Severity) \(.Title)"'
Dockerfile  DS-0026 LOW No HEALTHCHECK defined
k8s/linkbox.yaml  KSV-0011 LOW CPU not limited
k8s/linkbox.yaml  KSV-0020 LOW Runs with UID <= 10000
k8s/linkbox.yaml  KSV-0021 LOW Runs with GID <= 10000
k8s/linkbox.yaml  KSV-0125 MEDIUM Restrict container images to trusted registries
```

Five findings from two files. Each is worth reading against what this project already decided,
because using a built-in library well comes down to that comparison:

| check | what it says | against this project's decisions |
|---|---|---|
| DS-0026 | no HEALTHCHECK in the Dockerfile | Kubernetes ignores a Dockerfile's HEALTHCHECK and uses its own probes, so on this deployment the line would do nothing. A decision, not an oversight |
| KSV-0011 | no CPU limit | lesson 10's manifest has a CPU request and a memory limit, and no CPU limit: a CPU limit throttles a process even when cores sit idle. A choice with an argument |
| KSV-0020, KSV-0021 | the manifest sets no `runAsUser` or `runAsGroup` above 10000 | the image runs as 65532, which is above 10000, but the manifest does not say so. The same blindness as DS-0002 had for the Dockerfile |
| KSV-0125 | the image comes from an untrusted registry | Trivy's list of trusted registries does not include `localhost:5000`, which is the only registry this project trusts. Wrong for this project |

Before the fix in this lesson there was a sixth, DS-0002, the missing USER that your own rule
found. That one overlapped exactly: two tools, one finding, one fix.

### Where they overlap, and where they do not

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" data-fig=\"sp-l19-overlap\" aria-label=\"A table of rules against two sources of checks. Both your policy and Trivy's built-in checks cover: the Dockerfile user (DS-0002), runAsNonRoot (KSV-0012), a read-only root filesystem (KSV-0014), a memory limit (KSV-0018) and no latest tag (KSV-0013). Only your policy covers base images by digest (Trivy checks only for the latest tag, DS-0001) and the admission binding saying Deny. For images from localhost:5000 Trivy disagrees and flags it (KSV-0125). Only Trivy covers HEALTHCHECK, a CPU limit and a UID above 10000.\"><defs></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what is checked</text><text x=\"335\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">where</text><text x=\"435\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">policy/ (yours)</text><text x=\"595\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Trivy built-in</text><rect x=\"12\" y=\"40\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">base image by digest</text><text x=\"435\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><text x=\"595\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">only :latest (DS-0001)</text><text x=\"335\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">yours only</text><rect x=\"12\" y=\"76\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Dockerfile USER not root</text><text x=\"435\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><text x=\"595\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">DS-0002</text><text x=\"335\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">both</text><rect x=\"12\" y=\"112\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">runAsNonRoot</text><text x=\"435\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><text x=\"595\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">KSV-0012</text><text x=\"335\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">both</text><rect x=\"12\" y=\"148\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read-only root filesystem</text><text x=\"435\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><text x=\"595\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">KSV-0014</text><text x=\"335\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">both</text><rect x=\"12\" y=\"184\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">memory limit</text><text x=\"435\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><text x=\"595\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">KSV-0018</text><text x=\"335\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">both</text><rect x=\"12\" y=\"220\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">no :latest</text><text x=\"435\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><text x=\"595\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">KSV-0013</text><text x=\"335\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">both</text><rect x=\"12\" y=\"256\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"271\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">images from localhost:5000</text><text x=\"435\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><text x=\"595\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">flags it (KSV-0125)</text><text x=\"335\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">they disagree</text><rect x=\"12\" y=\"292\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"307\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">admission binding says Deny</text><text x=\"435\" y=\"307\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><text x=\"595\" y=\"307\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><text x=\"335\" y=\"307\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">yours only</text><rect x=\"12\" y=\"328\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"343\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HEALTHCHECK, CPU limit, UID above 10000</text><text x=\"435\" y=\"343\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"595\" y=\"343\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">DS-0026, KSV-0011, -0020, -0021</text><text x=\"335\" y=\"343\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Trivy only</text></svg>", "caption": "The general rules are in both. The rules that know this project, its registry, its digests, its admission policy, are only in yours."}
```

Four of Trivy's checks on the manifest ask what four of your rules ask, and they pass for the same
reasons:

```
ana@vm:~/linkbox$ trivy config --quiet --include-non-failures --format json k8s/linkbox.yaml | jq -r '.Results[].Misconfigurations[] | select(.Status == "PASS") | "\(.ID) \(.Title)"' | grep -E '^KSV-00(12|13|14|18) '
KSV-0012 Runs as root user
KSV-0013 Image tag ":latest" used
KSV-0014 Root file system is not read-only
KSV-0018 Memory not limited
```

**The overlap is large on the general rules and empty on the ones about this project.** Trivy's
library is mostly general rules nobody on a small team would think to write, and it is the right
place to look for ideas: KSV-0020 is a fair point, and adding
`runAsUser: 65532` to the manifest would answer it the same way `USER 65532:65532` answered DS-0002. Your own rules know things no library can: that
`localhost:5000` is the registry, that this project uses digests, that the admission binding must
say `Deny`. KSV-0125 does not merely miss that; it gets it backwards.

### Why the pipeline gates on your rules, not on the library

The pipeline stage in the next section runs conftest, and `trivy config` stays a tool you run when
you want a second opinion. Three reasons, each from an earlier lesson:

- **A gate must fail only for what someone should fix** (lesson 7). Of the five findings above, two
  are decisions already taken and one is wrong for this project, and a gate that fails on them would
  be overridden by Friday. Trivy
  can be told to skip checks with a `.trivyignore` file, but that is a list of the library's
  opinions you disagree with, and it grows.
- **The library changes under you.** `trivy config` downloads its checks bundle when it runs, the
  first time and again when a newer one is published, so a new check can break a build that changed
  nothing. That is right for vulnerability data, which lesson 8 pinned to one database for the
  recording, and awkward for a rule about how this project is configured.
- **A policy is a decision, and decisions are reviewed.** A rule in `policy/` arrived in a commit
  that somebody approved, with a message saying why. A check added to a library upstream did not.

None of this makes the built-in checks less useful. Read their output when a manifest or Dockerfile
changes much, adopt what you agree with as a rule of your own, with a test, and write down why you
disagree with the rest. Trivy also runs your own Rego beside its built-ins if you point it at a
directory of policies (`--config-check`), which is worth knowing if you would rather have one tool
than two. This course keeps them apart so the difference stays visible.

### Not every rule is a configuration check

Some decisions cannot be read from a file at all. Whether the image that runs is the image that
was signed (lesson 14), whether a dependency has an advisory (lesson 5), whether the running
container actually drops its capabilities (lesson 9): those need the artefact, a database or the
running system. A policy over files checks what was declared, and that is worth checking because
declarations are cheap to change and easy to get wrong. It does not check what happened.
