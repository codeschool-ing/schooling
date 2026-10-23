---
title: Admission rules of your own, at the Deployment's door
version: 1
---

Pod Security Admission answers one question, how much a pod may do on its node. linkbox's team has two more, both from earlier lessons. **An image must come from the registry the pipeline pushes to,
because only those images went through lesson 8's scan; and a container must declare a memory
limit, because lesson 9 showed what one without does to its neighbours.** Neither is in any Pod
Security profile. A ValidatingAdmissionPolicy is a rule like that, written as an expression in CEL
and evaluated inside the API server, with no program to install. `kubernetes` lesson 25 wrote one
that refused the `latest` tag; this one encodes the pipeline's own guarantees.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"sp-l10-admission\" aria-label=\"What happens to a Deployment on its way into the cluster, and to the pods made from it. kubectl apply sends the Deployment to the API server, which authenticates and authorises the request and then runs admission: the ValidatingAdmissionPolicy checks the Deployment's image and memory limit, and only then is it stored. The ReplicaSet controller then creates pods, and each pod goes through admission of its own: the LimitRange fills in defaults, and Pod Security Admission and the ResourceQuota can refuse it. A refused Deployment gets an error at kubectl; a refused pod only shows as an event.\"><defs><marker id=\"sp-l10-admission-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l10-admission-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"30\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">kubectl apply</text><rect x=\"160\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">API server</text><text x=\"235.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">who is asking, and may they</text><rect x=\"335\" y=\"30\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ValidatingAdmissionPolicy</text><text x=\"450.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the Deployment: registry, memory limit</text><rect x=\"590\" y=\"30\" width=\"115\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stored</text><text x=\"647.5\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">etcd</text><path d=\"M135 55 L158 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M310 55 L333 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M565 55 L588 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M450 80 L450 112\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l10-admission-ah-amber)\"></path><text x=\"450\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">refused: an error at kubectl</text><path d=\"M647 80 L647 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><rect x=\"560\" y=\"170\" width=\"145\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"632.5\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ReplicaSet</text><text x=\"632.5\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">creates each pod</text><rect x=\"390\" y=\"170\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">LimitRange</text><text x=\"465.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">defaults, maximum</text><rect x=\"210\" y=\"170\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Pod Security Admission</text><text x=\"290.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">restricted profile</text><rect x=\"40\" y=\"170\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ResourceQuota</text><text x=\"115.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">namespace total</text><path d=\"M560 195 L542 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M390 195 L372 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M210 195 L192 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M290 220 L290 252\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l10-admission-ah-amber)\"></path><path d=\"M115 220 L115 252\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l10-admission-ah-amber)\"></path><text x=\"205\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">refused: an event, no pod</text></svg>", "caption": "Two doors. The Deployment's is where kubectl hears no; the pods' door refuses later, and only the events say so."}
```

### The policy

Save it as `k8s/admission.yaml`:

```yaml
# Two rules the cluster itself enforces on every Deployment in the linkbox
# namespace, whoever applies it and however: images come from this
# project's registry, and every container declares a memory limit.
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: linkbox-deployments
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
        c.image.startsWith('localhost:5000/'))
      message: images come from the registry at localhost:5000 and nowhere else
    - expression: >-
        object.spec.template.spec.containers.all(c,
        has(c.resources.limits) && 'memory' in c.resources.limits)
      message: every container declares a memory limit
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: linkbox-deployments
spec:
  policyName: linkbox-deployments
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: linkbox
```

The policy says what to check and on which objects: Deployments, when created or updated. Each
`validation` is a CEL expression that must be true, with the message a refused person reads. The
binding switches the policy on, with the action `Deny`, for the namespaces its selector matches:
here the one whose name is `linkbox`, through the label Kubernetes puts on every namespace.

**`failurePolicy: Fail` decides what happens when the policy itself cannot be evaluated**, an
expression error on an object of an unexpected shape, say. `Fail` refuses the object; `Ignore` lets it
in. A guarantee that lapses whenever the check errors is the scanner that did not run of lesson 7,
so it fails closed.

### Apply it, and try it

```
ana@vm:~/linkbox$ kubectl apply -f k8s/admission.yaml
validatingadmissionpolicy.admissionregistration.k8s.io/linkbox-deployments created
validatingadmissionpolicybinding.admissionregistration.k8s.io/linkbox-deployments created
```

An image from anywhere else, Docker Hub here:

```
ana@vm:~/linkbox$ kubectl create deployment other -n linkbox --image=python:3.13-slim
Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "python" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "python" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "python" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "python" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
error: failed to create deployment: deployments.apps "other" is forbidden: ValidatingAdmissionPolicy 'linkbox-deployments' with binding 'linkbox-deployments' denied request: images come from the registry at localhost:5000 and nowhere else
```

linkbox's own image, but created the quick way, with no resources at all:

```
ana@vm:~/linkbox$ kubectl create deployment nolimit -n linkbox --image=localhost:5000/linkbox:main
Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "linkbox" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "linkbox" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "linkbox" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "linkbox" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
error: failed to create deployment: deployments.apps "nolimit" is forbidden: ValidatingAdmissionPolicy 'linkbox-deployments' with binding 'linkbox-deployments' denied request: every container declares a memory limit
```

**Both refused at the moment of `kubectl create`, with the policy's own sentence.** The `Warning`
above each error is Pod Security Admission, which looks at the pod template as the Deployment
passes and says its pods would be refused; it warns and stops nothing, exactly as in the
restricted namespace two sections back, where a Deployment got in and its pods were refused out of
sight. The `error` line is the policy. It matches Deployments, so whoever applies one hears the
refusal directly. The second case also shows how the rules combine: the image passed the first
rule, and the message is the second's.

linkbox's own manifest, applied again, passes both:

```
ana@vm:~/linkbox$ kubectl apply -f k8s/linkbox.yaml
namespace/linkbox unchanged
deployment.apps/linkbox unchanged
service/linkbox unchanged
```

And outside the namespace the binding selects, nothing changes:

```
ana@vm:~/linkbox$ kubectl create deployment other -n default --image=python:3.13-slim --dry-run=server
deployment.apps/other created (server dry run)
```

**`--dry-run=server` sends the object through admission without storing it**, so it is the honest
way to ask "would this be accepted?" The `default` namespace accepts an image from Docker Hub,
because the binding names `linkbox` only. That is a choice, and a cluster that hosts more than one
team usually binds rules like these more widely, with exceptions for the system namespaces.

### What the rules do not say

**`startsWith('localhost:5000/')` checks a name, and a name is not an identity.** Anything pushed to
that registry under any name passes, whether or not the pipeline built it, and the tag `main` moves
with every push. Lesson 14 closes the gap properly, by signing the image in the pipeline and
verifying the signature at admission; until then the rule says "from our registry", which is
narrower than "from anywhere" and wider than "built by us".

And no admission rule sees what the image does once it runs. Admission reads the manifest: the
fields, the names, the numbers. It cannot know that a library inside the image opens a connection
it should not, or that a process writes where it should not; the read-only filesystem and the empty
capability set are what limit that, at runtime. Watching what containers actually do, with a runtime
detector such as Falco, is the next layer, described in Falco's documentation and not run in this
course.
