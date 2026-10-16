---
title: What a seal is bound to
version: 1
---

**A SealedSecret is sealed to a name and a namespace, not only to a cluster.** The name and the
namespace are mixed into the encryption, so the controller will decrypt `bulletin-token` in
`staging` and nothing else. That is deliberate: without it, anybody allowed to create objects in
some namespace could copy staging's SealedSecret there and have the controller hand them the token.

Copying it to production shows the refusal. This is done straight against the cluster, as an
experiment, and undone at the end:

```
ana@laptop:~/fleet$ sed 's/namespace: staging/namespace: production/' apps/bulletin/staging/token.yaml | kubectl apply -f -
sealedsecret.bitnami.com/bulletin-token created
ana@laptop:~/fleet$ kubectl -n production get sealedsecret bulletin-token
NAME             AGE
bulletin-token   5s
ana@laptop:~/fleet$ kubectl -n production get events --field-selector involvedObject.name=bulletin-token -o custom-columns=REASON:.reason,MESSAGE:.message
REASON            MESSAGE
ErrUnsealFailed   Failed to unseal: no key could decrypt secret (token)
ana@laptop:~/fleet$ kubectl -n production delete sealedsecret bulletin-token
sealedsecret.bitnami.com "bulletin-token" deleted from production namespace
```

The SealedSecret was created, and nothing came of it. **The controller refused to unseal it**, and
says so in an event, `ErrUnsealFailed`, with the reason: no key it holds decrypts a value sealed for
another namespace. No Secret appeared in production.

So **every environment gets its own seal**, and usually its own token, which is what production gets
in the next section, with a different tool. `kubeseal --scope` can loosen the binding to the
namespace only, or to the whole cluster, for a value that truly is the same everywhere; it is a
decision to write down, because it widens who can read the secret.

## The key nobody may lose

The seal is only as durable as the controller's private keys, and they live in the cluster:

```
ana@laptop:~/fleet$ kubectl -n kube-system get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key
NAME                      TYPE                DATA   AGE
sealed-secrets-keylcjp5   kubernetes.io/tls   2      76s
```

One key so far, made when the controller first started, stored as an ordinary Secret of type
`kubernetes.io/tls` in `kube-system`. Every thirty days another joins it.

**If the cluster is lost, those keys are lost with it**, and every SealedSecret in the repository
becomes a file nobody can open. A cluster rebuilt from Git, which is GitOps's promise, would start
with new keys and fail every seal. So the keys are backed up, out of the cluster and out of Git:
`kubectl get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml` writes them out, and
that file goes wherever the company keeps its most sensitive material, because it opens every secret
the cluster has ever sealed. Applying it to a new cluster and restarting the controller lets the new
controller open the old seals.

The other way out is to re-seal: keep the plaintext somewhere else, and seal it again for the new
cluster. Which is a hint at what the third family of answers does.
