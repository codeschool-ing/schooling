---
title: Um reporter num objeto compartilhado
version: 1
---

Quem chega do Python, do Java ou de um programa em C com uma `.dll` ao lado costuma ler o pacote
`plugin` do Go como a mesma ideia: um binário que sai hoje e extensões que desconhecidos compilam e
colocam no lugar no ano que vem. **Um plugin Go é bem mais estreito que isso. É um pedaço de um
programa, compilado à parte, que precisa bater exatamente com o resto do programa.** É um pacote
`main` compilado com `go build -buildmode=plugin` num objeto compartilhado ELF, um arquivo `.so`. Um
programa em execução o abre com `plugin.Open`, acha uma variável ou função exportada pelo nome com
`Lookup` e a chama. A interface inteira é isso: duas funções e um tipo.

Esta seção constrói dois plugins para o `hits` e os carrega. A seção 03 é a lista dos jeitos como
esses mesmos dois plugins se recusam a carregar.

## Reporters

O `hits` imprime uma tabela ou JSON, e os formatos estão escritos no `main.go`. Um reporter é um
formato que mora fora dele: algo que recebe as contagens e as escreve. O trabalho acontece em
`~/plugins`, um módulo próprio chamado de novo `example.com/hits`, com o pacote `tally` e o
`tools/genlog` da lição 1, colocados ali sem mudança, e um `access.log` de 20.000 linhas gerado por
`genlog -n 20000`. O que é um reporter fica num pacote que todos importam, `report/report.go`:

```go
// Package report says what a reporter is, and keeps a list of the ones
// the program has.
package report

import (
	"io"
	"maps"
	"slices"

	"example.com/hits/internal/tally"
)

// A Reporter writes a summary out in a format of its own.
type Reporter interface {
	Report(s tally.Summary, w io.Writer) error
}

var registry = map[string]Reporter{}

// Register makes a reporter available by name. It is meant to be called
// from an init function, and it panics if the name is taken.
func Register(name string, r Reporter) {
	if _, dup := registry[name]; dup {
		panic("report: Register called twice for " + name)
	}
	registry[name] = r
}

// Get returns the reporter registered under name.
func Get(name string) (Reporter, bool) {
	r, ok := registry[name]
	return r, ok
}

// Names lists the registered reporters in alphabetical order.
func Names() []string {
	return slices.Sorted(maps.Keys(registry))
}
```

**A interface tem um método, e o registro ao lado é o padrão que o `database/sql` usa para os
drivers**: um mapa preenchido por `Register`, que entra em pânico com um nome repetido exatamente
como o `sql.Register`, e lido pelo nome. Nada nesta seção o usa para escolher um reporter. Ele está
aqui pelo que mostra sobre onde o código de um plugin roda, alguns parágrafos abaixo, e a seção 04
o usa sozinho.

Dois reporters, cada um um pacote comum que se registra no `init`. O primeiro escreve as contagens
por status em CSV, `reporters/csv/csv.go`:

```go
// Package csv writes the status counts of a summary as CSV.
package csv

import (
	"encoding/csv"
	"io"
	"maps"
	"slices"
	"strconv"

	"example.com/hits/internal/tally"
	"example.com/hits/report"
)

// Reporter is the CSV reporter.
type Reporter struct{}

func (Reporter) Report(s tally.Summary, w io.Writer) error {
	cw := csv.NewWriter(w)
	cw.Write([]string{"status", "requests"})
	for _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {
		cw.Write([]string{strconv.Itoa(status), strconv.Itoa(s.ByStatus[status])})
	}
	cw.Flush()
	return cw.Error()
}

func init() { report.Register("csv", Reporter{}) }
```

O `reporters/mean/mean.go` imprime quantas requisições houve e quanto uma levou em média:

```go
// Package mean reports how long a request took on average.
package mean

import (
	"fmt"
	"io"
	"time"

	"example.com/hits/internal/tally"
	"example.com/hits/report"
)

// Reporter is the mean-duration reporter.
type Reporter struct{}

func (Reporter) Report(s tally.Summary, w io.Writer) error {
	avg := s.Total / time.Duration(s.Lines)
	_, err := fmt.Fprintf(w, "%d requests, mean %v\n", s.Lines, avg.Round(time.Millisecond))
	return err
}

func init() { report.Register("mean", Reporter{}) }
```

