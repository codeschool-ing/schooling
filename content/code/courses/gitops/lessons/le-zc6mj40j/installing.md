---
title: Installing the operator
version: 1
---

The operator is published as a Helm chart, and its release page on GitHub carries the packaged chart
beside each version. In a company the chart would come through the repository manager of lesson 7;
here the course's own registry plays that part. The chart is fetched once, from the release:

```
ana@laptop:~/setup$ curl -fsSLO https://github.com/external-secrets/external-secrets/releases/download/helm-chart-1.3.2/external-secrets-1.3.2.tgz
ana@laptop:~/setup$ helm show chart external-secrets-1.3.2.tgz | grep -E '^(name|version|appVersion):'
appVersion: v1.3.2
name: external-secrets
version: 1.3.2
```

The `.prov` file beside it on the release page is Helm's own signature format, which `helm verify`
checks against the public key of whoever signed it: the same idea as lesson 8, with an older tool.

Then it is published into your registry, exactly as lesson 7 published `bulletin`'s chart, so that
**the cluster pulls it from a place you control**:

```
ana@laptop:~/setup$ helm push external-secrets-1.3.2.tgz oci://localhost:5001/charts --plain-http
Pushed: localhost:5001/charts/external-secrets:1.3.2
Digest: sha256:587c4e6f2e0a06da93b7334746b6e1c52bf2f552bf931564bb63bfdfc2eea5b2
```

The operator is infrastructure, so it goes beside Sealed Secrets in `infrastructure/`, as three
files. This is `infrastructure/external-secrets/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
```

this is `infrastructure/external-secrets/release.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: external-secrets
  namespace: external-secrets
spec:
  interval: 1h
  url: oci://registry:5000/charts/external-secrets
  insecure: true
  ref:
    tag: 1.3.2
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: external-secrets
  namespace: external-secrets
spec:
  interval: 1h
  chartRef:
    kind: OCIRepository
    name: external-secrets
```

and this is `infrastructure/external-secrets/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- namespace.yaml
- release.yaml
```

with `clusters/lab/external-secrets.yaml` made from `sealed-secrets.yaml` the same way lesson 9 made
`vault-auth.yaml`:

```
ana@laptop:~/fleet$ git switch --quiet -c external-secrets
ana@laptop:~/fleet$ git add infrastructure clusters && git status --short
A  clusters/lab/external-secrets.yaml
A  infrastructure/external-secrets/kustomization.yaml
A  infrastructure/external-secrets/namespace.yaml
A  infrastructure/external-secrets/release.yaml
ana@laptop:~/fleet$ git commit --quiet -m "external-secrets: the operator, 1.3.2"
ana@laptop:~/fleet$ kubectl -n external-secrets get deployments
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
external-secrets                   1/1     1            1           38s
external-secrets-cert-controller   1/1     1            1           38s
external-secrets-webhook           1/1     1            1           38s
ana@laptop:~/fleet$ kubectl get crds -o name | grep -c external-secrets.io
23
```

Three Deployments: the operator itself, the webhook that checks every SecretStore and ExternalSecret
before the API server stores it, and a controller that keeps the webhook's certificate current. And
23 custom resource definitions, most of them for kinds this course never uses: generators, which
make passwords, SSH keys or registry tokens, and push secrets, which write the other way.
