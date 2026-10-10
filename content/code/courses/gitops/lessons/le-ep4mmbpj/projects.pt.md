---
title: Projetos: o que uma Application pode tocar
version: 1
---

**Toda Application até aqui pertence ao projeto `default`, que permite qualquer repositório, qualquer
cluster, qualquer namespace e qualquer tipo de objeto.** Com o app de apps, qualquer pessoa cujo pull
request em `argocd/` entre consegue criar uma Application, e uma Application no `default` publica
qualquer coisa em qualquer lugar, inclusive no `kube-system`. Um projeto estreita isso. Salve isto
como `fleet/argocd/project-bulletin.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: bulletin
  namespace: argocd
spec:
  description: The bulletin application, in every environment
  sourceRepos:
  - http://gitea:3000/ana/fleet.git
  destinations:
  - server: https://kubernetes.default.svc
    namespace: staging
  - server: https://kubernetes.default.svc
    namespace: production
  clusterResourceWhitelist:
  - group: ""
    kind: Namespace
```

Três listas, cada uma de permissões. **`sourceRepos`**: só o `fleet` pode ser lido.
**`destinations`**: só os namespaces `staging` e `production` deste cluster.
**`clusterResourceWhitelist`**: dos objetos que vivem fora de um namespace, só um Namespace; uma
ClusterRole, uma CRD ou um webhook são recusados. Objetos dentro dos namespaces permitidos são
permitidos, a menos que uma `namespaceResourceBlacklist` diga outra coisa.

No mesmo pull request, o `argocd/bulletin-staging.yaml` troca `project: default` por
`project: bulletin`:

```
ana@laptop:~/fleet$ git switch --quiet -c project
ana@laptop:~/fleet$ git add argocd
ana@laptop:~/fleet$ git diff --cached --stat
 argocd/bulletin-staging.yaml |  2 +-
 argocd/project-bulletin.yaml | 17 +++++++++++++++++
 2 files changed, 18 insertions(+), 1 deletion(-)
ana@laptop:~/fleet$ git commit --quiet -m "argocd: the bulletin project"
ana@laptop:~/fleet$ argocd proj list
NAME      DESCRIPTION                                     DESTINATIONS    SOURCES                          CLUSTER-RESOURCE-WHITELIST  NAMESPACE-RESOURCE-BLACKLIST  SIGNATURE-KEYS  ORPHANED-RESOURCES  DESTINATION-SERVICE-ACCOUNTS
bulletin  The bulletin application, in every environment  2 destinations  http://gitea:3000/ana/fleet.git  /Namespace                  <none>                        <none>          disabled            <none>
default                                                   *,*             *                                */*                         <none>                        <none>          disabled            <none>
ana@laptop:~/fleet$ argocd app list
NAME                     CLUSTER                         NAMESPACE  PROJECT   STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                             PATH     TARGET
argocd/bulletin-staging  https://kubernetes.default.svc  staging    bulletin  Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  staging  main
argocd/root              https://kubernetes.default.svc  argocd     default   Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  argocd   main
```

## A regra em ação

Uma Application desse projeto que tente publicar no `kube-system` nunca chega a sincronizar. Esta é
aplicada à mão, como teste, e apagada depois:

```
ana@laptop:~/setup$ kubectl apply -f probe-system.yaml
application.argoproj.io/probe-system created
ana@laptop:~/setup$ argocd app get probe-system | sed -n '/^CONDITION/,/^$/p'
CONDITION         MESSAGE                                                                                                                                                         LAST TRANSITION
InvalidSpecError  application destination server 'https://kubernetes.default.svc' and namespace 'kube-system' do not match any of the allowed destinations in project 'bulletin'  2026-10-10 02:20:53 -0300 -03

ana@laptop:~/setup$ kubectl delete -f probe-system.yaml
application.argoproj.io "probe-system" deleted from argocd namespace
```

O controller recusou a própria Application, com uma mensagem que cita o projeto e a regra. **Um
projeto é a linha entre "pode fazer merge de um arquivo em `argocd/`" e "pode mudar qualquer coisa no
cluster"**, e a aula 11 a aperta, junto com as permissões da service account do próprio Argo CD.