Nenhum dos dois sabe algo sobre plugins. Eles viram plugins por meio de um pacote `main` cada um, e
esses são os arquivos mais curtos do curso. `plugins/csv/main.go`:

```go
// Command csv is the CSV reporter, built as a Go plugin.
package main

import (
	"example.com/hits/report"
	"example.com/hits/reporters/csv"
)

// Reporter is a variable: Lookup returns a *report.Reporter.
var Reporter report.Reporter = csv.Reporter{}
```

`plugins/mean/main.go`:

```go
// Command mean is the mean-duration reporter, built as a Go plugin.
package main

import (
	"example.com/hits/report"
	"example.com/hits/reporters/mean"
)

// Reporter is a function: Lookup returns it as a func() report.Reporter.
func Reporter() report.Reporter { return mean.Reporter{} }
```

**O que um plugin oferece ao hospedeiro são seus nomes exportados de nível de pacote, e nada
mais.** Não há função `main`, porque o `main` de um plugin nunca rodaria: o `go doc plugin` diz que
abrir um plugin chama as funções `init`, e não o `main`. Os dois arquivos exportam `Reporter` nas
duas formas que o `Lookup` pode devolver, uma variável no `csv` e uma função no `mean`. Cada um é
compilado com o próprio comando:

```
ana@vm:~/plugins$ go build -buildmode=plugin -o csv.so ./plugins/csv
ana@vm:~/plugins$ go build -buildmode=plugin -o mean.so ./plugins/mean
ana@vm:~/plugins$ stat -c "%s bytes  %n" csv.so mean.so
3724624 bytes  csv.so
4678072 bytes  mean.so
```

Dois arquivos de **3,7 e 4,7 MB** para reporters de umas vinte linhas cada. Um plugin carrega todo
pacote que importa, o runtime incluído, e o `mean` importa `fmt` e `time` além do que o `csv`
precisa. A seção 03 explica por que a maior parte desses bytes nunca é usada depois que o plugin
carrega.

## O hospedeiro

O programa que os carrega é o `cmd/hits-plugin/main.go`. Ele conta o log como a lição 1 faz e
depois entrega o resumo a cada plugin citado na linha de comando:

