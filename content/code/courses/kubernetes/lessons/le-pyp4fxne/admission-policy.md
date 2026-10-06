---
title: A rule of your own, at the same door
version: 1
---

Pod Security Standards answer one question, how much a pod may do on its node. Teams have others:
every Deployment must name an owner, no image may come from outside the company's registry, no tag may
be `latest`. **A ValidatingAdmissionPolicy is a rule like that, written as an expression and
evaluated inside the API server**, with no extra program to run.

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: no-latest-tag
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: ["apps"]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["deployments"]
  validations:
  - expression: >-
      object.spec.template.spec.containers.all(c,
        c.image.contains(':') && !c.image.endsWith(':latest'))
    message: "every image needs an explicit tag, and the tag may not be latest"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: no-latest-tag
spec:
  policyName: no-latest-tag
  validationActions: ["Deny"]
```

The policy says what to check and on which objects: Deployments, when created or updated. The
expression is CEL, a small expression language Kubernetes uses wherever it needs a rule in a manifest:
every container's image must contain a colon and must not end in `:latest`. The binding switches it
on, here for the whole cluster, with the action `Deny`.

```
ana@laptop:~/shop$ kubectl apply -f no-latest.yaml
validatingadmissionpolicy.admissionregistration.k8s.io/no-latest-tag created
validatingadmissionpolicybinding.admissionregistration.k8s.io/no-latest-tag created
ana@laptop:~/shop$ kubectl create deployment web --image=nginx:latest
error: failed to create deployment: deployments.apps "web" is forbidden: ValidatingAdmissionPolicy 'no-latest-tag' with binding 'no-latest-tag' denied request: every image needs an explicit tag, and the tag may not be latest
ana@laptop:~/shop$ kubectl create deployment web --image=nginx
error: failed to create deployment: deployments.apps "web" is forbidden: ValidatingAdmissionPolicy 'no-latest-tag' with binding 'no-latest-tag' denied request: every image needs an explicit tag, and the tag may not be latest
ana@laptop:~/shop$ kubectl create deployment web --image=nginx:1.29
deployment.apps/web created
```

`nginx:latest` is refused, and so is plain `nginx`, which means the same thing. `nginx:1.29` is
accepted. The message is the policy's own, which is the point of writing one: the person refused
reads what the rule wants, not a stack trace.

**The expression has a hole.** `registry.local:5000/shop` contains a colon, from the port, and no
tag, so it passes. A rule like this needs a test with every shape of image name the company actually
uses; the capture tried three shapes and missed the fourth. A stricter version checks the part after the last
slash. Policies that need more than an expression, or that change objects instead of refusing them,
are what admission webhooks are for; lesson 45 is about extending the API server in those ways.

| | Pod Security Standards | ValidatingAdmissionPolicy |
|---|---|---|
| written by | the Kubernetes project | you |
| switched on by | a namespace label | a binding |
| checks | pods against three fixed levels | any object, any expression |
| answer | refuse, warn or audit | refuse, warn or audit |
