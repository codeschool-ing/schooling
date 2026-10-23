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
