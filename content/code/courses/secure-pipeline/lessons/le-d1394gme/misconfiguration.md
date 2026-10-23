---
title: "Misconfiguration: what a file says, not what runs"
version: 1
---

A vulnerability scan asks whether a package has a known flaw. A misconfiguration scan asks a
different question: **does this file set what it should?** A Dockerfile that never names a user, a
Deployment that allows privilege escalation, a bucket open to the world in Terraform. Trivy's
`config` mode carries a few hundred such checks, and running it on linkbox's repository finds
something in two of its three files:

```
ana@vm:~/linkbox$ trivy config -q --table-mode summary .

Report Summary

┌────────────────────┬────────────┬───────────────────┐
│       Target       │    Type    │ Misconfigurations │
├────────────────────┼────────────┼───────────────────┤
│ Dockerfile         │ dockerfile │         2         │
├────────────────────┼────────────┼───────────────────┤
│ k8s/admission.yaml │ kubernetes │         0         │
├────────────────────┼────────────┼───────────────────┤
│ k8s/linkbox.yaml   │ kubernetes │         4         │
└────────────────────┴────────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

Six findings in a project that lessons 8 to 10 spent three lessons hardening. **Every one of them
needs the same triage as a finding from any other check**, and the Dockerfile's shows why.

### DS-0002: a true statement about the file, and a false one about the image

```
ana@vm:~/linkbox$ trivy config -q Dockerfile

Report Summary

┌────────────┬────────────┬───────────────────┐
│   Target   │    Type    │ Misconfigurations │
├────────────┼────────────┼───────────────────┤
│ Dockerfile │ dockerfile │         2         │
└────────────┴────────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


Dockerfile (dockerfile)
=======================
Tests: 27 (SUCCESSES: 25, FAILURES: 2)
Failures: 2 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 1, CRITICAL: 0)

DS-0002 (HIGH): Specify at least 1 USER command in Dockerfile with non-root user as argument
════════════════════════════════════════
Running containers with 'root' user can lead to a container escape situation. It is a best practice to run containers as non-root users, which can be done by adding a 'USER' statement to the Dockerfile.

See https://avd.aquasec.com/misconfig/ds-0002
────────────────────────────────────────


DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
════════════════════════════════════════
You should add HEALTHCHECK instruction in your docker container images to perform the health check on running containers.

See https://avd.aquasec.com/misconfig/ds-0026
────────────────────────────────────────
```

The high one says the Dockerfile has no `USER` instruction, so the container runs as root. The
first half is true. The second half is not, and the image says so:

```
ana@vm:~/linkbox$ docker inspect --format "{{.Config.User}}" localhost:5000/linkbox:main
65532
ana@vm:~/linkbox$ tail -n 9 Dockerfile
# pip, and a user that is not root.
FROM gcr.io/distroless/python3-debian13:nonroot
COPY --from=build /packages /packages
COPY --from=build --chown=nonroot:nonroot /data /data
COPY app.py settings.py /app/
WORKDIR /app
ENV PYTHONPATH=/packages LINKBOX_DB=/data/linkbox.db
EXPOSE 8000
ENTRYPOINT ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

The image runs as 65532, the `nonroot` user that lesson 8 chose by choosing the base
`gcr.io/distroless/python3-debian13:nonroot`. **The user comes from the base image, and the check
reads only the file in front of it**, so it cannot know. This is a false positive in this project,
in the sense lesson 3 defined: the rule is right in general and wrong about this case.

Two honest ways out exist, and each one is a decision for the record:

- **Make the file say what is true**: add `USER nonroot` to the final stage. The image does not
  change, the finding goes away, and the next person who changes the base to one that runs as root
  keeps a non-root container without having to remember why.
- **Record an exception** with the reason "the base image sets the user", in the way lesson 7
  records exceptions, with an owner and a date.

The first is cheaper and protects against a future mistake, which is why it is usually the better
of the two. This lesson changes no file of the project; lesson 19 comes back to the Dockerfile
with policies written for this project, which check the same thing deliberately.

DS-0026, the low one, asks for a `HEALTHCHECK`. Docker runs that instruction; Kubernetes ignores it
and uses the probes in the Deployment instead. For an image that only ever runs in a cluster, the
finding asks for something nobody would read.

### KSV-0125: whose idea of "trusted"?

The manifest has four. Asking only for the medium one keeps the output short:

```
ana@vm:~/linkbox$ trivy config -q --severity MEDIUM k8s/

Report Summary

┌────────────────┬────────────┬───────────────────┐
│     Target     │    Type    │ Misconfigurations │
├────────────────┼────────────┼───────────────────┤
│ admission.yaml │ kubernetes │         0         │
├────────────────┼────────────┼───────────────────┤
│ linkbox.yaml   │ kubernetes │         1         │
└────────────────┴────────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


linkbox.yaml (kubernetes)
=========================
Tests: 17 (SUCCESSES: 16, FAILURES: 1)
Failures: 1 (MEDIUM: 1)

KSV-0125 (MEDIUM): Container linkbox in deployment linkbox (namespace: linkbox) uses an image from an untrusted registry.
════════════════════════════════════════
Ensure that all containers use images only from trusted registry domains.

See https://avd.aquasec.com/misconfig/ksv-0125
────────────────────────────────────────
 linkbox.yaml:33-58
────────────────────────────────────────
  33 ┌         - name: linkbox
  34 │           image: localhost:5000/linkbox:main
  35 │           ports:
  36 │             - containerPort: 8000
  37 │           env:
  38 │             - name: LINKBOX_TOKEN
  39 │               valueFrom:
  40 │                 secretKeyRef:
  41 └                   name: linkbox
  ..   
────────────────────────────────────────
```

The check says `localhost:5000` is not a trusted registry. Lesson 10 decided the opposite, in
`k8s/admission.yaml`: the cluster accepts images from that registry and from nowhere else. **The
built-in check has a list of registries it trusts, and the project has its own**, so the finding is
a disagreement between two policies, and the project's is the one that is enforced. The three low findings are of the same kind. One is a CPU limit the manifest does not set: it requests CPU and limits memory, a common choice because a CPU limit throttles rather than protects. The other two are a user and group ID the
manifest leaves to the image, which runs as 65532, already above the 10000 the check asks for.

### What a configuration scanner is for

None of the six is a defect that ships. That is not a reason to turn the check off; it is the
normal state of a general-purpose rule set meeting one project's decisions. What the scan earns its
place with is the change nobody intended: the pull request that deletes `readOnlyRootFilesystem`, the
new manifest copied from a blog that runs privileged. Those arrive as **new** findings against a
baseline of six that have already been judged, which is the arrangement lesson 7 built for the
other scanners.

| finding | verdict | why |
|---|---|---|
| DS-0002, no `USER` | false positive here | the base image sets 65532; worth stating in the file anyway |
| DS-0026, no `HEALTHCHECK` | not applicable | Kubernetes uses probes |
| KSV-0125, untrusted registry | the project's policy differs | admission allows only `localhost:5000` |
| KSV-0011, no CPU limit | a choice to write down | memory is limited; CPU is requested, not capped |
| KSV-0020 and 0021, IDs above 10000 | true of the image, unstated in the file | the image's 65532 applies |
