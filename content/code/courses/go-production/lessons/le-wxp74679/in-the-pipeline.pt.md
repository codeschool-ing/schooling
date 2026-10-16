---
title: A verificação num hook e no CI
version: 1
---

Um editor que formata ao salvar cobre quem o usa. **A verificação que cobre todo mundo roda por onde
toda mudança passa**: num hook antes do commit, e no CI antes do merge. As duas se resumem a uma
pergunta feita às ferramentas das seções 02 e 04, "você mudaria alguma coisa?", e a primeira
tentativa de fazê-la costuma sair errada.

## O `gofmt -l` tem sucesso quando acha algo

Para haver o que achar, volte o `internal/tally/classes.go` ao estado em que a seção 02 o imprimiu,
desarrumado. Depois pergunte ao `gofmt` e olhe o status de saída:

```
ana@vm:~/fmt$ gofmt -l .; echo $?
internal/tally/classes.go
0
ana@vm:~/fmt$ test -z "$(gofmt -l .)"; echo $?
1
ana@vm:~/fmt$ gofmt -d . > /dev/null; echo $?
1
ana@vm:~/fmt$ goimports -d . > /dev/null; echo $?
0
```

**O `gofmt -l` citou o arquivo e saiu com 0.** Listar arquivos é o que pediram, e ele listou, então
pelas contas dele deu certo; um passo de CI que roda `gofmt -l .` sozinho fica verde com uma lista de
arquivos desformatados parada no log. A correção é tratar a saída como a resposta: `$(...)` captura o
que o `gofmt` imprimiu, e o `test -z` só tem sucesso quando isso está vazio, então a segunda linha
falha como uma verificação deve falhar.

O `gofmt -d` se comporta de outro jeito: sai com 1 quando imprime um diff, o que faz do `gofmt -d .`
uma verificação utilizável sozinha, com o diff no log de brinde. **O `goimports -d` não faz isso**:
ele imprimiu um diff em `/dev/null` e saiu com 0. Duas ferramentas com as mesmas flags e códigos de
saída diferentes já são motivo para deixar de confiar no código de saída aqui e capturar a saída
sempre.

## Um script, rodado pelo hook e pelo CI

A verificação pertence a um arquivo só, para que o hook e o job de CI não se afastem um do outro.
Ela roda o `goimports`, que formata como o `gofmt` e confere também o bloco de imports, com o prefixo
`-local` da seção 04 escrito uma vez. O `go run` com versão compila o `goimports` fixado no primeiro
uso e o pega do cache de build depois disso, então o script não precisa de nada instalado além do
próprio Go. `scripts/check-fmt.sh`:

```sh
#!/bin/sh
# check-fmt.sh: fail when goimports would change any Go file in the module.
# goimports formats the way gofmt does and fixes the imports as well, so one
# command covers both. The pre-commit hook and the CI job both run this file.
out=$(go run golang.org/x/tools/cmd/goimports@v0.52.0 -l -local example.com/hits .) || exit 2
if [ -n "$out" ]; then
	echo "check-fmt: goimports -local example.com/hits -w would change:" >&2
	echo "$out" >&2
	exit 1
fi
```

O Git roda o `.git/hooks/pre-commit`, se ele existir e for executável, antes de registrar um commit,
e abandona o commit se o hook sair com qualquer coisa diferente de 0. O hook só precisa chamar o
script. `.git/hooks/pre-commit`:

```sh
#!/bin/sh
# Refuse the commit when the check fails. Git runs hooks from the top of
# the working tree.
exec ./scripts/check-fmt.sh
```

Antes do primeiro commit de um repositório, o Git precisa saber quem o está fazendo, então o
`git config` define um nome e um endereço para este. Depois, o primeiro commit, com o `classes.go`
ainda desarrumado:

```
ana@vm:~/fmt$ git init -q -b main && git config user.name Ana && git config user.email ana@example.com
ana@vm:~/fmt$ chmod +x scripts/check-fmt.sh .git/hooks/pre-commit
ana@vm:~/fmt$ git add go.mod go.sum '*.go' scripts .github && git commit -q -m 'hits, formatted'; echo $?
check-fmt: goimports -local example.com/hits -w would change:
internal/tally/classes.go
1
ana@vm:~/fmt$ go fmt ./...
internal/tally/classes.go
ana@vm:~/fmt$ git add -u && git commit -q -m 'hits, formatted'; echo $?
0
ana@vm:~/fmt$ git log --oneline | wc -l
1
```

