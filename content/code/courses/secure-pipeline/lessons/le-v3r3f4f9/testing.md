---
title: Testing the policies themselves
version: 1
---

A policy that never fires looks exactly like a policy that is satisfied. Both print a line of
passes, both exit 0, both let the pipeline carry on. **The failure this course has been built
against, a check that silently did not happen, is the natural way for a policy to break**: a typo
in a field name, a helper that is undefined where it should be false, a refactor that changes what
a pattern matches. Every one of those turns a rule into a rule that passes everything, and nothing
on the screen changes.

So a policy needs tests of its own, and Rego has them built in.

### How a Rego test works

A test is a rule whose name starts with `test_`. It passes when its body holds. Inside it, `with
input as ...` replaces the input for that one evaluation. So a test can hand the rules a small,
made-up document and assert what comes out: that `deny` is empty for a good one, or that it contains
one exact message for a bad one. `conftest verify` finds every test in the policy directory and runs
them.

The tests live beside the rules, in their own package, and import the package they test. Save the
Dockerfile rules' tests as `policy/docker_test.rego`:

```
package docker_test

import data.docker

# A Dockerfile the rules accept: both images by digest, a numeric user.
good := [
	{"Cmd": "from", "Stage": 0, "Value": ["python:3.13-slim@sha256:57b2", "AS", "build"]},
	{"Cmd": "run", "Stage": 0, "Value": ["mkdir /data"]},
	{"Cmd": "from", "Stage": 1, "Value": ["gcr.io/distroless/python3-debian13:nonroot@sha256:727e"]},
	{"Cmd": "user", "Stage": 1, "Value": ["65532:65532"]},
]

test_good_dockerfile_passes if {
	count(docker.deny) == 0 with input as good
}

test_a_tag_is_refused if {
	bad := array.concat([{"Cmd": "from", "Stage": 0, "Value": ["python:3.13-slim"]}], array.slice(good, 1, 4))
	docker.deny["FROM python:3.13-slim: name the base image by digest (image@sha256:...)"] with input as bad
}

test_no_user_is_refused if {
	docker.deny["the final stage sets no USER: name a numeric user that is not root"] with input as array.slice(good, 0, 3)
}

# A USER in the build stage says nothing about the image that ships.
test_a_user_in_the_build_stage_does_not_count if {
	bad := array.concat(array.slice(good, 0, 1), [{"Cmd": "user", "Stage": 0, "Value": ["65532"]}, good[2]])
	count(docker.deny) == 1 with input as bad
}

test_root_by_number_is_refused if {
	bad := array.concat(array.slice(good, 0, 3), [{"Cmd": "user", "Stage": 1, "Value": ["0:0"]}])
	docker.deny["USER 0:0: use a numeric user other than 0, such as 65532"] with input as bad
}

test_a_user_name_is_refused if {
	bad := array.concat(array.slice(good, 0, 3), [{"Cmd": "user", "Stage": 1, "Value": ["nonroot"]}])
	docker.deny["USER nonroot: use a numeric user other than 0, such as 65532"] with input as bad
}
```

The input is a list of instructions written by hand, holding only the fields the rules read. Each
test changes one thing in the good Dockerfile and expects one specific message. Asserting the exact
message, not merely that something was denied, catches a rule that fires for the wrong reason.

The fourth test is the one most worth having. A USER in the build stage is easy to write and says
nothing about the image that ships, and a rule that collected every USER regardless of stage would
pass that Dockerfile. The test expects exactly one message, the missing USER, and fails if the build
stage's USER is counted.

And the manifests' tests as `policy/kubernetes_test.rego`:

```
package kubernetes_test

import data.kubernetes

# A container the rules accept, reduced to the fields they read, and the
# Deployment around it. Each test changes one thing and expects one message.
container := {
	"name": "linkbox",
	"image": "localhost:5000/linkbox:main",
	"securityContext": {"readOnlyRootFilesystem": true},
	"resources": {"limits": {"memory": "128Mi"}},
}

deployment(c, pod_security) := {
	"kind": "Deployment",
	"metadata": {"name": "linkbox"},
	"spec": {"template": {"spec": {"securityContext": pod_security, "containers": [c]}}},
}

good := deployment(container, {"runAsNonRoot": true})

test_the_good_deployment_passes if {
	count(kubernetes.deny) == 0 with input as good
}

test_root_is_refused if {
	kubernetes.deny["linkbox: container linkbox does not set runAsNonRoot: true"] with input as deployment(container, {})
}

# The container may say it for itself, and may also undo what the pod says.
test_the_container_can_set_it if {
	c := object.union(container, {"securityContext": {"runAsNonRoot": true}})
	count(kubernetes.deny) == 0 with input as deployment(c, {})
}

test_the_container_can_undo_it if {
	c := object.union(container, {"securityContext": {"runAsNonRoot": false}})
	kubernetes.deny["linkbox: container linkbox does not set runAsNonRoot: true"] with input as deployment(c, {"runAsNonRoot": true})
}

test_a_writable_root_is_refused if {
	c := object.union(container, {"securityContext": {"readOnlyRootFilesystem": false}})
	kubernetes.deny["linkbox: container linkbox does not set readOnlyRootFilesystem: true"] with input as deployment(c, {"runAsNonRoot": true})
}

# A request is not a limit: the container may still grow until the node runs out.
test_a_request_alone_is_refused if {
	c := object.union(object.remove(container, {"resources"}), {"resources": {"requests": {"memory": "64Mi"}}})
	kubernetes.deny["linkbox: container linkbox declares no memory limit"] with input as deployment(c, {"runAsNonRoot": true})
}

test_latest_is_refused if {
	c := object.union(container, {"image": "localhost:5000/linkbox:latest"})
	kubernetes.deny["linkbox: container linkbox uses localhost:5000/linkbox:latest; name a version or a digest"] with input as deployment(c, {"runAsNonRoot": true})
}

# localhost:5000 has a colon too; the tag is what follows the last slash.
test_no_tag_is_refused if {
	c := object.union(container, {"image": "localhost:5000/linkbox"})
	kubernetes.deny["linkbox: container linkbox uses localhost:5000/linkbox; name a version or a digest"] with input as deployment(c, {"runAsNonRoot": true})
}

test_a_digest_passes if {
	c := object.union(container, {"image": "localhost:5000/linkbox@sha256:2c1f"})
	count(kubernetes.deny) == 0 with input as deployment(c, {"runAsNonRoot": true})
}

test_another_registry_is_refused if {
	c := object.union(container, {"image": "docker.io/library/linkbox:main"})
	kubernetes.deny["linkbox: container linkbox pulls docker.io/library/linkbox:main; images come from localhost:5000"] with input as deployment(c, {"runAsNonRoot": true})
}

test_a_binding_that_only_warns_is_refused if {
	binding := {"kind": "ValidatingAdmissionPolicyBinding", "metadata": {"name": "linkbox-deployments"}, "spec": {"validationActions": ["Warn"]}}
	kubernetes.deny["linkbox-deployments: validationActions must include Deny"] with input as binding
}

test_a_policy_that_fails_open_is_refused if {
	policy := {"kind": "ValidatingAdmissionPolicy", "metadata": {"name": "linkbox-deployments"}, "spec": {"failurePolicy": "Ignore"}}
	kubernetes.deny["linkbox-deployments: failurePolicy must be Fail"] with input as policy
}
```

Same shape: one good container and the Deployment around it, built by a function so each test can
change one field. `object.union` merges a change into the container; `object.remove` takes a field
out first when the test needs it gone rather than changed.

### Running them

```
ana@vm:~/linkbox$ conftest verify --no-color

18 tests, 18 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped
```

18 tests, 6 for the Dockerfile and 12 for the manifests. They run in well under a second, which is
why the pipeline stage can afford to run them on every push before it runs the rules.

### A test catching what nothing else would

Here is the kind of edit that breaks a policy silently. Somebody reads `floating`, decides that
looking at the part after the last slash is fussy, and checks the whole image name for a colon
instead. It reads as a simplification:

```
ana@vm:~/linkbox$ sed -i 's/not contains(parts\[count(parts) - 1\], ":")/not contains(image, ":")/' policy/kubernetes.rego
ana@vm:~/linkbox$ git diff --unified=0 policy/
diff --git a/policy/kubernetes.rego b/policy/kubernetes.rego
index 464cc0d..0f85bd5 100644
--- a/policy/kubernetes.rego
+++ b/policy/kubernetes.rego
@@ -56 +56 @@ floating(image) if {
-	not contains(parts[count(parts) - 1], ":")
+	not contains(image, ":")
ana@vm:~/linkbox$ conftest test --no-color --namespace kubernetes k8s/

35 tests, 35 passed, 0 warnings, 0 failures, 0 exceptions
ana@vm:~/linkbox$ conftest verify --no-color
FAIL - policy/kubernetes_test.rego -  - data.kubernetes_test.test_no_tag_is_refused

18 tests, 17 passed, 0 warnings, 1 failure, 0 exceptions, 0 skipped
```

Look at what each command said. **Against the real manifests, the broken policy still passes all 35
tests**, because linkbox's image has a tag and the broken line only matters for an image without
one. Without the tests, this change would merge green and the rule would be dead from that day:
`localhost:5000/linkbox` contains the colon of the port, so the broken rule never sees an image
without a tag again. `conftest verify` names the one test that knows about that case, and its
comment says why it exists.

Put the line back, and both pass:

```
ana@vm:~/linkbox$ git checkout policy/kubernetes.rego
Updated 1 path from the index
ana@vm:~/linkbox$ conftest verify --no-color

18 tests, 18 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped
```

### What is worth a test

Write a test for every message a rule can produce, so each `deny` is seen to fire at least once.
Then one for each case somebody would get wrong when editing the rule: the pod-level setting a
container overrides, the colon in a registry's port, the USER in the wrong stage. Those are the
tests in the files above, and every one of them is a mistake that would otherwise pass in silence.

Commit the tests with the rules they test:

```
ana@vm:~/linkbox$ git add policy
ana@vm:~/linkbox$ git commit -q -m "tests for the policies"
9:38AM INF 0 commits scanned.
9:38AM INF scanned ~5223 bytes (5.22 KB) in 249ms
9:38AM INF no leaks found
```