```schooling-example
{
  "language": "go",
  "file": "cmd/hits-plugin/main.go",
  "parts": [
    {
      "code": "// Command hits-plugin counts a log and hands the summary to reporters\n// loaded from Go plugins.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"os\"\n\t\"plugin\"\n\n\t\"example.com/hits/internal/tally\"\n\t\"example.com/hits/report\"\n)\n",
      "note": "**`plugin` é um import comum da biblioteca padrão**, e importá-lo muda a forma como este programa é ligado: a seção 03 mostra a diferença."
    },
    {
      "code": "func main() {\n\tif len(os.Args) < 3 {\n\t\tfmt.Fprintln(os.Stderr, \"usage: hits-plugin <log> <plugin.so>...\")\n\t\tos.Exit(2)\n\t}\n\ts, err := count(os.Args[1])\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"hits-plugin:\", err)\n\t\tos.Exit(1)\n\t}\n\tfor _, path := range os.Args[2:] {\n\t\tr, err := load(path)\n\t\tif err == nil {\n\t\t\terr = r.Report(s, os.Stdout)\n\t\t}\n\t\tif err != nil {\n\t\t\tfmt.Fprintln(os.Stderr, \"hits-plugin:\", err)\n\t\t\tos.Exit(1)\n\t\t}\n\t}",
      "note": "O primeiro argumento é o log, e cada argumento depois dele é um arquivo de plugin. Cada um é carregado e recebe o mesmo resumo, na ordem em que foram citados."
    },
    {
      "code": "\tfmt.Fprintln(os.Stderr, \"hits-plugin: registered\", report.Names())\n}\n",
      "note": "Um diagnóstico na saída de erro: os nomes no registro do hospedeiro depois que todos os plugins foram abertos. Nada no `main` registra coisa alguma, então o que aparece aqui foi posto ali por um plugin."
    },
    {
      "code": "func count(name string) (tally.Summary, error) {\n\tf, err := os.Open(name)\n\tif err != nil {\n\t\treturn tally.Summary{}, err\n\t}\n\tdefer f.Close()\n\treturn tally.Count(f)\n}\n",
      "note": "A contagem é a da lição 1, sem mudança."
    },
    {
      "code": "func load(path string) (report.Reporter, error) {\n\tp, err := plugin.Open(path)\n\tif err != nil {\n\t\treturn nil, err\n\t}",
      "note": "**`plugin.Open` mapeia o arquivo no processo e roda as funções `init` de todo pacote que o programa ainda não tinha.** É ali que `csv` e `mean` se registram. Um caminho aberto pela segunda vez devolve o mesmo `*Plugin` sem rodar nada."
    },
    {
      "code": "\tsym, err := p.Lookup(\"Reporter\")\n\tif err != nil {\n\t\treturn nil, err\n\t}",
      "note": "O `Lookup` acha um nome exportado e o devolve como `plugin.Symbol`, que é `any`. O nome é uma string, então um erro de digitação aparece quando o programa roda, nunca quando compila."
    },
    {
      "code": "\tswitch v := sym.(type) {\n\tcase *report.Reporter:\n\t\treturn *v, nil\n\tcase func() report.Reporter:\n\t\treturn v(), nil\n\t}\n\treturn nil, fmt.Errorf(\"%s: Reporter is a %T\", path, sym)\n}",
      "note": "**Uma variável volta como um ponteiro para a variável, e uma função volta como a própria função.** Por isso `plugins/csv` chega como `*report.Reporter` e `plugins/mean` como `func() report.Reporter`. Afirmar `sym.(report.Reporter)` no primeiro falha, porque um ponteiro para interface não tem métodos."
    }
  ]
}
```

Compilado e rodado com os dois plugins:

```
ana@vm:~/plugins$ go build -o hits-plugin ./cmd/hits-plugin
ana@vm:~/plugins$ ./hits-plugin access.log csv.so mean.so
status,requests
200,7554
201,1256
204,1248
301,1192
304,1229
400,1223
401,1226
404,2549
500,1269
503,1254
20000 requests, mean 200ms
hits-plugin: registered [csv mean]
```

O CSV é a tabela de status da lição 1, e a média é 200 ms em 20.000 requisições. A última linha é a
que merece uma segunda leitura. **`registered [csv mean]` vem do registro do próprio hospedeiro, e
nada no hospedeiro jamais chamou `Register`**: as funções `init` dentro dos dois arquivos `.so`
rodaram quando o `plugin.Open` os carregou, e escreveram no mapa que o `cmd/hits-plugin` importou. O
plugin não ganhou um registro só dele.

O mesmo arquivo citado duas vezes mostra a outra regra que o `plugin.Open` segue:

```
ana@vm:~/plugins$ ./hits-plugin access.log csv.so csv.so | wc -l
hits-plugin: registered [csv]
22
```

Vinte e duas linhas são as onze linhas do CSV duas vezes, então o reporter rodou duas vezes. O
`init` dele rodou uma vez só: um segundo `Register("csv", …)` teria entrado em pânico com
`Register called twice for csv`. **Um caminho que já foi aberto devolve o plugin que está na
memória**, inicializado uma vez e mantido pela vida inteira do processo.

Importar `plugin` também muda o tipo de arquivo que o hospedeiro é:

```
ana@vm:~/plugins$ stat -c "%s bytes  %n" hits-plugin
4897008 bytes  hits-plugin
ana@vm:~/plugins$ readelf -d hits-plugin | grep NEEDED
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
```

O `hits-plugin` não tem reporter nenhum e, com 4.897.008 bytes, já é maior que o `hits` inteiro da
lição 1, que tinha 4.031.903. **E ele precisa da `libc.so.6`**, porque carregar um objeto
compartilhado em tempo de execução é o `dlopen` da biblioteca C, alcançado via cgo. Um hospedeiro que
carrega plugins é um programa ligado dinamicamente, seja lá o que ele carregue, e mesmo que não
carregue nada.
