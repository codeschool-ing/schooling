---
title: Instalando o operador
version: 1
---

O operador é publicado como um chart do Helm, e a página de releases dele no GitHub traz o chart
empacotado ao lado de cada versão. Numa empresa o chart viria pelo gerenciador de repositórios da
aula 7; aqui o registry do próprio curso faz esse papel. O chart é baixado uma vez, da release:

```
ana@laptop:~/setup$ curl -fsSLO https://github.com/external-secrets/external-secrets/releases/download/helm-chart-1.3.2/external-secrets-1.3.2.tgz
ana@laptop:~/setup$ helm show chart external-secrets-1.3.2.tgz | grep -E '^(name|version|appVersion):'
appVersion: v1.3.2
name: external-secrets
version: 1.3.2
```

O arquivo `.prov` ao lado dele na página de release é o formato de assinatura do próprio Helm, que o
`helm verify` confere com a chave pública de quem o assinou: a mesma ideia da aula 8, com uma
ferramenta mais antiga.

Depois ele é publicado no seu registry, exatamente como a aula 7 publicou o chart do `bulletin`,
para que **o cluster o baixe de um lugar que você controla**:

```
ana@laptop:~/setup$ helm push external-secrets-1.3.2.tgz oci://localhost:5001/charts --plain-http
Pushed: localhost:5001/charts/external-secrets:1.3.2
Digest: sha256:587c4e6f2e0a06da93b7334746b6e1c52bf2f552bf931564bb63bfdfc2eea5b2
```

O operador é infraestrutura, então vai ao lado do Sealed Secrets em `infrastructure/`, em três
arquivos. Este é o `infrastructure/external-secrets/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
```

este é o `infrastructure/external-secrets/release.yaml`:

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

e este é o `infrastructure/external-secrets/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- namespace.yaml
- release.yaml
```

com o `clusters/lab/external-secrets.yaml` feito a partir do `sealed-secrets.yaml` do mesmo jeito
que a aula 9 fez o `vault-auth.yaml`:

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

Três Deployments: o próprio operador, o webhook que confere todo SecretStore e ExternalSecret antes
que o API server o guarde, e um controlador que mantém em dia o certificado do webhook. E 23
definições de recursos customizados, a maioria para tipos que este curso nunca usa: geradores, que
fazem senhas, chaves SSH ou tokens de registry, e push secrets, que escrevem no sentido contrário.
