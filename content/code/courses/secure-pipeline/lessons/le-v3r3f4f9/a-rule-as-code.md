---
title: A rule that runs, not a page that is read
version: 1
---

Most organisations already have security policies. They live on a wiki page with a title like
"Container standards", and they say sensible things: images come from the internal registry, nothing
runs as root, every container has a memory limit. The page is read once, by a new developer in their
first week, and enforced at code review by whoever happens to remember it. **A rule that depends on
somebody remembering it is enforced on the days they do.** Nothing tells you when the page and the
repositories stopped agreeing, and on a platform with a hundred services they stopped agreeing long
ago.

Policy as code moves the rule out of the page and into the repository, in a language a machine
evaluates. Four things change, and each is one this course has already relied on somewhere:

| a rule on a page | a rule as code |
|---|---|
| edited by whoever has wiki access, with no review | changed in a commit, reviewed like any line of code |
| enforced by memory | evaluated on every push, by the pipeline |
| nobody knows whether it still matches what it was meant to catch | has tests of its own, which fail when it stops refusing what it should |
| applies when somebody checks | refuses at a point where refusing costs little: before merge, before deploy |

You have written policy as code twice already. Lesson 7's gate is one: a rule about which findings
break the build, in a file with tests. Lesson 10's admission policy is another: two rules in CEL that
the cluster applies to every Deployment. This lesson adds a general engine, so the same kind of rule
can be written about any file that describes how something is built or run.

### OPA, Rego and conftest

**Open Policy Agent (OPA)** is an engine that takes two things, a document in JSON and a set of
rules, and answers with a decision. It knows nothing about Kubernetes or Dockerfiles; it evaluates
rules over whatever JSON it is given. That generality is why it turns up in several places: as
**Gatekeeper**, an admission controller for Kubernetes; inside services that ask it whether a
request is allowed; and in CI, through conftest.

**Rego** is the language the rules are written in. It is declarative: a rule says what must be true
for a conclusion to hold, and the engine works out whether it does. The next section reads one rule
at a time.

**Conftest** is a command-line tool built on OPA for checking configuration files. It parses a file
into JSON (YAML, a Dockerfile, HCL, TOML, INI and twenty or so other formats), evaluates every rule
in a policy directory against it, prints what failed, and exits with 1 if anything did. That exit
status is all a pipeline stage needs.

The files this lesson checks are the ones in linkbox that say how it is built and how it runs: the
`Dockerfile` and the manifests in `k8s/`. They are the project's infrastructure, written down, and
checking them before anything is built or applied is what "infrastructure checks" means here. The
same approach covers Terraform, Helm values or a CI workflow, with a parser for each.

### Installing conftest

Conftest is one binary, released on GitHub with a checksum file beside it. On Linux, from your home
directory:

```
ana@vm:~$ curl -fsSLO https://github.com/open-policy-agent/conftest/releases/download/v0.71.0/conftest_0.71.0_Linux_x86_64.tar.gz
ana@vm:~$ curl -fsSL https://github.com/open-policy-agent/conftest/releases/download/v0.71.0/checksums.txt | grep ' conftest_0.71.0_Linux_x86_64.tar.gz$' | sha256sum --check
conftest_0.71.0_Linux_x86_64.tar.gz: OK
ana@vm:~$ tar -xzf conftest_0.71.0_Linux_x86_64.tar.gz conftest
ana@vm:~$ install -m 755 conftest ~/.local/bin/
ana@vm:~$ rm conftest conftest_0.71.0_Linux_x86_64.tar.gz
ana@vm:~$ conftest --version
Conftest: 0.71.0
OPA: 1.21.0
```

The same release page has builds for macOS and Windows, and Homebrew installs it with
`brew install conftest`. The version matters for one reason: conftest 0.71 runs OPA 1.21 and reads
**Rego v1**, the syntax every rule in this lesson uses. Older guides on the web write rules as
`deny[msg] { ... }`, which is Rego v0, and a current conftest refuses them unless told otherwise.
If an example you find fails to parse, that is the first thing to check.

### What makes a good rule to write

Not every line of a standards page should become code. A rule earns its place when three things are
true:

- **A file can show it.** "Images come from the internal registry" is visible in a manifest. "Code is
  reviewed by somebody who understands it" is not, and no parser will make it so.
- **The answer is yes or no.** "A memory limit is declared" is a check. "The memory limit is
  sensible" needs a person, or a number nobody can defend.
- **Somebody is hurt when it is broken.** A rule that refuses tabs in YAML wastes everybody's time
  and teaches them to ignore the stage, the alert fatigue lesson 7 described.

The rules this lesson writes all pass that test. Each one corresponds to a decision an earlier
lesson made and argued: digests in lesson 15, the unprivileged user in lessons 8 and 9, the
security context and limits in lesson 10. **Policy as code does not invent the policy.** It makes
the decisions already taken stay taken.
