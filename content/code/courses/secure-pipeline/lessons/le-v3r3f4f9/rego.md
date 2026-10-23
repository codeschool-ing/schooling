---
title: Rego, on the Dockerfile
version: 1
---

Rego reads oddly at first: it has no statements that run one after another and no `return`. A rule
is a conclusion, the word `if`, and the conditions under which the conclusion holds. **Every line of a rule's body
must be true for the rule to produce anything, and a line that cannot be evaluated counts as not
true.** That one sentence explains most of what surprises people about the language, and the rules
below lean on it on purpose.

### What conftest sees

Before writing a rule, look at the input it will receive. `conftest parse` prints the JSON a file
becomes. A Dockerfile becomes a list of instructions; filtering out the comments with `jq` leaves
one line per instruction, with its stage number, its command and its arguments:

```
ana@vm:~$ cd ~/linkbox
ana@vm:~/linkbox$ conftest parse Dockerfile | jq -c '.[][] | select(.Cmd != "comment") | [.Stage, .Cmd, .Value]'
[0,"from",["python:3.13-slim@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39","AS","build"]]
[0,"copy",["requirements.txt","/"]]
[0,"copy",["wheels","/wheels"]]
[0,"run",["pip install --no-cache-dir --no-index --find-links /wheels --require-hashes     --target /packages -r /requirements.txt"]]
[0,"run",["mkdir /data"]]
[1,"from",["gcr.io/distroless/python3-debian13:nonroot@sha256:727eccc5d83f11273c954652667b5b5a1c66120bd4cfb884e879ab77dcdf966a"]]
[1,"copy",["/packages","/packages"]]
[1,"copy",["/data","/data"]]
[1,"copy",["app.py","settings.py","/app/"]]
[1,"workdir",["/app"]]
[1,"env",["PYTHONPATH","/packages","=","LINKBOX_DB","/data/linkbox.db","="]]
[1,"expose",["8000"]]
[1,"entrypoint",["python3","-m","gunicorn","--bind","0.0.0.0:8000","app:app"]]
```

Two stages, numbered 0 and 1. Every instruction has a `Cmd` in lower case, a `Value` list holding
its arguments, and the `Stage` it belongs to. Nothing in the input says which user the image will
run as, and that absence is about to matter.

### Two rules for the Dockerfile

Lesson 15 named both base images by digest, and lessons 8 and 9 ran linkbox as an unprivileged user.
The policy makes both decisions checkable. Make a directory called `policy` in the project, which
is where conftest looks by default, and save this as `policy/docker.rego`:

```
package docker

# Rules for linkbox's Dockerfile. conftest hands each Dockerfile to these
# rules as a list of instructions, in order, each with its Cmd ("from",
# "copy", "user"...), its Value and the number of the Stage it belongs to.

# Every FROM names its image by digest. A tag is a name somebody else can
# move to a different image; a digest is the image itself.
deny contains msg if {
	some instr in input
	instr.Cmd == "from"
	image := instr.Value[0]
	not contains(image, "@sha256:")
	msg := sprintf("FROM %s: name the base image by digest (image@sha256:...)", [image])
}

# The stage that becomes the image sets a USER, by number, that is not 0.
# The base image's default user is invisible here, and Kubernetes can only
# check runAsNonRoot against a number.
deny contains msg if {
	not final_user
	msg := "the final stage sets no USER: name a numeric user that is not root"
}

deny contains msg if {
	user := final_user
	not numeric_non_root(user)
	msg := sprintf("USER %s: use a numeric user other than 0, such as 65532", [user])
}

final_stage := max({instr.Stage | some instr in input})

# The last USER of the final stage, which is the one the container runs as.
final_user := users[count(users) - 1] if {
	users := [instr.Value[0] | some instr in input; instr.Stage == final_stage; instr.Cmd == "user"]
	count(users) > 0
}

numeric_non_root(user) if {
	uid := split(user, ":")[0]
	regex.match(`^[0-9]+$`, uid)
	to_number(uid) != 0
}
```

Read it from the top.

**`package docker`** names the rules' namespace. conftest only evaluates the namespace it is told
to, `main` by default, so naming one per kind of file keeps the Dockerfile rules away from the
manifests.

**`deny contains msg if { ... }`** adds `msg` to a set called `deny` whenever every line in the body
holds. conftest reports each message in `deny` as a failure; an empty set is a pass. There are
three `deny` rules, and the set collects the messages of all of them: **separate rules are
alternatives, and the lines inside one rule must all hold together.**

**`some instr in input`** tries each instruction in turn. The first rule therefore says: for some
instruction whose command is `from`, whose image does not contain `@sha256:`, produce a message. Each
FROM that breaks the rule adds its own message.

**`final_user`** is a helper with no `deny` in its name. It collects the USER instructions of the
last stage into a list and takes the last one, because only the last USER of the final stage decides
whom the container runs as. When there is none, the helper is *undefined*, and `not final_user` is
true. That is how Rego says "is missing".

