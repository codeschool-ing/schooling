---
title: O formato de um programa com urfave/cli
version: 1
---

A lição 2 colocou o Cobra na frente do `hits`. Esta lição faz o mesmo com a **urfave/cli**, a outra
biblioteca que programas Go adotam quando o pacote flag deixa de bastar, e pergunta o que "mais
leve" compra e quanto custa. A ferramenta não muda: dois subcomandos, `count` e `top`, as mesmas
flags, a mesma saída e os mesmos códigos de saída da lição 1. **Na urfave/cli um programa inteiro é
um valor só, um `cli.Command`**, com os subcomandos como outros `cli.Command`s dentro dele e uma
função em cada um que roda quando a linha de comando o cita. Nada é registrado na inicialização e
não há gerador: você escreve a árvore como um literal e chama `Run` na raiz.

A versão usada do começo ao fim é a v3, na **v3.14.0**. Importa saber de que versão maior você está
lendo, porque a v2 tinha um tipo `cli.App` separado para a raiz e um argumento `*cli.Context` em toda
função, e a maioria das respostas na web ainda mostra isso. A v3 tem um tipo só para os dois casos e
passa um `context.Context` no lugar.

## Um módulo próprio

Esta versão fica em `~/cli-hits`, ao lado do `~/hits` da lição 1, para que as duas possam ser
medidas uma contra a outra na seção 05. Ela reaproveita a contagem da lição 1 sem mudança: coloque
o pacote `tally` da lição 1 em `internal/tally/tally.go` e o `genlog` em `tools/genlog/main.go`,
exatamente como a seção 03 e a seção 02 da lição 1 os imprimem, e crie o módulo com o mesmo nome:

```
ana@vm:~/cli-hits$ go mod init example.com/hits
go: creating new go.mod: module example.com/hits
go: to add module requirements and sums:
	go mod tidy
```

