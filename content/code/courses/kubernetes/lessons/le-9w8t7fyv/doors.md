---
title: The other doors in the API server
version: 1
---

A second scheduler is one way to put your own code into a cluster's decisions. There are three more,
and they differ in where your code runs and what happens when it is down.

| Door | Your code is | Asked when | If it is down |
| --- | --- | --- | --- |
| Scheduler extender | an HTTP service | after filter and score, for every pod of the profile | its `ignorable` field decides: fail the pod or carry on |
| Admission webhook | an HTTPS service | on every write the configuration matches | `failurePolicy` decides: refuse the write or let it through |
| ValidatingAdmissionPolicy | an expression inside the API server | on every write the binding matches | it cannot be down |
| Aggregated API | a whole API server behind a Service | on every request for its API group | that group answers with an error |

**The extender is the old door.** It predates the plugin framework, it costs an HTTP round trip per
pod, and new work writes a plugin or a profile instead. It is worth recognising in a configuration
someone else wrote.

**An admission webhook sits on the path of every write it matches**, which is its power and its risk.
A mutating one can add a sidecar to every pod, which is how several service meshes inject theirs; a
validating one can refuse what lesson 25's policy could not express. With `failurePolicy: Fail`, a
webhook that is down refuses the writes it matches, and if it matches the pods of its own Deployment,
it cannot be restarted. **Scope it with a selector and keep it out of `kube-system`.** Lesson 25's
ValidatingAdmissionPolicy does the common checks inside the API server, with nothing to keep running,
and is the first thing to reach for.

**An aggregated API is a door for whole new resources.** Lesson 21 met one: `metrics.k8s.io` is
served by metrics-server, and the API server only forwards to it. Lesson 43's CRDs are the other way to
add a resource, stored in etcd by the API server itself; aggregation is for the rare API that cannot
live in etcd, like one that computes its answers.

A fresh cluster has none of these:

```
ana@laptop:~/shop$ kubectl get apiservices | grep -v Local
NAME                              SERVICE   AVAILABLE   AGE
ana@laptop:~/shop$ kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations
No resources found
ana@laptop:~/shop$ kubectl get validatingadmissionpolicies
No resources found
```

The `apiservices` list without `Local` is only its header: every API group is served by the API server
itself. No webhooks and no policies. **Each line that appears here later is code that runs on someone's
write**, so these three commands are worth running on a cluster you inherit.
