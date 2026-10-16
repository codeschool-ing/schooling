---
title: O Flux, com menos que cluster-admin
version: 1
---

**O Flux consegue aplicar uma Kustomization como uma ServiceAccount em vez de como ele mesmo.** O
campo é `serviceAccountName`, e com ele definido o kustomize controller se passa por aquela conta
para todo objeto que cria, muda ou remove: o que a conta não pode fazer, o Flux não pode fazer em
nome daquele caminho do repositório. O controlador mantém o próprio poder para as Kustomizations que
não nomeiam uma conta.

Primeiro, quanto o Flux tem hoje:

```
ana@laptop:~/fleet$ kubectl get clusterrolebinding cluster-reconciler-flux-system -o custom-columns=ROLE:.roleRef.name,SUBJECTS:.subjects[*].name
ROLE            SUBJECTS
cluster-admin   kustomize-controller,helm-controller
ana@laptop:~/fleet$ kubectl auth can-i create clusterrolebindings --all-namespaces --as=system:serviceaccount:flux-system:kustomize-controller
yes
```

O binding `cluster-reconciler-flux-system` dá `cluster-admin` aos controladores kustomize e helm, e
o `kubectl auth can-i` diz o que isso significa numa palavra: o Flux pode criar um
ClusterRoleBinding, que é a permissão que concede todas as outras.

O staging ganha uma conta própria, no `flux-system` ao lado da Kustomization que a usa, autorizada a
administrar o namespace `staging` e nada mais. O ClusterRole `admin` é do próprio Kubernetes: a
maior parte do que fica dentro de um namespace, nada fora dele. Este é
`clusters/lab/staging-applier.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: staging-applier
  namespace: flux-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: staging-applier
  namespace: staging
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: staging-applier
  namespace: flux-system
```

e o `clusters/lab/staging.yaml` a nomeia, dentro de `spec`:

```yaml
  serviceAccountName: staging-applier
```

```
ana@laptop:~/fleet$ git switch --quiet -c staging-applier
ana@laptop:~/fleet$ git diff | grep '^[-+] '
+  serviceAccountName: staging-applier
ana@laptop:~/fleet$ git add clusters && git commit --quiet -m "staging: applied as staging-applier"
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                                                                                                                                                                                                                 
staging	main@sha1:db03e43c	False    	False	Namespace/staging dry-run failed (Forbidden): namespaces "staging" is forbidden: User "system:serviceaccount:flux-system:staging-applier" cannot patch resource "namespaces" in API group "" in the namespace "staging"	
       	                  	         	     	                                                                                                                                                                                                                       	
```

Merge feito, e o staging parou: `READY False`, com o motivo. A conta não pode fazer `patch` no
Namespace `staging`, porque um namespace não está dentro de si mesmo e o `admin` cobre o que está
dentro. A coluna `REVISION` ainda nomeia o commit anterior: o Flux confere o caminho inteiro com um
dry run primeiro, e aqui não aplicou nada.

**O Flux para na primeira recusa**, então a mensagem dele nomeia um problema e não todos. Para ver a
lista inteira antes do próximo pull request, faça ao API server a mesma pergunta que o Flux faz,
como a mesma conta: gere a pasta e aplique com um dry run no servidor, se passando por
`staging-applier`. Nada muda, e cada objeto recebe a própria resposta:

```
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/staging | kubectl apply --server-side --dry-run=server --as=system:serviceaccount:flux-system:staging-applier -f -
configmap/bulletin-bgc7c2mm85 serverside-applied (server dry run)
service/bulletin serverside-applied (server dry run)
deployment.apps/bulletin serverside-applied (server dry run)
Error from server (Forbidden): namespaces "staging" is forbidden: User "system:serviceaccount:flux-system:staging-applier" cannot patch resource "namespaces" in API group "" in the namespace "staging"
Error from server (Forbidden): sealedsecrets.bitnami.com "bulletin-token" is forbidden: User "system:serviceaccount:flux-system:staging-applier" cannot patch resource "sealedsecrets" in API group "bitnami.com" in the namespace "staging"
```

Três objetos passam e dois são recusados: o Namespace, como o Flux disse, e o SealedSecret, a que o
Flux nem chegou. O `admin` cobre os tipos que o Kubernetes traz e os tipos customizados cujos
próprios ClusterRoles dizem pertencer a ele; os do Sealed Secrets não dizem.

Duas coisas que o role `admin` não inclui, e a resposta mais estreita para cada uma é uma regra que
nomeia exatamente aquilo. Este é `clusters/lab/staging-applier-extra.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: staging-applier
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  resourceNames: ["staging"]
  verbs: ["get", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: staging-applier
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: staging-applier
subjects:
- kind: ServiceAccount
  name: staging-applier
  namespace: flux-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: staging-applier-sealed
  namespace: staging
rules:
- apiGroups: ["bitnami.com"]
  resources: ["sealedsecrets"]
  verbs: ["get", "list", "watch", "create", "patch", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: staging-applier-sealed
  namespace: staging
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: staging-applier-sealed
subjects:
- kind: ServiceAccount
  name: staging-applier
  namespace: flux-system
```

```
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet && git switch --quiet -c staging-applier-extra
ana@laptop:~/fleet$ git add clusters && git commit --quiet -m "staging-applier: its namespace and its sealed secrets"
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:79a931a1	False    	True 	Applied revision: main@sha1:79a931a1	
```

`READY True`, e desta vez todo objeto foi aplicado como `staging-applier`.

## O que isso compra

Um pull request na pasta do staging que vai além do staging: YAML válido que o `kubeconform` aceita,
e que um revisor cansado talvez aceite também, porque o nome parece inofensivo e ele está na pasta
de uma aplicação. Ele entra na lista do `kustomization.yaml` da pasta, e este é
`apps/bulletin/staging/debug.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: staging-debug
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: staging
```

O merge acontece, e o Flux tenta:

```
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet && git switch --quiet -c staging-debug
ana@laptop:~/fleet$ git add apps && git commit --quiet -m "staging: a debugging account"
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                                                                                                                                                                                                                                                                                                     
staging	main@sha1:79a931a1	False    	False	ClusterRoleBinding/staging-debug dry-run failed (Forbidden): clusterrolebindings.rbac.authorization.k8s.io "staging-debug" is forbidden: User "system:serviceaccount:flux-system:staging-applier" cannot patch resource "clusterrolebindings" in API group "rbac.authorization.k8s.io" at the cluster scope	
       	                  	         	     	                                                                                                                                                                                                                                                                                                           	
ana@laptop:~/fleet$ kubectl get clusterrolebinding staging-debug
Error from server (NotFound): clusterrolebindings.rbac.authorization.k8s.io "staging-debug" not found
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet && git switch --quiet -c revert-staging-debug
ana@laptop:~/fleet$ git revert --no-edit HEAD^2 >/dev/null && git log -1 --format=%s
Revert "staging: a debugging account"
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:dbee7f14	False    	True 	Applied revision: main@sha1:dbee7f14	
```

O Flux recusou a revisão no dry run, nomeando o ClusterRoleBinding e a conta, e o `kubectl get`
confirma que nada foi criado. **A revisão deixou passar; a permissão, não.** O caminho de volta é o
de qualquer merge ruim, um revert por pull request, e depois dele o staging volta a ficar pronto num
commit que não pede mais nada fora dele.
