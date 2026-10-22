---
title: Mais leve em quê? Três versões medidas
version: 1
---

A urfave/cli costuma ser descrita como a alternativa mais leve ao Cobra, e quase ninguém desdobra a
palavra. **Leve pode querer dizer um binário menor, menos módulos em que confiar e atualizar, ou
menos código seu**, e essas são três medidas diferentes que não precisam concordar. Esta seção tira
as três para o mesmo `hits`, construído de três jeitos na mesma máquina: a versão só com a
biblioteca padrão da lição 1, a versão com urfave/cli das seções 02 a 04, e uma versão com Cobra.

## Os três programas

A versão da lição 1 vai para um diretório próprio, `~/std-hits`, com o `main.go` e o pacote `tally`
colocados exatamente como a seção 04 da lição 1 os imprime. A versão com urfave/cli é o
`~/cli-hits` como a seção 04 o deixou. Para o Cobra, a lição 2 explica as peças; o programa abaixo
está aqui só para ser medido, e mantém a mesma saída e os mesmos códigos de saída, com o `-n`
checado para ser pelo menos 1. Em `~/cobra-cmp`, ao lado do mesmo `internal/tally/tally.go`, com um
módulo criado por `go mod init example.com/hits`, salve o `main.go`:

```go
// Command hits summarises a web server's access log, on Cobra.
package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"maps"
	"os"
	"slices"
	"text/tabwriter"

	"github.com/spf13/cobra"

	"example.com/hits/internal/tally"
)

// exitError carries an exit code out of a RunE.
type exitError struct {
	code int
	err  error
}

func (e exitError) Error() string { return e.err.Error() }

func main() {
	os.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))
}

func run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {
	root := &cobra.Command{
		Use:           "hits",
		Short:         "summarise a web server's access log",
		SilenceUsage:  true,
		SilenceErrors: true,
	}
	var asJSON bool
	var n int
	countCmd := &cobra.Command{
		Use:   "count [file]",
		Short: "requests per status code",
		RunE: func(cmd *cobra.Command, args []string) error {
			s, err := summarise(args, stdin)
			if err != nil {
				return err
			}
			if asJSON {
				return json.NewEncoder(stdout).Encode(s.ByStatus)
			}
			tw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)
			fmt.Fprintln(tw, "status\trequests")
			for _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {
				fmt.Fprintf(tw, "%d\t%d\n", status, s.ByStatus[status])
			}
			return tw.Flush()
		},
	}
	countCmd.Flags().BoolVar(&asJSON, "json", false, "print JSON instead of a table")
	topCmd := &cobra.Command{
		Use:   "top [file]",
		Short: "the paths with the most requests",
		RunE: func(cmd *cobra.Command, args []string) error {
			if n < 1 {
				return exitError{2, fmt.Errorf("-n must be at least 1, got %d", n)}
			}
			s, err := summarise(args, stdin)
			if err != nil {
				return err
			}
			rows := tally.Top(s, n)
			if asJSON {
				return json.NewEncoder(stdout).Encode(rows)
			}
			tw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)
			fmt.Fprintln(tw, "path\trequests")
			for _, r := range rows {
				fmt.Fprintf(tw, "%s\t%d\n", r.Path, r.Hits)
			}
			return tw.Flush()
		},
	}
	topCmd.Flags().IntVarP(&n, "limit", "n", 3, "how many paths to show")
	topCmd.Flags().BoolVar(&asJSON, "json", false, "print JSON instead of a table")
	root.AddCommand(countCmd, topCmd)
	root.SetArgs(args)
	root.SetOut(stdout)
	root.SetErr(stderr)
	err := root.Execute()
	if err == nil {
		return 0
	}
	fmt.Fprintf(stderr, "hits: %v\n", err)
	var e exitError
	if errors.As(err, &e) {
		return e.code
	}
	return 2
}

func summarise(args []string, stdin io.Reader) (tally.Summary, error) {
	in := stdin
	switch {
	case len(args) > 1:
		return tally.Summary{}, exitError{2, fmt.Errorf("one file at most, got %d", len(args))}
	case len(args) == 1 && args[0] != "-":
		f, err := os.Open(args[0])
		if err != nil {
			return tally.Summary{}, exitError{1, err}
		}
		defer f.Close()
		in = f
	}
	s, err := tally.Count(in)
	if err != nil {
		return s, exitError{1, err}
	}
	return s, nil
}
```

Busque o Cobra na versão que este curso fixa, compile e confira que ele dá a mesma resposta:

```
ana@vm:~/cobra-cmp$ go get github.com/spf13/cobra@v1.10.2
go: downloading github.com/spf13/cobra v1.10.2
go: downloading github.com/inconshreveable/mousetrap v1.1.0
go: downloading github.com/spf13/pflag v1.0.9
go: added github.com/inconshreveable/mousetrap v1.1.0
go: added github.com/spf13/cobra v1.10.2
go: added github.com/spf13/pflag v1.0.9
ana@vm:~/cobra-cmp$ go build -o hits . && ./hits top -n 2 access.log
path         requests
/login       2576
/api/orders  2542
ana@vm:~/cobra-cmp$ ./hits tpo; echo $?
hits: unknown command "tpo" for "hits"

Did you mean this?
	top

2
ana@vm:~/cobra-cmp$ ./hits completion bash | head -1
# bash completion V2 for hits                                 -*- shell-script -*-
```

Os mesmos dois caminhos com as mesmas contagens da seção 03, e uma sugestão para o erro de digitação
que o Cobra imprime sem que ninguém peça. O Cobra também acrescenta um comando `completion` por
padrão. **O módulo dele trouxe outros dois junto, `pflag` e `mousetrap`**, coisa que o `go get` da
seção 02 não fez: a urfave/cli não depende de nada fora da biblioteca padrão.

## Tamanho, módulos e pacotes

Os três binários, lado a lado:

```
ana@vm:~/std-hits$ go build -o hits . && stat -c "%s bytes  %n" hits ../cli-hits/hits ../cobra-cmp/hits
4031823 bytes  hits
6276176 bytes  ../cli-hits/hits
5107200 bytes  ../cobra-cmp/hits
```

A versão só com a biblioteca padrão fica a 80 bytes dos 4.031.903 da lição 1 com o mesmo
código-fonte, porque um binário Go registra os caminhos dos arquivos de que foi compilado, e estes
foram compilados em `~/std-hits` e não em `~/hits`. Os outros dois números são a medida: **a versão
com urfave/cli é a maior das três, 1.168.976 bytes maior que a com Cobra**. Seja o que for que
"mais leve" quer dizer, não quer dizer o binário, pelo menos não nestas versões. A medida não diz
por quê; a lição 17 desmonta binários e é onde procurar.

Depois, os módulos de que cada build depende, que é o que o `go list -m all` imprime:

```
ana@vm:~/std-hits$ go list -m all
example.com/hits
ana@vm:~/cli-hits$ go list -m all
example.com/hits
github.com/stretchr/testify v1.12.1
github.com/urfave/cli/v3 v3.14.0
go.yaml.in/yaml/v3 v3.0.5
ana@vm:~/cobra-cmp$ go list -m all
example.com/hits
github.com/cpuguy83/go-md2man/v2 v2.0.6
github.com/inconshreveable/mousetrap v1.1.0
github.com/russross/blackfriday/v2 v2.1.0
github.com/spf13/cobra v1.10.2
github.com/spf13/pflag v1.0.9
go.yaml.in/yaml/v3 v3.0.4
gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405
```

**Nem todo módulo listado é compilado.** O `go list -m all` é o grafo de módulos: todo módulo que
alguma exigência cita, inclusive os que uma dependência só usa nos próprios testes ou em pacotes que
você nunca importa. `testify` e `yaml` são as bibliotecas de teste da urfave/cli, que o `tidy` da
seção 02 baixou; `go-md2man` e `blackfriday` servem ao gerador de páginas de manual do Cobra. O que
de fato entra no binário é uma pergunta sobre pacotes, e o `go list -deps` a responde:

```
ana@vm:~/cli-hits$ go list -deps . | grep "\."
main_test.go:1:1: expected 'package', found 'EOF'
ana@vm:~/cobra-cmp$ go list -deps . | grep "\."
example.com/hits/internal/tally
vendor/golang.org/x/net/dns/dnsmessage
github.com/spf13/pflag
github.com/spf13/cobra
example.com/hits
```

O `grep` fica com os caminhos de import que têm ponto, o que deixa de fora os da biblioteca padrão.
**Um pacote de terceiros no build com urfave/cli, dois no do Cobra**, e o do Cobra ainda traz um
pacote que a biblioteca padrão carrega embutido, o `dnsmessage`, que faz parte do resolvedor do
pacote `net`. O `net` chega pelo `pflag`, cujas flags incluem endereços IP e redes. O `mousetrap` não
está em nenhuma das listas porque o Cobra só o importa num arquivo compilado para Windows. É nesse
sentido que a urfave/cli é mais leve: **um módulo, sem nada atrás dele**, é um nome num relatório
de vulnerabilidades e uma atualização para revisar.

