---
title: Base64 is not encryption
version: 1
---

`bulletin` has printed `token: none` since lesson 1. The program looks for a file at
`/secrets/token` and, when there is one, prints the start of its SHA-256 rather than the value, so
the page proves which token a pod has without showing it. This lesson gives staging and production a
token each, and the obvious way to write one is a Secret:

```
ana@laptop:~/fleet$ kubectl -n staging create secret generic bulletin-token --from-literal=token=a-staging-token --dry-run=client -o yaml
apiVersion: v1
data:
  token: YS1zdGFnaW5nLXRva2Vu
kind: Secret
metadata:
  name: bulletin-token
  namespace: staging
```

**The value in `data` is not hidden; it is encoded.** Base64 turns bytes into letters so that any
byte can sit in YAML, and it reverses with one command and no key:

```
ana@laptop:~/fleet$ kubectl -n staging create secret generic bulletin-token --from-literal=token=a-staging-token --dry-run=client -o jsonpath='{.data.token}' | base64 -d; echo
a-staging-token
```

A Kubernetes Secret is a ConfigMap with a different name and a little more care around it: it is not
printed by `kubectl describe`, it can be readable by fewer people than a ConfigMap, and the API
server can encrypt it in etcd. None of that helps once the YAML is in Git, where **whoever can read
the repository can read the token**, and so can every clone, every fork, every backup and every
laptop that ever checked it out. Deleting the file later does not help either: the commit that added
it is still there, and lesson 2's history is exactly the thing that never forgets.

So a Secret's YAML never goes into the repository as it is. The rest of this lesson is about what
goes in instead.
