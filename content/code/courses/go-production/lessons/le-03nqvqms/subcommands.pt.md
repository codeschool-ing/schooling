---
title: Uma ferramenta, vários comandos
version: 1
---

`go build`, `go test` e `go vet` são um programa só. `git commit` e `git log` também. **Uma
ferramenta com subcomandos é um único binário cujo primeiro argumento escolhe o que ele faz**, e
cada escolha aceita flags próprias: `go test -run` não significa nada para o `go build`. O `hits` é
montado assim, com dois subcomandos, `count` e `top`, e nada além da biblioteca padrão.

Ele vem em duas partes, e a divisão é a primeira decisão que vale copiar. A contagem não tem relação
com linha de comando, então fica num pacote próprio, `internal/tally`. O diretório `internal` deixa
o pacote importável de dentro deste módulo e de mais lugar nenhum, o que dá liberdade para mudá-lo.
As lições 2 a 4 colocam três linhas de comando diferentes na frente deste mesmo pacote, e as lições
12 e 13 o deixam mais rápido. Salve-o como `internal/tally/tally.go`:

```go
// Package tally reads the lines of an access log and counts them.
package tally

import (
	"bufio"
	"cmp"
	"fmt"
	"io"
	"slices"
	"strconv"
	"strings"
	"time"
)

// Entry is one line of the log.
type Entry struct {
	Time     time.Time
	Method   string
	Path     string
	Status   int
	Duration time.Duration
}

// Parse reads one line: a time, a method, a path, a status and a duration,
// separated by spaces.
func Parse(line string) (Entry, error) {
	f := strings.Fields(line)
	if len(f) != 5 {
		return Entry{}, fmt.Errorf("want 5 fields, got %d", len(f))
	}
	t, err := time.Parse(time.RFC3339, f[0])
	if err != nil {
		return Entry{}, err
	}
	status, err := strconv.Atoi(f[3])
	if err != nil {
		return Entry{}, fmt.Errorf("status: %w", err)
	}
	d, err := time.ParseDuration(f[4])
	if err != nil {
		return Entry{}, err
	}
	return Entry{Time: t, Method: f[1], Path: f[2], Status: status, Duration: d}, nil
}

// Summary is what Count found.
type Summary struct {
	Lines    int
	ByStatus map[int]int
	ByPath   map[string]int
	Total    time.Duration
}

// Count reads every line from r. A line it cannot parse stops it, and the
// error names the line.
func Count(r io.Reader) (Summary, error) {
	s := Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}
	sc := bufio.NewScanner(r)
	for n := 1; sc.Scan(); n++ {
		e, err := Parse(sc.Text())
		if err != nil {
			return s, fmt.Errorf("line %d: %w", n, err)
		}
		s.Lines++
		s.ByStatus[e.Status]++
		s.ByPath[e.Path]++
		s.Total += e.Duration
	}
	return s, sc.Err()
}

// PathCount is one row of Top.
type PathCount struct {
	Path string `json:"path"`
	Hits int    `json:"hits"`
}

// Top returns the n paths with the most requests, the most first. Paths
// with the same count come in alphabetical order.
func Top(s Summary, n int) []PathCount {
	rows := make([]PathCount, 0, len(s.ByPath))
	for p, h := range s.ByPath {
		rows = append(rows, PathCount{p, h})
	}
	slices.SortFunc(rows, func(a, b PathCount) int {
		return cmp.Or(cmp.Compare(b.Hits, a.Hits), cmp.Compare(a.Path, b.Path))
	})
	return rows[:min(n, len(rows))]
}
```

O `Parse` transforma uma linha numa `Entry` e diz com precisão o que há de errado numa linha que
não consegue ler. O `Count` lê linhas até a entrada acabar e mantém três contagens. O `Top` ordena
os caminhos pela contagem e desempata em ordem alfabética, de modo que duas execuções sobre o mesmo
log imprimem sempre a mesma tabela. **Nada ali imprime ou encerra o programa**: o pacote devolve
valores e erros, e decidir o que uma pessoa vê é trabalho da linha de comando.

## A linha de comando

