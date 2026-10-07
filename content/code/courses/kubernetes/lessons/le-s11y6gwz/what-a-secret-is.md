---
title: What a Secret is, and what base64 is not
version: 1
---

**The most common belief about Secrets is that their values are encrypted, because they look
scrambled.** They are encoded. Base64 writes any bytes using 64 printable characters, so that a
binary key or a password with odd characters fits in a JSON or YAML field; it has no key and hides
nothing. The password used here is made up for the lab and opens nothing:

```
ana@laptop:~/shop$ kubectl create secret generic db --from-literal=user=shop --from-literal=password=lab-only-7Hq2
secret/db created
ana@laptop:~/shop$ kubectl get secret db
NAME   TYPE     DATA   AGE
db     Opaque   2      0s
ana@laptop:~/shop$ kubectl get secret db -o jsonpath="{.data}"; echo
{"password":"bGFiLW9ubHktN0hxMg==","user":"c2hvcA=="}
ana@laptop:~/shop$ kubectl get secret db -o jsonpath="{.data.password}" | base64 -d; echo
lab-only-7Hq2
```

`bGFiLW9ubHktN0hxMg==` is the password, and `base64 -d` gives it back with no key at all. **Anyone
who can read the object can read the value**, so a Secret's protection is never its encoding. What a
Secret does buy is everything around the value: Kubernetes knows it is sensitive, so it can be
encrypted where it is stored, kept out of `kubectl describe`, mounted in memory rather than on disk,
and given access rules of its own.

## Into a pod

The two ways in are the same as for a ConfigMap:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: reader
spec:
  containers:
  - name: reader
    image: busybox:1.37
    command: ["sh", "-c", "sleep 3600"]
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db
          key: user
    volumeMounts:
    - name: db
      mountPath: /run/secrets/db
      readOnly: true
  volumes:
  - name: db
    secret:
      secretName: db
      defaultMode: 0400
```

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
pod/reader created
ana@laptop:~/shop$ kubectl exec reader -- sh -c 'echo user is $DB_USER; ls -l /run/secrets/db/; mount | grep secrets/db'
user is shop
total 0
lrwxrwxrwx    1 root     root            15 Oct  6 17:15 password -> ..data/password
lrwxrwxrwx    1 root     root            11 Oct  6 17:15 user -> ..data/user
tmpfs on /run/secrets/db type tmpfs (ro,relatime,size=16480968k,noswap)
```

The variable is there, and the volume shows one file per key. Two details are different from a
ConfigMap and both are deliberate. **The volume is a `tmpfs`**, in the node's memory, so the
password is never written to the node's disk. And `defaultMode: 0400` makes the files readable by
their owner only; the listing shows the links, and the files behind `..data` carry that mode.

**Prefer the file to the variable for anything that matters.** An environment variable is easy to
leak by accident: it is printed by a crash report that dumps the environment, inherited by every
child process, and readable in `/proc` by anything running as the same user. A file in a `tmpfs`
mount is read when the program chooses to read it, and nowhere else.
