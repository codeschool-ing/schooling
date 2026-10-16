---
title: Sealed Secrets
version: 1
---

**Sealed Secrets encrypts a Secret with a key that only one cluster holds.** A controller runs in
the cluster and keeps the private half of a key pair; anybody can fetch the public half and encrypt
with it. What goes into Git is a `SealedSecret`, an object whose values only that controller can
decrypt, and the controller turns it into an ordinary Secret beside it. The repository is public to
everybody who can read it, and still the token is not.

`kubeseal` is the command-line half, and it installs like the other tools:

```
ana@laptop:~/setup$ ARCH=$(dpkg --print-architecture)
ana@laptop:~/setup$ curl -fsSLO https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.40.0/kubeseal-0.40.0-linux-$ARCH.tar.gz
ana@laptop:~/setup$ curl -fsSL https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.40.0/sealed-secrets_0.40.0_checksums.txt | grep " kubeseal-0.40.0-linux-$ARCH.tar.gz$" | sha256sum --check
kubeseal-0.40.0-linux-amd64.tar.gz: OK
ana@laptop:~/setup$ tar -xzf kubeseal-0.40.0-linux-$ARCH.tar.gz kubeseal && sudo install -m 0755 kubeseal /usr/local/bin/ && rm kubeseal kubeseal-0.40.0-linux-$ARCH.tar.gz
ana@laptop:~/setup$ kubeseal --version
kubeseal version: 0.40.0
```

The controller is cluster infrastructure rather than an application, so it goes in a directory of
its own, `infrastructure/`. The release publishes the controller as one file of plain manifests,
which goes into the repository as it is: the version is then whatever a reviewed commit says, and
upgrading it is a pull request like any other.

```
ana@laptop:~/fleet$ git switch --quiet -c sealed-secrets
ana@laptop:~/fleet$ mkdir -p infrastructure/sealed-secrets
ana@laptop:~/fleet$ curl -fsSLo infrastructure/sealed-secrets/controller.yaml https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.40.0/controller.yaml
ana@laptop:~/fleet$ grep -c '^kind:' infrastructure/sealed-secrets/controller.yaml
11
ana@laptop:~/fleet$ git add infrastructure clusters && git commit --quiet -m "sealed-secrets: the controller, 0.40.0"
ana@laptop:~/fleet$ kubectl -n kube-system get deployment sealed-secrets-controller
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
sealed-secrets-controller   1/1     1            1           34s
```

Eleven objects: the controller's Deployment, the `SealedSecret` kind, two Services and the roles and
bindings it needs. Flux applies the directory with one more Kustomization in `clusters/lab/`. This
is `clusters/lab/sealed-secrets.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: sealed-secrets
  namespace: flux-system
spec:
  interval: 10m
  path: ./infrastructure/sealed-secrets
  prune: true
  wait: true
  timeout: 3m
  sourceRef:
    kind: GitRepository
    name: flux-system
```

## Sealing a token

`kubeseal` needs the controller's public key. It can ask the controller each time, but a copy in a
file lets you seal on a machine that cannot reach the cluster, and makes plain which key you are
using:

```
ana@laptop:~/fleet$ kubeseal --fetch-cert > ~/setup/sealed-secrets.pem
ana@laptop:~/fleet$ openssl x509 -in ~/setup/sealed-secrets.pem -noout -subject -enddate
subject=
notAfter=Oct 13 00:45:52 2036 GMT
```

No subject, and a certificate valid for ten years, which says less than it seems: the controller
makes a **new key every thirty days** and keeps all the old ones, so new seals use the newest key
and old ones still decrypt. Fetch the certificate again now and then; a seal made with an older one
still works.

Sealing is a pipe: a Secret's YAML goes in, made with `--dry-run=client` so that nothing is created,
and a SealedSecret comes out. The token never touches a file in the clear:

