---
title: "revive: estilo, pelas regras que você escolhe"
version: 1
---

Estilo é a primeira linha da tabela da lição 7 com o que o vet deixa de fora: **código correto escrito
de um jeito em que o próximo leitor tropeça**. Um comentário de documentação faltando numa função
exportada, um `context.Context` que não é o primeiro parâmetro, uma string de erro que soa errada
impressa depois de outra. Nenhum deles é bug, e numa equipe cada um vira um comentário de revisão que
alguém escreve à mão, de novo, toda semana. Um linter de estilo escreve esses comentários no lugar, e o
`revive` é o que a maioria dos projetos Go adota.

## O sucessor do golint, e o que ele herdou

Por anos o linter de estilo foi o `golint`, do próprio projeto Go. O README dele agora abre com
"Golint is deprecated and frozen. There's no drop-in replacement for it, but tools such as Staticcheck
and `go vet` should be used instead." **O README do revive responde na primeira linha: "Drop-in
replacement of golint."** Os dois têm razão a seu modo. Rodado sem configuração, o revive aplica as 18
regras do golint, portadas sem mudança, e cinco próprias, 23 ao todo. O que ele acrescenta é tudo o que
o golint nunca teve: um arquivo de configuração, uma severidade por regra, regras que recebem
argumentos, comentários que desligam uma regra, e mais 82 regras que ficam desligadas até uma
configuração pedir por elas.

O `~/lint` ainda tem o `report.go` da seção 02, sem as diretivas. Instale a versão fixada e rode:

```
ana@vm:~/lint$ go install github.com/mgechev/revive@v1.17.1 && revive -version
version 1.17.1
ana@vm:~/lint$ revive ./... | sort -V
internal/tally/report.go:15:1: exported function NewReport should have comment or be unexported
internal/tally/report.go:15:27: exported func NewReport returns unexported type *tally.report, which can be annoying to use
internal/tally/report.go:40:24: context.Context should be the first parameter of a function
internal/tally/report.go:45:21: error strings should not be capitalized or end with punctuation or a newline
ana@vm:~/lint$ revive ./... > /dev/null; echo $?
0
ana@vm:~/lint$ revive -set_exit_status ./... > /dev/null; echo $?
1
```

A saída passa por `sort -V`, que a ordena por arquivo, linha e coluna. **O revive verifica cada regra
numa goroutine própria e imprime os achados conforme chegam**, então duas execuções listam as mesmas
linhas em ordens diferentes.

Quatro achados, e três são coisas que o staticcheck não mencionou. O `exported` quer um comentário em
todo nome exportado, enquanto o `ST1020` a `ST1022` do staticcheck julgam só um comentário que existe,
e ainda vêm desligados. O `unexported-return` diz que `NewReport` devolve um `*report`, um tipo que
quem chama não consegue nomear, então pode guardar o valor mas não escrevê-lo num campo de struct nem
numa assinatura de função própria. O `context-as-argument` quer o contexto primeiro, porque é ali que
todo leitor o procura. O quarto, `error-strings`, é a mesma queixa do `ST1005` do staticcheck, com
outras palavras.

## Um linter que nunca falha

Olhe de novo os dois códigos de saída. **O revive achou quatro coisas e saiu com 0**, e só o
`-set_exit_status` muda isso. Os padrões dele põem em 0 os dois códigos de saída que ele pode devolver:
um usado quando o pior achado é um aviso, outro quando é um erro. Um passo de CI que roda só
`revive ./...` imprime os achados num log e passa, sempre, que é a armadilha do `gofmt -l` da lição 6
de novo, com outra ferramenta.

## Um arquivo de configuração, impresso inteiro

O `revive.toml` decide quais regras rodam, quão grave cada uma é, e qual código de saída cada
severidade rende. Salve-o no topo do módulo, `revive.toml`:

```toml
# revive.toml: the rules revive applies to this module, and which of them fail.
enable-default-rules = true
severity = "warning"
confidence = 0.8
error-code = 1
warning-code = 0

[rule.context-as-argument]
severity = "error"

[rule.unhandled-error]
severity = "error"
arguments = ['^fmt\.Fprint(f|ln)?$']

[rule.cognitive-complexity]
arguments = [7]
exclude = ["TEST"]
```

Linha a linha, de cima para baixo:

| configuração | o que faz |
|---|---|
| `enable-default-rules = true` | mantém as 23 padrão; **sem ela, nomear qualquer regra desliga toda padrão não nomeada** |
| `severity`, `confidence` | a severidade de uma regra que não define a sua, e quão segura uma regra precisa estar antes de relatar |
| `error-code = 1`, `warning-code = 0` | um erro reprova a execução, um aviso é impresso e passa |
| `context-as-argument` | uma regra padrão, elevada de aviso para erro |
| `unhandled-error` | uma chamada cujo erro é descartado; o argumento é uma lista de expressões regulares de funções a liberar |
| `cognitive-complexity` | quão difícil é acompanhar uma função, no máximo 7, e fora dos arquivos de teste |

A primeira linha é a armadilha do formato. Um `revive.toml` que só acrescenta `unhandled-error` parece
"os padrões mais uma", e é "uma": `exported`, `error-strings` e as outras vinte e uma param de rodar sem
aviso. **A expressão em `unhandled-error` precisa casar com o nome inteiro da função**, `fmt.Fprintf` e
não só o começo, e é por isso que termina em `$` e escreve as três terminações; `'^fmt\.Fprint'` sozinho
não libera nada. Escrever na saída de erro no `main.go` é o que essa lista desculpa, e mais nada.

```
ana@vm:~/lint$ revive -config revive.toml ./... | sort -V
internal/tally/report.go:15:1: exported function NewReport should have comment or be unexported
internal/tally/report.go:15:27: exported func NewReport returns unexported type *tally.report, which can be annoying to use
internal/tally/report.go:40:24: context.Context should be the first parameter of a function
internal/tally/report.go:45:21: error strings should not be capitalized or end with punctuation or a newline
internal/tally/report.go:48:2: Unhandled error in call to function os.WriteFile
ana@vm:~/lint$ revive -config revive.toml ./... > /dev/null; echo $?
1
ana@vm:~/lint$ revive -config revive.toml -formatter ndjson ./... | grep -o '"Severity":"error","Failure":"[^"]*"' | sort
"Severity":"error","Failure":"Unhandled error in call to function os.WriteFile"
"Severity":"error","Failure":"context.Context should be the first parameter of a function"
```

**Cinco achados e status de saída 1.** O novo é o `os.WriteFile` no `Save`, o bug para o qual o
staticcheck da seção 02 não tinha checagem: a escrita pode falhar e a função devolve `nil` mesmo assim.
Dois dos cinco são erros, e foram esses dois que reprovaram a execução. A saída padrão não mostra a
severidade, e o formatador `ndjson`, um objeto JSON por achado, mostra: o `grep` separou os dois. O
`main_test.go` ficou fora: `TestRun` tem complexidade cognitiva 11, acima do limite, e
`exclude = ["TEST"]` mantém a regra longe de todo arquivo `_test.go`, onde um teste em tabela tem mesmo
essa cara.

## Desligando uma regra numa linha

As diretivas do revive também são comentários. `//revive:disable-next-line:REGRA motivo` cobre a linha
de baixo; `//revive:disable:REGRA` e `//revive:enable:REGRA` delimitam um trecho do arquivo. O motivo é
opcional por padrão, e a diretiva `specify-disable-reason`, definida na configuração, o torna
obrigatório.

```
ana@vm:~/lint$ sed -i '/^func NewReport/i //revive:disable-next-line:unexported-return the type stays private until the API settles' internal/tally/report.go
ana@vm:~/lint$ revive -config revive.toml ./internal/... | sort -V
internal/tally/report.go:16:1: exported function NewReport should have comment or be unexported
internal/tally/report.go:41:24: context.Context should be the first parameter of a function
internal/tally/report.go:46:21: error strings should not be capitalized or end with punctuation or a newline
internal/tally/report.go:49:2: Unhandled error in call to function os.WriteFile
```

**O `unexported-return` sumiu e os outros quatro ficaram**, cada um uma linha abaixo, porque o
comentário acrescentou uma linha acima deles. A diretiva nomeou uma regra, então o `exported`, na mesma
linha de código, continua relatando. Apague a linha da diretiva antes da seção 04.

## Por que uma equipe o escolhe

Algumas das 23 regras padrão do revive se sobrepõem à família de estilo do staticcheck, `error-strings`
e `ST1005` entre elas. O resto do valor dele está nas regras que mais ninguém tem e nos argumentos
que elas recebem: um limite de complexidade, um tamanho máximo de linha, uma lista de imports que um
pacote não pode usar, um cabeçalho com que todo arquivo deve começar. **O revive é onde uma equipe
escreve as próprias convenções**, as que não são do projeto Go nem são bugs. A maioria das equipes que
faz isso nunca o roda sozinho: a seção 04 roda as mesmas regras de dentro do `golangci-lint`, com um só
arquivo de configuração para todos os linters.