Desta vez a linha de comando fica em dois arquivos. O `main.go` guarda a árvore de comandos e nada
mais, o que o deixa curto o bastante para ler de uma vez:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"context\"\n\t\"fmt\"\n\t\"os\"\n\n\t\"github.com/urfave/cli/v3\"\n)\n",
      "note": "Um import a mais que a versão da lição 1, e ele é a biblioteca inteira. O pacote se chama `cli`, e o `/v3` no fim do caminho faz parte do nome do módulo: v1, v2 e v3 são três módulos diferentes, que podem conviver num mesmo build."
    },
    {
      "code": "func main() {\n\tcmd := &cli.Command{\n\t\tName:  \"hits\",\n\t\tUsage: \"summarise a web server's access log\",\n\t\tCommands: []*cli.Command{",
      "note": "**O programa é um valor**: um `cli.Command` para o próprio `hits`, com uma fatia de `cli.Command`s para os subcomandos. Nada é registrado e nada roda até o `Run` ser chamado lá embaixo."
    },
    {
      "code": "\t\t\t{\n\t\t\t\tName:      \"count\",\n\t\t\t\tUsage:     \"requests per status code\",\n\t\t\t\tArgsUsage: \"[file]\",\n\t\t\t\tFlags:     []cli.Flag{jsonFlag()},\n\t\t\t\tAction:    count,\n\t\t\t},",
      "note": "Um subcomando é do mesmo tipo que a raiz. `ArgsUsage` é só texto para a tela de ajuda; `Flags` lista o que este comando aceita, e `Action` é a função que roda quando a linha de comando o cita."
    },
    {
      "code": "\t\t\t{\n\t\t\t\tName:      \"top\",\n\t\t\t\tUsage:     \"the paths with the most requests\",\n\t\t\t\tArgsUsage: \"[file]\",\n\t\t\t\tFlags: []cli.Flag{\n\t\t\t\t\t&cli.IntFlag{\n\t\t\t\t\t\tName:      \"n\",\n\t\t\t\t\t\tAliases:   []string{\"limit\"},\n\t\t\t\t\t\tValue:     3,\n\t\t\t\t\t\tUsage:     \"how many paths to show\",\n\t\t\t\t\t\tSources:   cli.EnvVars(\"HITS_TOP\"),\n\t\t\t\t\t\tValidator: atLeastOne,\n\t\t\t\t\t},\n\t\t\t\t\tjsonFlag(),\n\t\t\t\t},\n\t\t\t\tAction: top,\n\t\t\t},\n\t\t},\n\t}",
      "note": "O `top` declara o `-n` com quatro coisas que a lição 1 precisou escrever à mão ou deixou de fora: um segundo nome, uma variável de ambiente a ler quando a flag não vem, uma checagem do valor e o padrão impresso na ajuda. A seção 03 roda cada uma."
    },
    {
      "code": "\tif err := cmd.Run(context.Background(), os.Args); err != nil {\n\t\tfmt.Fprintf(os.Stderr, \"hits: %v\\n\", err)\n\t\tos.Exit(1)\n\t}\n}\n",
      "note": "**O `Run` recebe o `os.Args` inteiro, nome do programa incluído**, e um `context.Context` que ele repassa a toda Action. É o formato que o próprio README da biblioteca mostra, e a seção 04 trata do que ele faz de errado."
    },
    {
      "code": "// jsonFlag is a function rather than a variable because a flag holds the\n// value it parsed, so two commands must not share one.\nfunc jsonFlag() cli.Flag {\n\treturn &cli.BoolFlag{Name: \"json\", Usage: \"print JSON instead of a table\"}\n}\n",
      "note": "Os dois comandos aceitam `-json`. Nesta biblioteca uma flag é uma struct que guarda o valor que leu, então cada comando ganha uma nova, vinda de uma função, em vez de dividir uma variável."
    },
    {
      "code": "func atLeastOne(n int) error {\n\tif n < 1 {\n\t\treturn fmt.Errorf(\"must be at least 1, got %d\", n)\n\t}\n\treturn nil\n}",
      "note": "O `Validator` do `-n`. Ele recebe o `int` já convertido, depois que a biblioteca recusou tudo o que não é número."
    }
  ]
}
```

As duas Actions e a função que elas compartilham vão no `report.go`, ao lado. Elas fazem o que o
`count`, o `top` e o `summarise` da lição 1 faziam, e diferem em onde buscam as coisas: **toda
Action recebe o `*cli.Command` a que pertence**, e pede a ele as flags pelo nome, os argumentos que
sobraram e os fluxos para ler e escrever. Salve o `report.go`:

```go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"maps"
	"os"
	"slices"
	"text/tabwriter"

	"github.com/urfave/cli/v3"

	"example.com/hits/internal/tally"
)

// count and top are the two Actions. Each receives the command it belongs
// to, which holds the parsed flags, the arguments left over and the streams.
func count(ctx context.Context, cmd *cli.Command) error {
	s, err := summarise(cmd)
	if err != nil {
		return err
	}
	if cmd.Bool("json") {
		return json.NewEncoder(cmd.Writer).Encode(s.ByStatus)
	}
	tw := tabwriter.NewWriter(cmd.Writer, 0, 0, 2, ' ', 0)
	fmt.Fprintln(tw, "status\trequests")
	for _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {
		fmt.Fprintf(tw, "%d\t%d\n", status, s.ByStatus[status])
	}
	return tw.Flush()
}

func top(ctx context.Context, cmd *cli.Command) error {
	s, err := summarise(cmd)
	if err != nil {
		return err
	}
	rows := tally.Top(s, cmd.Int("n"))
	if cmd.Bool("json") {
		return json.NewEncoder(cmd.Writer).Encode(rows)
	}
	tw := tabwriter.NewWriter(cmd.Writer, 0, 0, 2, ' ', 0)
	fmt.Fprintln(tw, "path\trequests")
	for _, r := range rows {
		fmt.Fprintf(tw, "%s\t%d\n", r.Path, r.Hits)
	}
	return tw.Flush()
}

