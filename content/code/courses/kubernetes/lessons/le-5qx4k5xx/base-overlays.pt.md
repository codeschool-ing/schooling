---
title: Uma base e as diferenças
version: 1
---

**A base é a loja como todo ambiente a roda**, escrita como manifestos comuns, mais um
`kustomization.yaml` que os lista:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      containers:
      - name: shop
        image: shop:1.0
        envFrom:
        - configMapRef:
            name: shop-settings
```

```yaml
resources:
- deployment.yaml
- service.yaml
configMapGenerator:
- name: shop-settings
  literals:
  - GREETING=hello
```

O `configMapGenerator` escreve o ConfigMap de onde o Deployment lê o ambiente, então a configuração
vive numa linha em vez de num arquivo próprio.

## Dois overlays

Um overlay nomeia a base como recurso e diz o que mudar. Staging fica com uma réplica e a sua própria
saudação, e ganha um sufixo em todo nome:

```yaml
resources:
- ../../base
namespace: staging
nameSuffix: -staging
labels:
- pairs:
    env: staging
configMapGenerator:
- name: shop-settings
  behavior: merge
  literals:
  - GREETING=staging
```

Produção mantém os nomes, usa a imagem mais nova, e aplica um patch no número de réplicas:

```yaml
resources:
- ../../base
namespace: production
labels:
- pairs:
    env: production
images:
- name: shop
  newTag: "1.1"
patches:
- path: replicas.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 3
```

**O patch é um fragmento do objeto que ele muda**: o mesmo tipo e nome, e só os campos a substituir. O
Kustomize acha o objeto correspondente na base e junta os dois.

```
ana@laptop:~/shop$ find deploy -type f | sort
deploy/base/deployment.yaml
deploy/base/kustomization.yaml
deploy/base/service.yaml
deploy/overlays/production/kustomization.yaml
deploy/overlays/production/replicas.yaml
deploy/overlays/staging/kustomization.yaml
```

## Montando

`kubectl kustomize` imprime o que um overlay produz, sem tocar no cluster:

```
ana@laptop:~/shop$ kubectl kustomize deploy/overlays/production | grep -E "^kind|^  name|namespace:|replicas|image:|env:"
kind: ConfigMap
    env: production
  name: shop-settings-f655md8fbd
  namespace: production
kind: Service
    env: production
  name: shop
  namespace: production
kind: Deployment
    env: production
  name: shop
  namespace: production
  replicas: 3
```

Todo objeto foi para `production`, ganhou o rótulo `env`, e o Deployment ganhou três réplicas e
`shop:1.1`. **O nome do ConfigMap ganhou um hash, `-f655md8fbd`**, calculado a partir do conteúdo, e a
referência do Deployment a ele foi reescrita para bater. Esse é o assunto da próxima seção.

```
        image: shop:1.1
ana@laptop:~/shop$ kubectl kustomize deploy/overlays/staging | grep -E "^kind|^  name|namespace:|GREETING|name: shop-settings"
  GREETING: staging
kind: ConfigMap
  name: shop-settings-staging-ckt68hf7g8
  namespace: staging
kind: Service
  name: shop-staging
  namespace: staging
kind: Deployment
  name: shop-staging
```

Os objetos de staging levam o sufixo `-staging`, referências incluídas, e a saudação é a do overlay.