**`numeric_non_root`** splits `65532:65532` at the colon, checks the user part is digits and not 0.
A name such as `nonroot` fails it, and the comment above the rule says why: with `runAsNonRoot` set,
the kubelet refuses to start a container whose image names its user by name, because it cannot tell
which number the name stands for. That refusal was not reproduced here.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l19-rego\" aria-label=\"How conftest reaches a verdict. The Dockerfile is parsed into input, a list of instructions. Each of the three deny rules is evaluated against it: inside a rule every line must hold, and when they all do the rule adds its message to the set deny. The rules are alternatives, so the set collects the messages of all of them. An empty set is a pass and exit status 0; any message is a failure and exit status 1.\"><defs><marker id=\"sp-l19-rego-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"95\" width=\"92\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"58.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Dockerfile</text><path d=\"M104 120 L158 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><text x=\"131\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">parse</text><rect x=\"160\" y=\"90\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">input</text><text x=\"220.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a list of instructions</text><rect x=\"300\" y=\"30\" width=\"215\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"407.5\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"500\" fill=\"var(--paper)\">deny: a FROM without a digest</text><path d=\"M280 120 L288 120 L288 53 L298 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><path d=\"M515 53 L535 53 L535 120 L548 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><rect x=\"300\" y=\"98\" width=\"215\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"407.5\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"500\" fill=\"var(--paper)\">deny: no USER in the final stage</text><path d=\"M280 120 L288 120 L288 121 L298 121\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><path d=\"M515 121 L535 121 L535 120 L548 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><rect x=\"300\" y=\"166\" width=\"215\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"407.5\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"500\" fill=\"var(--paper)\">deny: a USER that is not a number above 0</text><path d=\"M280 120 L288 120 L288 189 L298 189\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><path d=\"M515 189 L535 189 L535 120 L548 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-rego-ah-paper-dim)\"></path><text x=\"407\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">every line of a rule must hold</text><rect x=\"550\" y=\"92\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the set deny</text><text x=\"630.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">one message per rule that held</text><text x=\"630\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">empty: pass, exit 0</text><text x=\"630\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">a message: FAIL, exit 1</text></svg>", "caption": "Lines inside a rule are joined by AND; separate rules are joined by OR, into one set of messages. The set decides the exit status."}
```

### The first run fails

```
ana@vm:~/linkbox$ mkdir policy
ana@vm:~/linkbox$ conftest test --no-color --namespace docker Dockerfile; echo "exit status $?"
FAIL - Dockerfile - docker - the final stage sets no USER: name a numeric user that is not root

3 tests, 2 passed, 0 warnings, 1 failure, 0 exceptions
exit status 1
```

The digest rule passed for both FROM lines. The user rule failed, and exit status 1 is what a
pipeline stage turns into a broken build. `3 tests` is three `deny` rules evaluated against one
file.

The finding surprises people, because linkbox does not run as root. The base image sets its user:

```
ana@vm:~/linkbox$ docker image inspect --format '{{.Config.User}}' gcr.io/distroless/python3-debian13:nonroot
65532
```

**The image runs as 65532, and the file says nothing about it.** That is the limit of any check that
reads the file rather than the image: what the file does not state, it cannot see. The base image
could be swapped for one whose default user is root, by a single changed line, and a review of that
line would show a new digest and nothing about the user.

A second tool agrees. Trivy's configuration scanner, which lesson 11 ran, has a built-in check for
exactly this, and it raises it for the same reason:

```
ana@vm:~/linkbox$ trivy config --quiet --format json Dockerfile | jq -r '.Results[].Misconfigurations[]? | "\(.ID) \(.Severity) \(.Title)"'
DS-0002 HIGH Image user should not be 'root'
DS-0026 LOW No HEALTHCHECK defined
```

DS-0002 is Trivy's version of the rule above. The section on built-in checks returns to the other
line.

### The fix

State the user in the file, by number, in the final stage. The rest of the Dockerfile is lesson 15's;
the comment above the second FROM says why the line is there. Save it as `Dockerfile`:

```dockerfile
# Build: the pinned dependencies, installed from the wheels the pipeline
# downloaded and checked against requirements.txt. The build itself runs
# with no network, so it can read nothing it was not handed.
FROM python:3.13-slim@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39 AS build
COPY requirements.txt /
COPY wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links /wheels --require-hashes \
    --target /packages -r /requirements.txt
RUN mkdir /data

# Run: the same Python and nothing else. No shell, no package manager, no
# pip, and a user that is not root, written here by number although the base
# image already sets it, so that a check reading this file can see it. Both
# images are named by digest, so a tag that moves upstream changes nothing
# here until somebody changes it.
FROM gcr.io/distroless/python3-debian13:nonroot@sha256:727eccc5d83f11273c954652667b5b5a1c66120bd4cfb884e879ab77dcdf966a
COPY --from=build /packages /packages
COPY --from=build --chown=nonroot:nonroot /data /data
COPY app.py settings.py /app/
WORKDIR /app
ENV PYTHONPATH=/packages LINKBOX_DB=/data/linkbox.db
USER 65532:65532
EXPOSE 8000
ENTRYPOINT ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

```
ana@vm:~/linkbox$ conftest test --no-color --namespace docker Dockerfile

3 tests, 3 passed, 0 warnings, 0 failures, 0 exceptions
```

Three rules, three passes. The image this builds is the same as before, since 65532 was already its
user. What changed is that the file now says so, and a change that removes the line or sets it to 0
breaks the build at the first stage that reads it.
