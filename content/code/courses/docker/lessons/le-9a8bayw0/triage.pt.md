---
title: Lendo os achados
version: 1
---

**Uma lista de achados não é uma lista de tarefas.** O que torna um deles urgente é existir correção,
quão grave ele é, e se o código vulnerável está em algum lugar que o seu programa usa. O scanner
responde às duas primeiras.

## Corrigido, ou não

Um achado alto da imagem Debian, e como as 163 se dividem:

```
ana@vm:~$ trivy image --input debian.tar --format json | jq "[.Results[0].Vulnerabilities[] | select(.Severity == \"HIGH\")][0] | {VulnerabilityID, PkgName, InstalledVersion, FixedVersion, Status}"
{
  "VulnerabilityID": "CVE-2026-76642",
  "PkgName": "bsdutils",
  "InstalledVersion": "1:2.41.5-0+deb13u1",
  "FixedVersion": null,
  "Status": "affected"
}
ana@vm:~$ trivy image --input debian.tar --format json | jq -r "[.Results[0].Vulnerabilities[].Status] | group_by(.) | map(\"\(.[0])=\(length)\") | join(\" \")"
affected=161 fix_deferred=2
ana@vm:~$ trivy image --input debian.tar --ignore-unfixed --format json | jq -r -f severities.jq
none
```

`"FixedVersion": null` e `"Status": "affected"`: **o Debian sabe dele e não lançou correção**. Isso
vale para 161 das 163. O `--ignore-unfixed` esconde essas e não sobra nada, o que diz algo útil:
**reconstruir esta imagem hoje não removeria nenhuma delas**. Elas vão sumir quando o Debian lançar as
correções e a imagem for reconstruída por cima delas.

Uma base menor é o outro jeito de encurtar uma lista assim, e é o argumento da aula 14 visto do lado
do scanner: os pacotes que não estão lá não têm avisos.

## Uma barreira no pipeline

O `--exit-code 1` faz o Trivy falhar quando acha algo nas severidades citadas, que é como um pipeline
recusa uma imagem:

```
ana@vm:~$ trivy image --input shelf.tar --exit-code 1 --severity HIGH,CRITICAL > /dev/null; echo "exit $?"
exit 1
ana@vm:~$ trivy image --input debian.tar --exit-code 1 --severity HIGH,CRITICAL > /dev/null; echo "exit $?"
exit 1
```

**As duas falham**, o `shelf` pelo único achado alto. Uma barreira em `HIGH,CRITICAL` com
`--ignore-unfixed` é o meio-termo de costume: bloqueia o que dá para corrigir, e não bloqueia todo
build pelo que ninguém consegue corrigir. A aula 26 põe uma varredura no pipeline.

## Corrigindo o que dá para corrigir

O achado alto do `shelf` tem correção, `golang.org/x/text` 0.39.0. A Ana não tem Go na máquina (aula
1), então a atualização roda na imagem `golang:1.25`, com o usuário dela, com o código montado:

```
ana@vm:~$ cd shelf
ana@vm:~/shelf$ docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/src -w /src -v ~/gopkg:/go/pkg -e GOCACHE=/tmp/gocache -e GOPROXY=off -e GOFLAGS=-mod=mod golang:1.25 sh -c "go get golang.org/x/text@v0.39.0 && go mod tidy && go mod vendor"
go: upgraded golang.org/x/sync v0.17.0 => v0.21.0
go: upgraded golang.org/x/text v0.29.0 => v0.39.0
ana@vm:~/shelf$ git diff --stat -- go.mod go.sum vendor/modules.txt
 go.mod             | 4 ++--
 go.sum             | 8 ++++----
 vendor/modules.txt | 8 ++++----
 3 files changed, 10 insertions(+), 10 deletions(-)
ana@vm:~/shelf$ grep x/text go.mod
	golang.org/x/text v0.39.0 // indirect
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.6.1 -t shelf:1.6.1 . && docker save shelf:1.6.1 -o ../shelf-1.6.1.tar
sha256:86e45ec8b235ba9a9c609562080de0c89dcb4b97ee52608f627b9bb1dc420abf
ana@vm:~/shelf$ cd ..
ana@vm:~$ trivy image --input shelf-1.6.1.tar --format json | jq -r -f severities.jq
UNKNOWN=1
```

**O `go get` subiu o `x/text` para a versão corrigida**, e o `golang.org/x/sync` junto, porque a versão
nova precisa dele. O `go mod tidy` e o `go mod vendor` trouxeram o `go.sum` e o `vendor/` junto, e a
imagem reconstruída passa sem o achado alto. No laboratório, o `GOPROXY=off` faz o Go usar módulos
baixados antes de o laboratório começar, verificados contra as respostas salvas do banco de checksums;
numa máquina normal, o mesmo comando os baixa.

**O que sobra é o `tzdata` na base**, corrigido no Debian, mas ainda não na imagem distroless. Essa
correção chega quando o Google reconstruir o distroless e a Ana reconstruir o `shelf` em cima dele.
Com a base fixada pelo digest (aula 16), ela chega como um pull request que muda o digest, e é testada
antes de ir para produção.
