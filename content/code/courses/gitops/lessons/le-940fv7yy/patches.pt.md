---
title: Patches, e os campos que o Kustomize já conhece
version: 1
---

**Um overlay muda a base de dois jeitos: por campos que o Kustomize conhece, e por patches para todo o
resto.** `namespace`, `replicas`, `images` e os geradores são do primeiro tipo. Cada um diz uma coisa,
numa linha, e o Kustomize a aplica a todo objeto em que ela couber. Eles devem ser a primeira escolha
sempre que existirem, porque quem lê vê a intenção, e não a mecânica.

Um patch é para o resto, e o Kustomize aceita duas formas de patch.

**Um strategic merge patch** parece um pedaço do objeto, e é mesclado nele. A produção ganha pedidos e
limites de recursos que o staging não tem, e o patch é a parte de um Deployment que diz isso. Este é o
`apps/bulletin/production/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: production
resources:
- namespace.yaml
- ../base
replicas:
- name: bulletin
  count: 3
images:
- name: localhost:5001/bulletin
  newTag: "1.1"
configMapGenerator:
- name: bulletin
  literals:
  - MESSAGE=Welcome to the bulletin.
patches:
- target:
    kind: Service
    name: bulletin
  patch: |-
    - op: add
      path: /spec/ports/0/nodePort
      value: 30081
- patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: bulletin
    spec:
      template:
        spec:
          containers:
          - name: bulletin
            resources:
              requests:
                cpu: 10m
                memory: 16Mi
              limits:
                memory: 32Mi
```

e o `apps/bulletin/production/namespace.yaml` cita `production` do jeito que o do staging cita
`staging`. O segundo patch não tem `target`: um strategic merge patch cita o próprio objeto, e os
containers são casados pelo `name`, então os recursos caem no container `bulletin` e nada mais da lista
se mexe.

**Um JSON patch** é uma lista de operações sobre caminhos, `add`, `replace`, `remove`, e é o que os dois
overlays usam para o `nodePort` do Service. A porta é um elemento de uma lista sem nome para casar,
então o patch diz `/spec/ports/0/nodePort`: a primeira porta. Uma posição é uma coisa frágil para
casar: a base tem exatamente uma porta hoje, e uma segunda porta acrescentada no começo da lista
levaria o patch para a porta errada sem erro nenhum. **Prefira um strategic merge patch, e use um JSON
patch onde nenhum campo pode ser casado pelo nome.**

```
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/production | awk 'BEGIN { RS = "---\n" } /kind: Deployment/'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bulletin
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: bulletin
  template:
    metadata:
      labels:
        app: bulletin
    spec:
      containers:
      - envFrom:
        - configMapRef:
            name: bulletin-95kb84mf4k
        image: localhost:5001/bulletin:1.1
        name: bulletin
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
        resources:
          limits:
            memory: 32Mi
          requests:
            cpu: 10m
            memory: 16Mi
```

O `kubectl kustomize` mostra o Deployment da produção com os campos da base, as réplicas e a tag do
overlay, e os recursos do patch, que é tudo o que a produção é.
