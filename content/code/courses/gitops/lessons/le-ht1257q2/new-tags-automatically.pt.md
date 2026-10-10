---
title: Tags novas, propostas automaticamente
version: 1
---

**Todo release até aqui chegou ao `fleet` porque uma pessoa editou uma tag.** Para o staging, onde todo
release deveria chegar assim que é construído, isso é uma tarefa chata, e o Flux consegue fazê-la: os
controladores de imagem dele observam um registry atrás de tags novas, escolhem a mais nova por uma
política e fazem commit da tag nova de volta no Git. O que traz a pergunta que a aula 2 resolveu:
**commit onde?** Não na `main`, onde ninguém faz push. Num branch, de onde um pull request passa pelas
checagens e pela revisão de sempre.

## Os controladores

Os controladores de imagem são partes opcionais do Flux, então eles são uma mudança nos componentes do
próprio Flux:

```sh
flux install --export --components-extra=image-reflector-controller,image-automation-controller \
  > clusters/lab/flux-system/gotk-components.yaml
```

Esse pull request faz o Flux instalar mais dois controladores em si mesmo, como a aula 4 prometeu que
atualizar o Flux funcionaria.

## Algo que pode fazer push

A automação precisa enviar um branch, o que o token só de leitura do Flux não consegue. Ela ganha uma
conta própria, `image-bot`, com permissão `write`, um token num Secret e, mais abaixo, um
`GitRepository` próprio que o usa, para que só a automação guarde uma credencial que escreve:

```
ana@laptop:~/fleet$ docker exec gitea gitea admin user create --username image-bot --password 'change-me-please' --email image-bot@example.org --must-change-password=false
2026/10/10 07:12:30 modules/setting/setting.go:133:loadCommonSettingsFrom() [W] [security] ALLOWED_HOST_LIST only restricts private hosts in the default lax mode, set EGRESS_MODE = strict to allow only the listed hosts, or lax to keep this
New user 'image-bot' has been successfully created!
ana@laptop:~/fleet$ docker exec gitea gitea admin user generate-access-token --username image-bot --token-name automation --scopes write:repository --raw > ~/image-bot.token
2026/10/10 07:12:30 modules/setting/setting.go:133:loadCommonSettingsFrom() [W] [security] ALLOWED_HOST_LIST only restricts private hosts in the default lax mode, set EGRESS_MODE = strict to allow only the listed hosts, or lax to keep this
ana@laptop:~/fleet$ chmod 600 ~/image-bot.token
ana@laptop:~/fleet$ curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '{"permission": "write"}' $API/collaborators/image-bot
204
ana@laptop:~/fleet$ flux create secret git fleet-writer-auth --url=http://gitea:3000/ana/fleet.git --username=image-bot --password="$(cat ~/image-bot.token)"
► git secret 'fleet-writer-auth' created in 'flux-system' namespace
```

A linha `[W]` antes de cada resposta do Gitea é um aviso sobre o `ALLOWED_HOST_LIST` que a aula 4
configurou para os webhooks: no modo padrão do Gitea a lista só governa endereços privados, que é tudo
de que este laptop precisa. O `204` é a resposta do Gitea à permissão: feito, nada a dizer.

## O que observar, que tag escolher, onde escrever

Quatro objetos, sendo o primeiro o `GitRepository` pelo qual a automação escreve. Salve-os como
`clusters/lab/image-automation.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: fleet-writer
  namespace: flux-system
spec:
  interval: 1m
  url: http://gitea:3000/ana/fleet.git
  ref:
    branch: main
  secretRef:
    name: fleet-writer-auth
---
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImageRepository
metadata:
  name: bulletin
  namespace: flux-system
spec:
  image: registry:5000/bulletin
  insecure: true
  interval: 1m
---
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImagePolicy
metadata:
  name: bulletin
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: bulletin
  filterTags:
    pattern: '^1\.(?P<minor>[0-9]+)$'
    extract: '$minor'
  policy:
    numerical:
      order: asc
---
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImageUpdateAutomation
metadata:
  name: staging
  namespace: flux-system
spec:
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: fleet-writer
  git:
    checkout:
      ref:
        branch: main
    push:
      branch: image-updates
    commit:
      author:
        name: image-bot
        email: image-bot@example.org
      messageTemplate: "staging: bulletin {{range .Changed.Changes}}{{.NewValue}}{{end}}"
  update:
    path: ./apps/bulletin/staging
    strategy: Setters
```