```
ana@laptop:~/fleet$ git switch --quiet -c staging-token
ana@laptop:~/fleet$ TOKEN=$(openssl rand -hex 16)
ana@laptop:~/fleet$ kubectl -n staging create secret generic bulletin-token --from-literal=token=$TOKEN --dry-run=client -o yaml | kubeseal --cert ~/setup/sealed-secrets.pem -o yaml > apps/bulletin/staging/token.yaml
ana@laptop:~/fleet$ cat apps/bulletin/staging/token.yaml
---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: bulletin-token
  namespace: staging
spec:
  encryptedData:
    token: AgDJGI2gmRdGrMT6nidqHUIuIPcYpdP7yiWFAqGCUfCBVVwh0FORv2gv31yZ65uXW33ui9B+j58hrcNJnQMQRg5GCDAHdsiJB1cv/aJOqKemPDNHIS7DAYRiLvS968tpVOsOdz/eGcAfF43kU/4rjY7KJosM9YzGWeRwwpIw2GZatKnaLgW5SUi72kPOW1bB1hDE35VPbtW9eN17EUxBbVPkLlDP3CcSI/ARCoD1qB4Eoe96CESkK/T9gq0pkBEfSatqqBKh7lqbwpg+rTCdmeULTFMpoI9zN5Pcqq6urZvTKexsb/mC8y/CCbv8tuuS9akSEYmUNhesD+Nej8KzsB5w026HaAJg+UKhY+CLjaZuVLAXtSqel1PYrhJJSnkMWPzCTFvaNZVjSVLMbvEW+VgI+y17VAiWHPagP758gHXNjOYxe0UN5UOa5NfuSoqGjjyGaU5MofzTh2lYmzyN8klMGJsoZODU1cBOdUu6rC8dKroyN3dEeLGLyOOFwY3KuF8fSwspKevB1ceAE4WNflIdEnQ+xgbyd5xAEveZTZIZ47O+4MthDG9EiALfFB0sWnWXm5Mns5sDuwoZAlsdzokY4Bb0grku2qiLJyohGDiVEYa/B90kaZAvLNMv2nXVxywVM6EtLgR3HuZVRWU0M6yDNlfgfylxj2EzCEu41Vxa7TK9R/1GVuIeXmvo07YdX7SKbPOeQzDQ1Ai7EUzKU5Zv7HNRryzsYlx/j76QgeXOHQ==
  template:
    metadata:
      name: bulletin-token
      namespace: staging
```

`encryptedData` holds the token, encrypted to the controller's key, and `template` says what the
Secret it becomes will look like. **This file is safe to commit**: anybody can read it, and only the
controller in this cluster can open it.

The base Deployment mounts the Secret as a file at `/secrets/token`, which is where `bulletin`
looks, and marks it **optional**, so that an environment without a token still starts. This is
`apps/bulletin/base/deployment.yaml` now:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bulletin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bulletin
  template:
    metadata:
      labels:
        app: bulletin
    spec:
      containers:
      - name: bulletin
        image: localhost:5001/bulletin
        envFrom:
        - configMapRef:
            name: bulletin
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
        volumeMounts:
        - name: token
          mountPath: /secrets
          readOnly: true
      volumes:
      - name: token
        secret:
          secretName: bulletin-token
          optional: true
```

Staging's kustomization lists `token.yaml` among its resources, and `clusters/lab/staging.yaml`
gains two lines:

```yaml
  dependsOn:
  - name: sealed-secrets
```

They matter on the day the cluster is rebuilt from the repository. Flux would otherwise apply
staging and the controller at the same time, staging would fail for want of the `SealedSecret` kind,
and it would recover only on its next attempt. With `dependsOn`, staging waits until the
controller's Kustomization is ready.

And `validate.sh` meets one more kind whose schema is not Kubernetes', so `SealedSecret` joins the
list it skips:

```sh
sed -i 's/-skip HelmRelease,OCIRepository /-skip HelmRelease,OCIRepository,SealedSecret /' ~/setup/validate.sh
```

```
ana@laptop:~/fleet$ git diff | grep '^[-+] '
+        volumeMounts:
+        - name: token
+          mountPath: /secrets
+          readOnly: true
+      volumes:
+      - name: token
+        secret:
+          secretName: bulletin-token
+          optional: true
+  dependsOn:
+  - name: sealed-secrets
ana@laptop:~/fleet$ git add apps clusters && git commit --quiet -m "staging: a sealed token"
ana@laptop:~/fleet$ kubectl -n staging get sealedsecrets,secrets
NAME                                      AGE
sealedsecret.bitnami.com/bulletin-token   35s

NAME                    TYPE     DATA   AGE
secret/bulletin-token   Opaque   1      35s
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.2
message: Staging is built by Kustomize.
pod: bulletin-6b796f54fc-r8l9q
token: sha256:3dda1746e73e
ana@laptop:~/fleet$ printf %s "$TOKEN" | sha256sum | cut -c1-12
3dda1746e73e
```

The controller opened the SealedSecret and wrote a Secret of the same name beside it. Staging's pods
rolled, because the base Deployment changed, and the new ones mount the token: the fingerprint on
the page is the fingerprint of `$TOKEN`, computed on your side from the value that never went
anywhere in the clear.
