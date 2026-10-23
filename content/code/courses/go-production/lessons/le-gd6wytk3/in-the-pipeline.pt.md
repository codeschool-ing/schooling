---
title: Lint no pipeline sem se afogar nele
version: 1
---

Um linter num notebook é um conselho. **Um linter no CI é uma barreira, e uma barreira tem três
tarefas**: dar a mesma resposta em toda máquina, segurar problemas novos sem exigir que todo problema
velho seja corrigido antes, e fazer isso rápido o bastante para ninguém aprender a esperar por ela.
Cada uma das três é uma configuração que alguém precisa escolher, e os padrões escolhem mal para um
código antigo.

## A mesma resposta em toda parte

Pedir a versão mais nova que houver é a ideia errada comum aqui: "o golangci-lint mais recente" parece
a escolha mais segura, e é a que deixa vermelho um build verde numa manhã em que ninguém mudou uma
linha. **Cada versão muda o que sai no relatório.** A seção 04 viu dois casos: a 2.0.0 tirou todas as
exclusões padrão, o que fez o `errcheck` voltar a relatar impressões e fechamentos, e a 2.14.0 levou o
revive de 1.15.0 para 1.17.0, o que trouxe uma regra nova, e religou uma das checagens do `gosec`, a
`G407`. Fixar o golangci-lint fixa todos os linters dentro dele, já que as versões deles estão no
`go.mod` dele. Então a versão fica escrita num lugar que o CI lê, e atualizá-la é um pull request
próprio, em que os achados novos são o diff inteiro e podem ser corrigidos ou excluídos de propósito.

## Só o que esta mudança acrescentou

Um código antigo tem uma pilha antiga de avisos, e a primeira execução de um linter novo sobre ele
relata todos. O `~/lint` é esse código em miniatura: o `report.go` carrega os onze achados com que a
seção 04 terminou, e eles vão ficar por um tempo. Faça dele um repositório Git e commite-o como está,
do jeito que a lição 6 fez com o `~/fmt`:

```
ana@vm:~/lint$ git init -q -b main && git config user.name Ana && git config user.email ana@example.com
ana@vm:~/lint$ git add -A && git commit -q -m "hits, with the warnings it has today" && git log --oneline | wc -l
1
```

Aí chega uma funcionalidade nova, escrita por alguém com pressa. `internal/tally/share.go`:

```go
package tally

// Share returns the percentage of requests that ended with status.
func Share(s Summary, status int) float64 {
	n, ok := s.ByStatus[status]
	if ok == false || s.Lines == 0 {
		return 0
	}
	return 100 * float64(n) / float64(s.Lines)
}
```

```
ana@vm:~/lint$ golangci-lint run --output.text.print-issued-lines=false | tail -9
internal/tally/report.go:33:5: SA4003: every value of type uint is >= 0 (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not end with punctuation or newlines (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not be capitalized (staticcheck)
internal/tally/share.go:6:5: S1002: should omit comparison to bool constant, can be simplified to !ok (staticcheck)
12 issues:
* errcheck: 1
* govet: 1
* revive: 4
* staticcheck: 6
ana@vm:~/lint$ golangci-lint run --new-from-rev=HEAD; echo $?
internal/tally/share.go:6:5: S1002: should omit comparison to bool constant, can be simplified to !ok (staticcheck)
	if ok == false || s.Lines == 0 {
	   ^
1 issues:
* staticcheck: 1
1
```

**A execução simples relata doze achados, e só o último é sobre o arquivo novo.** Uma barreira que
falha com os doze reprova esta mudança por onze problemas que ela não causou, e quem escreveu o
`share.go` aprende que o passo de lint fica vermelho faça o que fizer. O `--new-from-rev=HEAD` mantém só
os achados em linhas que diferem do commit nomeado, aqui o arquivo novo, e a barreira passa a dizer uma
coisa só: `ok == false` é `!ok`.

Num pull request, o commit com que comparar é onde o branch saiu do `main`, e o
`--new-from-merge-base` descobre isso:

```
ana@vm:~/lint$ git switch -q -c share && git add -A && git commit -q -m "tally: Share"
ana@vm:~/lint$ golangci-lint run --new-from-merge-base=main; echo $?
internal/tally/share.go:6:5: S1002: should omit comparison to bool constant, can be simplified to !ok (staticcheck)
	if ok == false || s.Lines == 0 {
	   ^
1 issues:
* staticcheck: 1
1
ana@vm:~/lint$ golangci-lint run --new-from-merge-base=main --issues-exit-code=0 > /dev/null; echo $?
0
ana@vm:~/lint$ golangci-lint run ./cmd/...; echo $?
level=error msg="[linters_context] typechecking error: pattern ./cmd/...: lstat ./cmd/: no such file or directory"
0 issues.
7
```