A segunda parte é o `main.go`, na raiz do módulo, e ela trata só de quem está digitando. Leia em
pedaços:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"encoding/json\"\n\t\"errors\"\n\t\"flag\"\n\t\"fmt\"\n\t\"io\"\n\t\"maps\"\n\t\"os\"\n\t\"slices\"\n\t\"text/tabwriter\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "O comentário de documentação do pacote dá o nome do comando, que é a convenção para um pacote `main`. O `tally` é importado pelo caminho completo dentro deste módulo."
    },
    {
      "code": "const usage = `usage: hits <command> [flags] [file]\n\ncommands:\n  count   requests per status code\n  top     the paths with the most requests\n\nWith no file, or with -, hits reads standard input.\n`\n",
      "note": "O texto impresso quando alguém pede ajuda ou erra o comando. **Escrito à mão**, porque nada na biblioteca padrão sabe que este programa tem subcomandos."
    },
    {
      "code": "func main() {\n\tos.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))\n}\n",
      "note": "**O `main` faz uma coisa só: passa os argumentos e os fluxos do processo para o `run` e sai com o que o `run` devolver.** Tudo o que dá para testar fica no `run`, que a seção 05 testa sem iniciar processo nenhum."
    },
    {
      "code": "func run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tif len(args) == 0 {\n\t\tfmt.Fprint(stderr, usage)\n\t\treturn 2\n\t}\n\tswitch args[0] {\n\tcase \"count\":\n\t\treturn count(args[1:], stdin, stdout, stderr)\n\tcase \"top\":\n\t\treturn top(args[1:], stdin, stdout, stderr)\n\tcase \"help\", \"-h\", \"-help\", \"--help\":\n\t\tfmt.Fprint(stdout, usage)\n\t\treturn 0\n\t}\n\tfmt.Fprintf(stderr, \"hits: unknown command %q\\n\\n%s\", args[0], usage)\n\treturn 2\n}\n",
      "note": "A primeira palavra escolhe o subcomando e o resto é entregue a ele. Uma linha de comando vazia e uma palavra desconhecida são erros de quem chamou, então as duas imprimem o uso na saída de erro e devolvem 2."
    },
    {
      "code": "func count(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"count\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}",
      "note": "**Cada subcomando tem o seu `flag.FlagSet`**, com flags que nenhum outro subcomando vê. O `ContinueOnError` faz o `Parse` devolver o erro em vez de encerrar, e assim o subcomando escolhe o código de saída; o `SetOutput` manda as mensagens do pacote flag para o mesmo fluxo de todas as outras reclamações."
    },
    {
      "code": "\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, s.ByStatus)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"status\\trequests\")\n\tfor _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {\n\t\tfmt.Fprintf(tw, \"%d\\t%d\\n\", status, s.ByStatus[status])\n\t}\n\treturn flush(tw, stderr)\n}\n",
      "note": "O que sobra depois das flags é o arquivo a ler. A tabela passa por um `tabwriter`, que alinha cada coluna pela célula mais larga; os códigos de status saem ordenados porque um map não tem ordem própria."
    },
    {
      "code": "func top(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"top\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tn := fs.Int(\"n\", 3, \"how many paths to show\")\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}\n\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\trows := tally.Top(s, *n)\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, rows)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"path\\trequests\")\n\tfor _, r := range rows {\n\t\tfmt.Fprintf(tw, \"%s\\t%d\\n\", r.Path, r.Hits)\n\t}\n\treturn flush(tw, stderr)\n}\n",
      "note": "O segundo subcomando tem uma flag a mais que o primeiro, `-n`, e a mesma forma no resto."
    },
    {
      "code": "// summarise counts the file named in args, or standard input.\nfunc summarise(args []string, stdin io.Reader, stderr io.Writer) (tally.Summary, int) {\n\tin := stdin\n\tswitch {\n\tcase len(args) > 1:\n\t\tfmt.Fprintf(stderr, \"hits: one file at most, got %d\\n\", len(args))\n\t\treturn tally.Summary{}, 2\n\tcase len(args) == 1 && args[0] != \"-\":\n\t\tf, err := os.Open(args[0])\n\t\tif err != nil {\n\t\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\t\treturn tally.Summary{}, 1\n\t\t}\n\t\tdefer f.Close()\n\t\tin = f\n\t}\n\ts, err := tally.Count(in)\n\tif err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn s, 1\n\t}\n\treturn s, 0\n}\n",
      "note": "**Nenhum arquivo, ou um arquivo chamado `-`, quer dizer entrada padrão.** Dois arquivos é erro de uso e leva 2; um arquivo que não abre, ou uma linha que não converte, é falha da execução e leva 1."
    },
    {
      "code": "// flush writes out a table, and encode a value as JSON. A write can fail,\n// on a full disk for one, and that is reported.\nfunc flush(tw *tabwriter.Writer, stderr io.Writer) int {\n\tif err := tw.Flush(); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n\nfunc encode(stdout, stderr io.Writer, v any) int {\n\tif err := json.NewEncoder(stdout).Encode(v); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n",
      "note": "**Uma escrita pode falhar**, num disco cheio ou num arquivo fechado, e as duas formas de escrever informam a falha em vez de descartá-la. Uma tabela fica retida no `tabwriter` até o `Flush`, então é ali que o erro dela aparece."
    },
    {
      "code": "// flagError turns a failed parse into an exit code. The flag package has\n// already printed the message and the usage.\nfunc flagError(err error) int {\n\tif errors.Is(err, flag.ErrHelp) {\n\t\treturn 0\n\t}\n\treturn 2\n}",
      "note": "O `-h` volta do `Parse` como `flag.ErrHelp`. Pedir ajuda não é erro, então é 0; qualquer outra coisa que o pacote recusou é 2."
    }
  ]
}
```

Compilado, e diante das duas perguntas sobre as 20.000 linhas:

```
ana@vm:~/hits$ find . -name "*.go" | sort
./internal/tally/tally.go
./main.go
./tools/genlog/main.go
ana@vm:~/hits$ go build -o hits . && stat -c "%s bytes  %n" hits
4031903 bytes  hits
ana@vm:~/hits$ ./hits count access.log
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
ana@vm:~/hits$ ./hits top -n 5 access.log
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
/api/users      2512
/api/orders/42  2503
ana@vm:~/hits$ ./hits top -json access.log
[{"path":"/login","hits":2576},{"path":"/api/orders","hits":2542},{"path":"/static/app.js","hits":2526}]
```

O `200` é pouco mais de um terço do log, o que os seis `200` na lista de dezesseis do `genlog`
preveem, e o `404` é cerca do dobro de qualquer outro erro porque aparece duas vezes na lista. O
JSON saiu com o padrão de três caminhos e com os nomes de campo das tags da struct em `tally`. Um
binário de **4.031.903 bytes** para um programa tão pequeno é o runtime mais as partes da biblioteca
padrão que ele usa; a lição 17 o desmonta.

## Erros, e de quem são

O despacho escrito à mão precisa cuidar do que o pacote flag cuidava de graça na seção 03. Aqui
está o programa chamado sem nada, com um erro de digitação, com um pedido de ajuda e com um valor
inválido:

```
ana@vm:~/hits$ ./hits; echo $?
usage: hits <command> [flags] [file]

