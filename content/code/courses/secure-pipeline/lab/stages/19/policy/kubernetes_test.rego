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
