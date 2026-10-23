---
title: The manifests, and a violation caught
version: 1
---

Lesson 10 wrote linkbox's Kubernetes manifests with a security context field by field: a pod that
refuses to run as root, a read-only root filesystem, a memory limit, an image from the project's own
registry. Pod Security Admission and the admission policy then enforce some of that on the cluster.
**This policy checks the same manifests before they reach any cluster**, in the commit that changes
them, where the person who broke a rule is the one reading the message.

### The input, and what it adds

`k8s/linkbox.yaml` holds three documents (a Namespace, a Deployment and a Service) and
`k8s/admission.yaml` two more. conftest hands each document to the rules separately, so `input` is
one Kubernetes object at a time, with `kind`, `metadata` and `spec` exactly as written. A rule about
Deployments starts by checking `input.kind` and does nothing for the other four.

Save this as `policy/kubernetes.rego`:

```
package kubernetes

# Rules for the manifests in k8s/. conftest hands each YAML document to
# these rules separately, so input is one object: a Namespace, a
# Deployment, a Service or an admission policy.

deployment if input.kind == "Deployment"

pod := input.spec.template.spec if deployment

containers contains c if {
	some c in pod.containers
}

# Pod Security Admission refuses a pod that may run as root; saying so here
# refuses it before it reaches a cluster. The pod's securityContext counts
# for every container, and a container's own overrides it.
deny contains msg if {
	some c in containers
	not runs_as_non_root(c)
	msg := sprintf("%s: container %s does not set runAsNonRoot: true", [input.metadata.name, c.name])
}

runs_as_non_root(c) if c.securityContext.runAsNonRoot == true

runs_as_non_root(c) if {
	not c.securityContext.runAsNonRoot == false
	pod.securityContext.runAsNonRoot == true
}

deny contains msg if {
	some c in containers
	not c.securityContext.readOnlyRootFilesystem == true
	msg := sprintf("%s: container %s does not set readOnlyRootFilesystem: true", [input.metadata.name, c.name])
}

deny contains msg if {
	some c in containers
	not c.resources.limits.memory
	msg := sprintf("%s: container %s declares no memory limit", [input.metadata.name, c.name])
}

# An image is named by a tag that is not latest, or by digest. A name with
# no tag at all means latest.
deny contains msg if {
	some c in containers
	floating(c.image)
	msg := sprintf("%s: container %s uses %s; name a version or a digest", [input.metadata.name, c.name, c.image])
}

floating(image) if endswith(image, ":latest")

floating(image) if {
	not contains(image, "@")
	parts := split(image, "/")
	not contains(parts[count(parts) - 1], ":")
}

# The same rule the cluster's admission policy enforces, checked here too.
deny contains msg if {
	some c in containers
	not startswith(c.image, "localhost:5000/")
	msg := sprintf("%s: container %s pulls %s; images come from localhost:5000", [input.metadata.name, c.name, c.image])
}

# The admission policy itself. A binding that only warns or audits lets
# every Deployment through, and nothing on the cluster says so; a policy
# that fails open lets them through whenever it cannot be evaluated.
# Kubernetes takes a missing failurePolicy as Fail.
deny contains msg if {
	input.kind == "ValidatingAdmissionPolicyBinding"
	not "Deny" in input.spec.validationActions
	msg := sprintf("%s: validationActions must include Deny", [input.metadata.name])
}

deny contains msg if {
	input.kind == "ValidatingAdmissionPolicy"
	input.spec.failurePolicy != "Fail"
	msg := sprintf("%s: failurePolicy must be Fail", [input.metadata.name])
}
```

Most of it is the shape from the previous section: a helper that picks out what the rules look at,
here every container of a Deployment's pod template, and one `deny` rule per decision. Three details
are worth reading closely.

**`runs_as_non_root` is written twice.** Two definitions of the same helper are alternatives: it
holds if the container says `runAsNonRoot: true` itself, or if the container does not say `false`
and the pod says `true`. That is how Kubernetes resolves the two levels, a container's own setting
overriding the pod's, and a policy that checked only the pod level would pass a container that
quietly switched it off.