commands:
  count   requests per status code
  top     the paths with the most requests

With no file, or with -, hits reads standard input.
2
ana@vm:~/hits$ ./hits cont access.log; echo $?
hits: unknown command "cont"

usage: hits <command> [flags] [file]

commands:
  count   requests per status code
  top     the paths with the most requests

With no file, or with -, hits reads standard input.
2
ana@vm:~/hits$ ./hits top -h; echo $?
Usage of top:
  -json
    	print JSON instead of a table
  -n int
    	how many paths to show (default 3)
0
ana@vm:~/hits$ ./hits top -n five access.log; echo $?
invalid value "five" for flag -n: parse error
Usage of top:
  -json
    	print JSON instead of a table
  -n int
    	how many paths to show (default 3)
2
```

**Todos esses são erros de quem chamou, e todos terminam em 2**, menos o pedido de ajuda, que não é
erro. A listagem do `-h` pertence só ao `top` e não sabe nada do `count`, porque cada `FlagSet`
descreve apenas as próprias flags.

O que ele não faz também fica à vista. `cont` está a uma letra de `count`, e o programa não avisa.
`hits help top` imprime o uso geral, não o do `top`. Não há como completar o nome de um subcomando
com a tecla Tab. Cada uma dessas coisas são vinte linhas que você poderia escrever à mão. **Essa
pilha de recursos de vinte linhas é exatamente o Cobra da lição 2**: o mesmo programa, com o
despacho, a ajuda, as sugestões e o autocompletar escritos uma vez por outra pessoa.
