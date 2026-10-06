---
title: Where the password really is, and who can read it
version: 1
---

The API server answers with base64. **Underneath, etcd holds the object as the API server wrote
it**, and by default the API server writes it as it is. Reading the stored bytes directly, with
etcd's own client, and keeping only the printable runs of characters:

```
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/db --print-value-only | strings | grep -A1 password
;{"f:data":{".":{},"f:password":{},"f:user":{}},"f:type":{}}B
password
lab-only-7Hq2
```

There it is, `lab-only-7Hq2`, in plain text in the database. **So anyone with a copy of etcd's data
has every Secret in the cluster**: a backup left in a bucket, a disk from a decommissioned control
plane, a snapshot shared to debug something else. That is the case encryption at rest exists for.

## Encryption at rest

The API server can encrypt chosen types before it writes them, with keys from a file it is given.
On this lab's control plane the file looks like this, with the key itself left out of the transcript:

```
ana@laptop:~/shop$ docker exec shop-control-plane sed "s/secret: .*/secret: (32 random bytes, not shown)/" /etc/kubernetes/pki/encryption.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources: ["secrets"]
  providers:
  - secretbox:
      keys:
      - name: key1
        secret: (32 random bytes, not shown)
  - identity: {}
```

`secretbox` is one of the providers, an authenticated cipher with a 32-byte key, and the list is
ordered: **new writes use the first provider**, and `identity` at the end, which means "no
encryption", lets the API server still read what was written before. The flag points the API server
at the file:

```
ana@laptop:~/shop$ docker exec shop-control-plane grep encryption-provider /etc/kubernetes/manifests/kube-apiserver.yaml
    - --encryption-provider-config=/etc/kubernetes/pki/encryption.yaml
```

**Turning it on does not touch what is already stored.** The password is still readable in etcd:

```
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/db --print-value-only | strings | grep -c lab-only
1
```

Every Secret has to be written again for the new rule to apply, and replacing each one with itself
does exactly that:

```
ana@laptop:~/shop$ kubectl get secrets --all-namespaces -o json | kubectl replace -f - | tail -n 1
secret/bootstrap-token-abcdef replaced
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/db --print-value-only | head -c 26; echo
k8s:enc:secretbox:v1:key1:
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/db --print-value-only | strings | grep -c lab-only
0
ana@laptop:~/shop$ kubectl get secret db -o jsonpath="{.data.password}" | base64 -d; echo
lab-only-7Hq2
```

**Now the stored value begins with `k8s:enc:secretbox:v1:key1:`** — which provider, which key — and
the password appears nowhere in it. Through the API nothing changed: `kubectl` still returns the
password, because the API server decrypts on the way out. Encryption at rest protects a copy of the
data. It does not protect against anybody who can ask the API server.

On a managed cluster the provider runs etcd, and encryption at rest is a setting, usually with the
key kept in the provider's key service rather than in a file on the control plane.

## Who may read a Secret

```
ana@laptop:~/shop$ kubectl auth can-i get secrets --as=system:serviceaccount:default:default
no
ana@laptop:~/shop$ kubectl auth can-i get secrets
yes
```

**This is the protection that matters every day.** The pods of the `default` namespace run as the
`default` service account, and it may not read Secrets; Ana's own user, the cluster's administrator,
may. Lesson 23 writes these rules. For a value that must not live in the cluster at all, an external
store such as Vault or a cloud's secret manager keeps it, and a controller or a CSI driver (lesson
27) delivers it to the pod when it starts.

| what you worry about | what protects you |
|---|---|
| somebody reads the object through the API | RBAC: who may `get` Secrets (lesson 23) |
| a copy of etcd's data leaks | encryption at rest |
| the value leaks from inside the pod | a file in `tmpfs` rather than a variable, and a small image |
| the value is in git | never put it there; keep it in a store and deliver it at runtime |