**O mesmo achado único, agora medido contra o ponto de saída do branch**, não importa quantos commits o
branch tenha. As duas flags têm um ponto cego que vem do jeito como funcionam: mantêm achados em linhas
alteradas. Uma mudança que apaga a única chamada a uma função antiga faria o `unused` relatar essa
função, numa linha que a mudança nunca tocou, então o problema novo seria filtrado junto com os velhos.
Esse é o preço da abordagem, e é por isso que a pilha velha também precisa diminuir, em pull requests
separados, até a flag poder sair.

## O que o código de saída diz

Os dois últimos comandos mostram os outros dois códigos que vale conhecer. O `--issues-exit-code=0`
mantém o relatório e deixa o passo passar, que é como um linter pode rodar uma semana no CI, só
imprimindo, antes de alguém fazer dele uma barreira. O segundo é um erro no próprio comando: um padrão
que não nomeia nenhum pacote.

| código | o que o golangci-lint está dizendo |
|---|---|
| `0` | rodou e não achou nada que devesse relatar |
| `1` | achou problemas, ou o número definido por `--issues-exit-code` |
| `3` | não conseguiu rodar: um arquivo de configuração que recusou, como na seção 04 |
| `5` | não havia arquivos Go para olhar |
| `7` | rodou e registrou um erro no caminho, como o `./cmd/` ausente acima |

**Código que não compila não é um caso à parte**: um erro de sintaxe volta como um problema do linter
chamado `typecheck`, com status 1. O passo de build também o acha, o que é um dos motivos para o passo
de lint nunca ser o único.

## O cache

O golangci-lint guarda num cache o que cada linter achou em cada pacote, e uma execução em que nada
mudou lê isso de volta em vez de analisar de novo:

```
ana@vm:~/lint$ golangci-lint cache clean && time golangci-lint run > /dev/null

real	0m2.891s
user	0m2.791s
sys	0m0.402s
ana@vm:~/lint$ time golangci-lint run > /dev/null

real	0m0.370s
user	0m0.255s
sys	0m0.091s
ana@vm:~/lint$ golangci-lint cache status
Dir: /home/ana/.cache/golangci-lint
Size: 179.7KiB
```

**2,891 segundos com o cache limpo, 0,370 segundo com ele cheio**, num módulo de seis arquivos Go; a
proporção cresce com o tamanho do código. Os números são tempos de uma execução e mudam um pouco a cada
vez, e a ordem de grandeza não muda. Uma máquina de CI começa vazia, então vale guardar o cache entre
execuções, junto com os caches de build e de módulos do próprio Go, em `~/.cache` e `~/go/pkg/mod`.

## A mesma checagem no CI

No GitHub Actions o trabalho fica com a action do próprio projeto, a que o repositório do golangci-lint
roda nos próprios pull requests. Ela instala a versão fixada e a roda. `.github/workflows/lint.yml`:

```yaml
name: lint
on: pull_request
permissions:
  contents: read
jobs:
  golangci:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
      - uses: golangci/golangci-lint-action@v9
        with:
          version: v2.14.0
          args: --new-from-merge-base=origin/main
```

```
ana@vm:~/lint$ git add .github && git commit -q -m "ci: lint" && git log --oneline | head -1 | cut -c9-
ci: lint
```

**Este arquivo não foi executado**: o laboratório não tem GitHub, como na lição 6. Ele foi commitado
acima, e num repositório hospedado lá roda em todo pull request. Quatro linhas carregam decisões.
`on: pull_request` e não `push`, porque no próprio `main` a merge base é o commit sendo verificado e o
`--new-from-merge-base` nunca acharia nada. `fetch-depth: 0` busca o histórico inteiro, sem o qual o
`origin/main` não está lá para comparar. `go-version-file` tira o Go do `go.mod`, como na lição 6. E
`version: v2.14.0` é a fixação, o único lugar do repositório que a nomeia. As três actions estão nas
versões principais que o workflow do próprio golangci-lint usava quando a 2.14.0 saiu:
`actions/checkout` v7, `actions/setup-go` v7 e `golangci/golangci-lint-action` v9.

## Implantando num código antigo

**O custo de um linter barulhento não são os minutos gastos lendo.** É que as pessoas param de ler: uma
barreira que erra uma vez em cinco ensina todo mundo a pôr `//nolint` sem olhar, e na sexta vez ela
estava certa. Cada passo abaixo serve para manter o sinal alto o bastante para que um build vermelho
seja levado a sério.

1. Comece de `default: standard` com o preset `std-error-handling`. Nunca `default: all`: ele liga os
   115, incluindo `arangolint` e `clickhouselint`, escritos para dois drivers de banco de dados de que
   o `hits` nunca ouviu falar.
2. Rode-o com `--issues-exit-code=0` por alguns dias e leia o que ele diz, no CI, onde todo mundo vê a
   mesma lista.
3. Corrija o que é barato, exclua o que é errado para este código em `exclusions.rules`, e ligue o
   `--new-from-merge-base`. A partir desse dia o código novo segue o padrão.
4. Quite os achados antigos um pacote por vez, em pull requests próprios, até a flag poder sair.
5. Acrescente um linter por vez, cada um num pull request que também faz o código passar nele, para que
   nenhum linter chegue com uma pilha atrasada.