**O hook recusou o commit e citou o arquivo**; depois do `go fmt` e do `git add -u`, que põe no stage
a nova versão de todo arquivo que o Git já acompanha, o mesmo commit passou. Dois limites valem ser
conhecidos. Um hook mora em `.git`, que não vai para o commit, então cada clone precisa instalá-lo de
novo, e qualquer um o pula com `git commit --no-verify`. E este confere os arquivos como estão no
disco, não como foram para o stage, então um arquivo corrigido depois do `git add` e não adicionado
de novo passa pelo hook e entra desarrumado no commit. **O hook é uma comodidade para quem faz o
commit; o CI é a verificação que ninguém consegue pular.**

## O mesmo script no CI

No GitHub Actions o job tem três passos: buscar o código, instalar o Go que o `go.mod` cita, rodar o
script. `.github/workflows/format.yml`:

```yaml
name: format
on: [push, pull_request]
jobs:
  format:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
      - run: sh scripts/check-fmt.sh
```

**Este arquivo não foi rodado**: o laboratório não tem GitHub. Ele entrou no commit com o resto acima,
e num repositório hospedado lá ele roda a cada push e a cada pull request. Qualquer outro sistema de
CI precisa das mesmas três coisas, e a última linha é igual em todo lugar. As versões das duas
actions eram as mais novas quando esta lição foi escrita.

## Um arquivo que não compila

Capturar a saída tem uma armadilha própria. Um arquivo que o `gofmt` não consegue ler não é listado,
porque não há com o que comparar; o `gofmt` informa o erro de sintaxe na saída de erro e sai com 2.
Aqui está um, digitado no meio de uma edição, ao lado da árvore recém-registrada:

```
ana@vm:~/fmt$ echo 'package tally; func Broken(' > internal/tally/broken.go
ana@vm:~/fmt$ test -z "$(gofmt -l .)"; echo $?
internal/tally/broken.go:1:29: expected ')', found 'EOF'
0
ana@vm:~/fmt$ out=$(gofmt -l .) && test -z "$out"; echo $?
internal/tally/broken.go:1:29: expected ')', found 'EOF'
2
ana@vm:~/fmt$ sh scripts/check-fmt.sh; echo $?
internal/tally/broken.go:1:29: expected ')', found 'EOF'
exit status 2
2
ana@vm:~/fmt$ rm internal/tally/broken.go
```

**O `test -z "$(gofmt -l .)"` passou.** A saída padrão veio vazia, o erro foi para o terminal, e o
status de saída do `gofmt` foi jogado fora dentro do `$(...)`. A segunda forma o preserva: uma
atribuição como `out=$(gofmt -l .)` tem o status de saída do comando que rodou, então o `&&` para no
2 e a linha falha. O build pegaria esse arquivo de qualquer jeito, mas uma verificação de formato não
deveria depender do build para cobri-la. O terceiro comando é o `check-fmt.sh`, que está escrito da
segunda forma; o `exit status 2` dele é o `go run` dizendo como terminou o programa que rodou.

## O que não conferir

`gofmt -l .` e `goimports -l .` leem todo arquivo `.go` dentro do diretório, e a seção 02 mostrou que
não é isso que o `go fmt` faz: o `go fmt ./...` formata os arquivos de pacotes, e o padrão de pacotes
`./...` deixa dois tipos de diretório de fora. Uma verificação em `.` os lê assim mesmo:

| diretório | o que tem dentro | por que a verificação deve pulá-lo |
|---|---|---|
| `vendor/` | cópias das suas dependências, feitas pelo `go mod vendor` | é código dos outros, e o próximo `go mod vendor` desfaria qualquer mudança nele |
| `testdata/` | entradas para testes, que o comando go nunca compila | o teste de um parser pode guardar ali um arquivo `.go` quebrado de propósito, e o script acima falharia nele com status 2 |

O `hits` não tem nenhum dos dois, então `.` está certo para ele. Um módulo que os tenha deve escrever,
no lugar do `.` no fim da linha do `goimports` no script, os diretórios que guardam o próprio código,
como `internal tools *.go` aqui.

**Arquivos gerados são outro caso.** Um arquivo que começa com um comentário como
`// Code generated by stringer; DO NOT EDIT.` é lido como qualquer outro, e o `gofmt` não tem isenção
para ele. Um bom gerador formata a própria saída: o `stringer`, do mesmo módulo `golang.org/x/tools`
que o `goimports`, passa o que escreve pelo `go/format` da biblioteca padrão, que formata exatamente
como o `gofmt`. Se um gerador não faz isso, a correção vai no passo que o roda, não no arquivo, já que
o próximo `go generate`, assunto da lição 10, sobrescreve tudo o que você editar à mão.