## Linhas, e o que elas compram

```
ana@vm:~/std-hits$ wc -l main.go ../cli-hits/main.go ../cli-hits/report.go ../cobra-cmp/main.go
  144 main.go
  103 ../cli-hits/main.go
   74 ../cli-hits/report.go
  119 ../cobra-cmp/main.go
  440 total
```

A versão com a biblioteca é a mais longa, 177 linhas contra 144, e a contagem esconde mais do
que mostra. Boa parte das 144 da lição 1 é um texto de uso escrito à mão e o `switch` do despacho, e
boa parte das 177 da urfave/cli são literais de struct declarando coisas que a lição 1 nem tinha. A
versão com Cobra é mais curta que as duas porque faz menos. Ela não tem variável de ambiente nem
validador, então a checagem do `-n` fica escrita no comando. E cada flag tem um nome longo e um
atalho de uma letra, que é tudo o que uma flag do pflag pode ter, onde a urfave/cli aceita quantos
apelidos você quiser. O que as linhas compram fica mais claro com a mesma chamada feita ao binário da lição 1:

```
ana@vm:~/std-hits$ ./hits top access.log -n 2; echo $?
hits: one file at most, got 3
2
```

| | biblioteca padrão (lição 1) | urfave/cli v3.14.0 | Cobra v1.10.2 |
|---|---|---|---|
| binário | 4.031.823 bytes | 6.276.176 bytes | 5.107.200 bytes |
| módulos em `go list -m all` | 1 | 4 | 8 |
| pacotes de terceiros compilados | 0 | 1 | 2 |
| linhas de código de linha de comando | 144 | 177 | 119 |
| flags depois dos argumentos | não | sim | sim |
| ajuda | escrita à mão | gerada | gerada |
| sugestão para erro de digitação | nenhuma | `cli.SuggestCommand`, chamado à mão | embutida |
| completação no shell | nenhuma | um campo | um comando por padrão |
| uma flag vinda do ambiente | à mão | `Sources: cli.EnvVars(…)` | à mão, ou uma segunda biblioteca |

**Uma flag vinda do ambiente é um campo na urfave/cli e nada no Cobra**: a struct `Flag` do pflag
não tem campo para isso. A resposta do Cobra costuma ser uma biblioteca companheira, o Viper, que é
mais um módulo e não é assunto de nenhuma lição deste curso.

## Qual, e quando

**A biblioteca padrão** serve para uma ferramenta com um ou dois comandos, poucas flags e um motivo
para continuar pequena ou sem dependências. Exemplos são um auxiliar distribuído dentro de uma
imagem de contêiner, um programa num repositório cuja política é não ter código de terceiros e
qualquer coisa de que o pacote flag da lição 21 do `go-concurrency` dê conta. O custo é a lista de recursos de vinte
linhas da lição 1, escritos por você ou deixados de lado.

**A urfave/cli** serve para uma ferramenta com alguns comandos que quer um tratamento moderno de
flags, valores vindos do ambiente e ajuda e completação geradas, a partir de **uma dependência sem
dependências próprias**. O programa é um único literal que se lê de cima a baixo, e com `Reader`,
`Writer`, `ErrWriter` e `ExitErrHandler` definidos ele se testa como o da lição 1. O custo são os
padrões da seção 04, que precisam ser substituídos um gancho por vez, e um binário que não é
pequeno.

**O Cobra** serve para uma árvore grande de comandos, do tipo que o Kubernetes, o Hugo e o GitHub
CLI têm, os três citados no próprio README do Cobra. Ele traz um gerador, saída de documentação como
páginas de manual, e o formato de muitas ferramentas Go conhecidas, então quem o usa encontra algo
familiar. A lição 2 trata dele. O que ele custa são dois módulos compilados, o `net` entre os
pacotes, e uma segunda biblioteca no dia em que uma flag precisar vir do ambiente.

Nenhuma das três muda o `tally`, e é a decisão da seção 04 da lição 1 rendendo pela segunda vez.
**A linha de comando é uma camada fina sobre um pacote que não sabe nada dela**, então trocar a
camada é coisa de uma tarde. As medidas acima podem ser tiradas de novo quando sair a próxima
versão de qualquer uma das três.