O `ImageRepository` lista as tags do `bulletin`; o `ImagePolicy` fica com as tags no formato `1.N`,
tira o `N` de cada uma e escolhe o maior; o `ImageUpdateAutomation` faz checkout da `main`, reescreve o que a política escolheu em
`apps/bulletin/staging` e envia o commit para o branch `image-updates`. **O que ele reescreve está
marcado no arquivo**: um comentário, depois da tag no overlay do staging, citando a política:

```yaml
  newTag: "1.1" # {"$imagepolicy": "flux-system:bulletin:tag"}
```

**Por que não uma faixa de versões?** A política `semver` do Flux lê versões de três números, e este
curso marca o `bulletin` com dois desde a aula 1: `1.2`, não `1.2.0`. Uma faixa como
`>=1.0.0 <2.0.0` não casa com nenhuma delas, e a política diz `unable to determine latest version
from provided list` e não escolhe nada. O filtro também descarta `stable`, a tag movida à mão antes
nesta aula, que não é versão nenhuma. Um time que marca com três números desde o começo pode usar a
faixa.

O `:tag` quer dizer que só a tag é reescrita; o nome da imagem continua `localhost:5001/bulletin`, o
nome pelo qual o nó baixa, enquanto o controlador observa o mesmo registry pelo nome de dentro do
cluster.

Os componentes, os quatro objetos e a marca vão num pull request só, e depois do merge o Flux roda seis
controladores em vez de quatro:

```
ana@laptop:~/fleet$ git switch --quiet -c image-automation
ana@laptop:~/fleet$ flux install --export --components-extra=image-reflector-controller,image-automation-controller > clusters/lab/flux-system/gotk-components.yaml
ana@laptop:~/fleet$ git add clusters apps
ana@laptop:~/fleet$ git diff --cached --stat
 apps/bulletin/staging/kustomization.yaml      |    2 +-
 clusters/lab/flux-system/gotk-components.yaml | 1300 ++++++++++++++++++++++++-
 clusters/lab/image-automation.yaml            |   62 ++
 3 files changed, 1362 insertions(+), 2 deletions(-)
ana@laptop:~/fleet$ git commit --quiet -m "flux: propose new staging releases from the registry"
ana@laptop:~/fleet$ kubectl -n flux-system get deployments
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
helm-controller               1/1     1            1           4m4s
image-automation-controller   1/1     1            1           4s
image-reflector-controller    1/1     1            1           4s
kustomize-controller          1/1     1            1           4m4s
notification-controller       1/1     1            1           4m4s
source-controller             1/1     1            1           4m5s
```

## Um release que se propõe sozinho

```
ana@laptop:~/bulletin$ git tag v1.2
ana@laptop:~/bulletin$ git push --quiet origin v1.2
ana@laptop:~/bulletin$ docker build --quiet --build-arg VERSION=1.2 -t localhost:5001/bulletin:1.2 .
sha256:484d38fbf937d15e5e1cad296ded20756581c2b36129206c9c659f73228a8cbb
ana@laptop:~/bulletin$ docker push --quiet localhost:5001/bulletin:1.2
localhost:5001/bulletin:1.2
ana@laptop:~/fleet$ flux get image policy bulletin
NAME    	IMAGE                 	TAG	READY	MESSAGE                                                                                             
bulletin	registry:5000/bulletin	1.2	True 	Latest image tag for registry:5000/bulletin resolved to 1.2 (previously registry:5000/bulletin:1.1)	
ana@laptop:~/fleet$ git fetch --quiet && git log --oneline -1 origin/image-updates
3c3a61e staging: bulletin 1.2
ana@laptop:~/fleet$ git diff main origin/image-updates | grep '^[-+] '
-  newTag: "1.1" # {"$imagepolicy": "flux-system:bulletin:tag"}
+  newTag: "1.2" # {"$imagepolicy": "flux-system:bulletin:tag"}
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.2
message: Staging is built by Kustomize.
pod: bulletin-cfd6f4744-hf4cv
token: none
```

A versão 1.2 foi enviada ao registry, e nada mais foi feito à mão. Em menos de um minuto a política a
escolheu, a automação fez commit de `staging: bulletin 1.2` no `image-updates` e enviou. **O branch é a
proposta**: ele passa pela checagem e pela revisão do Bruno como um pull request, e só o merge muda o
staging. A produção não tem marca, então nada nunca propõe um release para ela.
