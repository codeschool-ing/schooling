---
title: Production
version: 1
---

**Production is one more directory and one more file in `clusters/lab/`.** It runs the same
application with its own configuration: two replicas, its own message, and port 30081, which
lesson 1's cluster file maps to `localhost:8081`. Save this as
`apps/bulletin/production/bulletin.yaml`:

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

and this as `clusters/lab/production.yaml`:

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

`dependsOn` makes Flux reconcile production only while staging is ready. **It orders, and it does
not promote**: production still runs whatever its own directory says, which is not necessarily what
staging runs. What it prevents is applying production in the middle of a change that has already
broken staging in the same commit.

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

Two environments, one cluster, one repository, and nothing about either of them that is not in a
file under `apps/bulletin/`.
