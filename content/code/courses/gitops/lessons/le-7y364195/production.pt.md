---
title: Produção
version: 1
---

**A produção é mais uma pasta e mais um arquivo em `clusters/lab/`.** Ela roda a mesma aplicação com
a configuração dela: duas réplicas, a mensagem dela e a porta 30081, que o arquivo do cluster da aula
1 liga a `localhost:8081`. Salve isto como `apps/bulletin/production/bulletin.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bulletin
  namespace: production
spec:
  replicas: 2
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
        image: localhost:5001/bulletin:1.0
        env:
        - name: MESSAGE
          value: Welcome to the bulletin.
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bulletin
  namespace: production
spec:
  type: NodePort
  selector:
    app: bulletin
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30081
```

e isto como `clusters/lab/production.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: production
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/bulletin/production
  prune: true
  wait: true
  timeout: 2m
  dependsOn:
  - name: staging
  sourceRef:
    kind: GitRepository
    name: flux-system
```

O `dependsOn` faz o Flux reconciliar a produção só enquanto o staging está pronto. **Ele ordena, e não
promove**: a produção continua rodando o que a pasta dela diz, que não é necessariamente o que o
staging roda. O que ele evita é aplicar a produção no meio de uma mudança que já quebrou o staging no
mesmo commit.

```
ana@laptop:~/fleet$ git switch --quiet -c production
ana@laptop:~/fleet$ git add apps/bulletin/production clusters/lab/production.yaml
ana@laptop:~/fleet$ git commit --quiet -m "fleet: production"
ana@laptop:~/fleet$ flux get kustomizations
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                              
flux-system	main@sha1:99d01437	False    	True 	Applied revision: main@sha1:99d01437	
production 	main@sha1:99d01437	False    	True 	Applied revision: main@sha1:99d01437	
staging    	main@sha1:99d01437	False    	True 	Applied revision: main@sha1:99d01437	
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.0
message: Welcome to the bulletin.
token: none
```

Dois ambientes, um cluster, um repositório, e nada sobre nenhum deles que não esteja num arquivo em
`apps/bulletin/`.