// summarise counts the file named on the command line, or standard input.
// Its errors carry the exit code lesson 1 gave them: 2 for a mistake in the
// call, 1 for a run that failed.
func summarise(cmd *cli.Command) (tally.Summary, error) {
	args := cmd.Args()
	in := cmd.Reader
	switch {
	case args.Len() > 1:
		return tally.Summary{}, cli.Exit(fmt.Sprintf("hits: one file at most, got %d", args.Len()), 2)
	case args.Len() == 1 && args.First() != "-":
		f, err := os.Open(args.First())
		if err != nil {
			return tally.Summary{}, cli.Exit("hits: "+err.Error(), 1)
		}
		defer f.Close()
		in = f
	}
	s, err := tally.Count(in)
	if err != nil {
		return s, cli.Exit("hits: "+err.Error(), 1)
	}
	return s, nil
}
```

Compare o `summarise` com o da lição 1. Lá, ele devolvia um código de saída ao lado do resumo,
porque nada mais no programa sabia o que 1 e 2 significavam. Aqui **um erro pode levar o próprio
código de saída**: o `cli.Exit` embrulha uma mensagem e um número num valor do tipo
`cli.ExitCoder`, que é um `error` com um método `ExitCode`, e quem acabar segurando o erro pode
perguntar a ele que código ele quis dizer. A seção 04 trata de quem é esse alguém.

## Buscando a biblioteca

Com os dois arquivos salvos, os imports citam um módulo que o build ainda não tem. O `go get` o
busca na versão que você indicar e o registra no `go.mod`; o `go mod tidy` então lê os imports e
acerta o arquivo:

```
ana@vm:~/cli-hits$ go get github.com/urfave/cli/v3@v3.14.0
go: downloading github.com/urfave/cli/v3 v3.14.0
go: added github.com/urfave/cli/v3 v3.14.0
ana@vm:~/cli-hits$ go mod tidy && cat go.mod
go: downloading github.com/stretchr/testify v1.12.1
go: downloading go.yaml.in/yaml/v3 v3.0.5
module example.com/hits

go 1.27.1

require github.com/urfave/cli/v3 v3.14.0
```

**O `go.mod` ganhou uma linha, `require github.com/urfave/cli/v3 v3.14.0`**, e essa é toda a marca
que a biblioteca deixa no build: ela não depende de nada fora da biblioteca padrão. O `tidy` ainda
baixou mais dois módulos, `testify` e `yaml`, porque é isso que os testes da própria urfave/cli
importam, e o `tidy` confere os testes daquilo de que você depende. A seção 05 mostra que nenhum dos
dois é compilado no `hits`.

## As mesmas respostas

Compilado, e diante das duas perguntas da lição 1:

```
ana@vm:~/cli-hits$ find . -name "*.go" | sort
./internal/tally/tally.go
./main.go
./report.go
./tools/genlog/main.go
ana@vm:~/cli-hits$ go build -o hits . && stat -c "%s bytes  %n" hits
6257727 bytes  hits
ana@vm:~/cli-hits$ ./hits count access.log
status  requests
200     7554
201     1256
204     1248
301     1192
304     1229
400     1223
401     1226
404     2549
500     1269
503     1254
ana@vm:~/cli-hits$ ./hits top -n 5 access.log
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
/api/users      2512
/api/orders/42  2503
```

**As contagens batem linha a linha com a seção 03 da lição 1**, porque a contagem é o mesmo pacote
lendo as mesmas 20.000 linhas; só mudou o código que lê a linha de comando. O binário é outra
história. **6.257.727 bytes contra os 4.031.903 da lição 1**: a biblioteca e o que ela puxa da
biblioteca padrão somaram cerca de 2,2 MB a um programa que faz exatamente o mesmo trabalho. A
seção 05 põe esse número ao lado do do Cobra, e o resultado não sai do jeito que a palavra "leve"
sugere.
