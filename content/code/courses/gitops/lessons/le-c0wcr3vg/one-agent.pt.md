---
title: Um agente por vez
version: 1
---

**Dois reconciliadores para os mesmos objetos são as "duas verdades" da aula 2 com duas máquinas
brigando**, então o Argo CD sai antes de o Flux chegar. Esta aula começa do cluster como a aula 3 o
deixou, e o primeiro trabalho é aposentar o Argo CD sem derrubar o staging junto.

A ordem importa. Uma Application apagada com a cascata do Argo CD apagaria os objetos que gerencia;
estas Applications foram criadas sem o finalizer que pede isso, então apagá-las deixa o staging
rodando. A raiz vai primeiro, para que nada recrie as outras, depois o resto, depois o próprio Argo
CD:

```
ana@laptop:~$ kubectl delete -f ~/setup/root.yaml
application.argoproj.io "root" deleted from argocd namespace
ana@laptop:~$ kubectl -n argocd delete applications --all
application.argoproj.io "bulletin-staging" deleted from argocd namespace
ana@laptop:~$ kubectl delete -k ~/setup/argocd | tail -n 2
networkpolicy.networking.k8s.io "argocd-repo-server-network-policy" deleted from argocd namespace
networkpolicy.networking.k8s.io "argocd-server-network-policy" deleted from argocd namespace
ana@laptop:~$ kubectl get namespace argocd
NAME     STATUS   AGE
argocd   Active   79s
ana@laptop:~$ kubectl -n staging get pods
NAME                        READY   STATUS    RESTARTS   AGE
bulletin-657dd4685b-6jx4n   1/1     Running   0          82s
bulletin-657dd4685b-hdznv   1/1     Running   0          81s
bulletin-657dd4685b-zxh6n   1/1     Running   0          81s
```

`namespace "argocd" not found`: cada parte dele se foi, os tipos de recurso inclusive. Os três pods do
staging nem perceberam, porque nada os apagou. Eles ainda levam a anotação de rastreamento do Argo
CD, que ninguém lê agora e que o Flux vai deixar em paz.

## Aposentando o acesso de uma máquina

O Argo CD tinha uma conta no Gitea com acesso de leitura ao `fleet`, e um token dela está em
`~/argocd.token`. As credenciais de um sistema aposentado são um dos caminhos clássicos para dentro de
uma organização: **ninguém lembra que elas existem, então ninguém percebe quando são usadas.** Tire o
acesso no dia em que o sistema sai:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -X DELETE -H "$AS_ANA" $API/collaborators/argocd
204
```

`204`, e o token agora é chave de nada. A aula 11 transforma isso em hábito, e não num passo de que
alguém precisa lembrar.

A pasta `argocd/` do `fleet` descreve Applications que nada mais aplica. Um arquivo no repositório
que nenhum agente lê é uma descrição que vai deixar de ser verdade em silêncio, então ela sai também,
no mesmo pull request que traz o Flux.