**`floating` reads the tag after the last slash.** `localhost:5000/linkbox` contains a colon, in
the registry's port, and still has no tag, which means `latest` to anybody who pulls it. Checking
the whole string for a colon would pass it. The tests in the next section pin that case down.

**The last two rules check the admission policy itself.** A `ValidatingAdmissionPolicyBinding`
whose `validationActions` say `Warn` or `Audit` instead of `Deny` still installs, still appears in
`kubectl get`, and lets every Deployment through. A policy whose `failurePolicy` is `Ignore` lets
them through whenever it cannot be evaluated. Both are one-word edits, and neither shows any symptom
on the cluster. They are exactly the kind of change a review misses and a rule does not.

One more rule repeats a rule lesson 10 already enforces at admission: images come from
`localhost:5000`. That duplication is deliberate, and the last section of this lesson argues it.

### Running it

```
ana@vm:~/linkbox$ conftest test --no-color --namespace kubernetes k8s/

35 tests, 35 passed, 0 warnings, 0 failures, 0 exceptions
```

Seven rules against five documents: 35 tests, all passing. linkbox's manifests already do everything
these rules ask, which is what you would expect from lesson 10, and is the normal state of a policy:
**it is written to pass today and to fail the day somebody changes something.**

### A change that breaks three rules

To watch it fail, make the kind of edit that arrives in a hurry: the container cannot write a cache
file, so somebody makes its root filesystem writable, and to test a local build they point the
image at `linkbox:latest`. `sed` makes both edits, and `git diff` shows them as a reviewer would:

```
ana@vm:~/linkbox$ sed -i 's/readOnlyRootFilesystem: true/readOnlyRootFilesystem: false/; s|localhost:5000/linkbox:main|linkbox:latest|' k8s/linkbox.yaml
ana@vm:~/linkbox$ git diff --unified=0 k8s/
diff --git a/k8s/linkbox.yaml b/k8s/linkbox.yaml
index 9fd9a17..276b8ea 100644
--- a/k8s/linkbox.yaml
+++ b/k8s/linkbox.yaml
@@ -34 +34 @@ spec:
-          image: localhost:5000/linkbox:main
+          image: linkbox:latest
@@ -45 +45 @@ spec:
-            readOnlyRootFilesystem: true
+            readOnlyRootFilesystem: false
ana@vm:~/linkbox$ conftest test --no-color --namespace kubernetes k8s/
FAIL - k8s/linkbox.yaml - kubernetes - linkbox: container linkbox does not set readOnlyRootFilesystem: true
FAIL - k8s/linkbox.yaml - kubernetes - linkbox: container linkbox pulls linkbox:latest; images come from localhost:5000
FAIL - k8s/linkbox.yaml - kubernetes - linkbox: container linkbox uses linkbox:latest; name a version or a digest

35 tests, 32 passed, 0 warnings, 3 failures, 0 exceptions
```

Three messages for two changed lines. The image change breaks two rules at once, the tag and the
registry, and each message says which container and what to do about it. A reviewer looking at the
diff sees two small lines; the policy sees three decisions reversed.

Put the file back, and the policy passes again:

```
ana@vm:~/linkbox$ git checkout k8s/linkbox.yaml
Updated 1 path from the index
ana@vm:~/linkbox$ conftest test --no-color --namespace kubernetes k8s/

35 tests, 35 passed, 0 warnings, 0 failures, 0 exceptions
```

### Commit the policies

The Dockerfile change and both policies go in one commit, so the rule and the line it requires
arrive together:

```
ana@vm:~/linkbox$ git add Dockerfile policy
ana@vm:~/linkbox$ git commit -q -m "policy as code: the Dockerfile and the manifests"
1:55AM INF 0 commits scanned.
1:55AM INF scanned ~4406 bytes (4.41 KB) in 180ms
1:55AM INF no leaks found
```

The three lines after the commit are lesson 6's pre-commit hook scanning the staged files for
secrets, as it does on every commit from here on. Nothing runs these rules on a push yet; the last section of this lesson adds the stage. First, the
rules need tests of their own, because a policy has the same failure mode as any other check in this
course: it can stop working and keep passing.
