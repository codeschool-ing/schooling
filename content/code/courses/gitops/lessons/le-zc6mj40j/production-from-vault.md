---
title: Production's token, from Vault
version: 1
---

Production's token has been a SOPS file since lesson 9. It moves to Vault, where lesson 9 already
put a value at `secret/bulletin/production` and a role that lets production's `bulletin` read it.
Two objects in `apps/bulletin/production/vault.yaml` replace the file:

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: vault
spec:
  provider:
    vault:
      server: http://vault:8200
      path: secret
      version: v2
      auth:
        kubernetes:
          mountPath: kubernetes
          role: bulletin-production
          serviceAccountRef:
            name: bulletin
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: bulletin-token
spec:
  refreshInterval: 1m
  secretStoreRef:
    kind: SecretStore
    name: vault
  target:
    name: bulletin-token
  data:
  - secretKey: token
    remoteRef:
      key: bulletin/production
      property: token
```

The store logs in **as the ServiceAccount `bulletin`**: the operator asks Kubernetes for a token for
it and presents that to Vault, exactly the exchange lesson 9 did by hand. So the operator holds no
Vault credential of its own, and what it can read in production is what production's role allows.
The ExternalSecret writes the `token` field of that entry into a Secret named `bulletin-token`, the
name the base Deployment already mounts, and reads it again every minute.

`validate.sh` meets two more kinds whose schemas are not Kubernetes', so they join the skip list:

```sh
sed -i 's/-skip HelmRelease,OCIRepository,SealedSecret /-skip HelmRelease,OCIRepository,SealedSecret,SecretStore,ExternalSecret /' ~/setup/validate.sh
```

A list that keeps growing is the sign of a better way: `kubeconform` can be given the schemas of
custom resources, from a directory or from a public catalogue of them, and then it validates these
too. This course keeps the list short enough to read.

```
ana@laptop:~/fleet$ git switch --quiet -c production-vault
ana@laptop:~/fleet$ git rm --quiet apps/bulletin/production/token.sops.yaml && git add apps
ana@laptop:~/fleet$ git diff --cached --stat
 apps/bulletin/production/kustomization.yaml |  2 +-
 apps/bulletin/production/token.sops.yaml    | 22 -------------------
 apps/bulletin/production/vault.yaml         | 33 +++++++++++++++++++++++++++++
 3 files changed, 34 insertions(+), 23 deletions(-)
ana@laptop:~/fleet$ git commit --quiet -m "production: the token comes from Vault"
ana@laptop:~/fleet$ kubectl -n production get secretstore,externalsecret
NAME                                    AGE   STATUS   CAPABILITIES   READY
secretstore.external-secrets.io/vault   69s   Valid    ReadWrite      True

NAME                                                STORETYPE     STORE   REFRESH INTERVAL   STATUS         READY
externalsecret.external-secrets.io/bulletin-token   SecretStore   vault   1m                 SecretSynced   True
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.1
message: Welcome to the bulletin.
pod: bulletin-55bcbd4ddb-5swsk
token: sha256:951e14be7632
ana@laptop:~/fleet$ vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12
951e14be7632
```

The store is `Valid`: the operator logged in to Vault as production's `bulletin` ServiceAccount. The
ExternalSecret is `SecretSynced`, and the pod prints the fingerprint of the value Vault holds, the
same twelve characters as the hash of `vault kv get`. The SOPS file left the repository in the same
commit, so production's token is in Git nowhere at all, encrypted or not.
