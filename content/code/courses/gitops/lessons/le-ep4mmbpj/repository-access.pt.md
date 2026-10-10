---
title: Uma chave só de leitura para o repositório
version: 1
---

**O Argo CD precisa ler o `fleet`, e não precisa de mais nada do Gitea.** Ele nunca faz push, nunca
abre pull request, nunca aprova. Então ele ganha uma conta própria com acesso de leitura a esse
repositório, e um token com um único escopo, `read:repository`. Se esse token vazar, o estrago é que
alguém consegue ler o estado desejado, o que é ruim, e não que alguém consegue mudá-lo, o que seria
o cluster.

```
ana@laptop:~$ docker exec gitea gitea admin user create --username argocd --password 'change-me-please' --email argocd@example.org --must-change-password=false
New user 'argocd' has been successfully created!
ana@laptop:~$ docker exec gitea gitea admin user generate-access-token --username argocd --token-name cluster --scopes read:repository --raw > ~/argocd.token
ana@laptop:~$ chmod 600 ~/argocd.token
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '{"permission": "read"}' $API/collaborators/argocd
204
```

O `argocd` é um **colaborador com permissão `read`**, a mais baixa que o Gitea tem. Agora o Argo CD
fica sabendo do repositório, no endereço que funciona de dentro do cluster:

```
ana@laptop:~$ argocd repo add http://gitea:3000/ana/fleet.git --username argocd --password "$(cat ~/argocd.token)"
Repository 'http://gitea:3000/ana/fleet.git' added
ana@laptop:~$ argocd repo list
TYPE  NAME  REPO                             INSECURE  OCI    LFS    CREDS  STATUS      MESSAGE  PROJECT
git         http://gitea:3000/ana/fleet.git  false     false  false  false  Successful           
```

`Successful` quer dizer que o repo server o clonou com essas credenciais. Elas não ficam guardadas
em nenhum lugar misterioso: o `argocd repo add` escreveu um Secret do Kubernetes no namespace
`argocd`, com um rótulo que diz ao Argo CD o que ele é,

```
ana@laptop:~$ kubectl -n argocd get secrets -l argocd.argoproj.io/secret-type=repository
NAME              TYPE     DATA   AGE
repo-2788178720   Opaque   4      1s
ana@laptop:~$ kubectl -n argocd get secrets -l argocd.argoproj.io/secret-type=repository -o jsonpath='{.items[0].data.url}' | base64 -d; echo
http://gitea:3000/ana/fleet.git
```

e isso é tudo o que um "repositório" é para o Argo CD. Escrever esse Secret em YAML e aplicá-lo faz a
mesma coisa, e é assim que um time acrescenta repositórios sem ninguém digitar um token num terminal.
**Guardar esse YAML no Git é a única coisa que você não pode fazer**: o campo `password` dele é o
token, em base64. A aula 9 mostra como guardá-lo no Git cifrado.
