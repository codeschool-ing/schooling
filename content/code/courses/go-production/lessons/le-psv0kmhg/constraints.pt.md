---
title: A linha `//go:build`
version: 1
---

Quando um código precisa ser diferente no Windows e no Linux, a primeira coisa que a maioria das
pessoas escreve é um `if runtime.GOOS == "windows"`. **Isso só funciona enquanto todo ramo compila
em todo sistema.** Um ramo que cita `syscall.SIGUSR1` não compila para Windows, cujo pacote `syscall`
não tem esse nome, e o compilador recusa o programa inteiro antes que algum ramo tenha a chance de
não rodar. Uma restrição de build atua um nível acima: ela decide quais arquivos o compilador recebe,
então um arquivo que não compilaria para Windows simplesmente não faz parte de um build para Windows.

Esta seção acrescenta ao `hits` um recurso que precisa exatamente disso, escreve do jeito ingênuo,
vê falhar e depois divide em um arquivo por tipo de sistema.

## Um recurso que muda conforme o sistema

Contar um log grande leva tempo, e quem espera quer saber até onde a contagem chegou. **O Unix tem
uma convenção para fazer essa pergunta a um programa em execução: mandar um sinal.** O `dd` do GNU
imprime o progresso quando recebe `SIGUSR1`, e no macOS e nos BSDs apertar Ctrl-T envia `SIGINFO`,
que as ferramentas deles respondem do mesmo jeito. O Windows não tem nenhum dos dois sinais. O pacote
`os/signal` pede ao runtime do Go que entregue os sinais escolhidos num canal em vez de agir sobre
eles, e é só disso que o `hits` precisa.

O trabalho acontece num diretório novo, `~/tags`, com o `hits` da aula 1: o pacote `tally`, o
`main_test.go` e o `genlog`, com o módulo criado por `go mod init example.com/hits` e o `access.log`
de 20.000 linhas que `go run ./tools/genlog -n 20000` escreve. Dois arquivos são novos. O primeiro
conta o que passa por ele e informa a contagem quando chega um sinal:

```schooling-example
{
  "language": "go",
  "file": "progress.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"os\"\n\t\"os/signal\"\n\t\"sync/atomic\"\n)\n",
      "note": "Nada neste arquivo cita um sistema. **Ele compila para todo alvo do jeito que está**, e é por isso que é um arquivo só: a parte que muda é uma única variável, `progressSignals`, que ele usa e não define."
    },
    {
      "code": "// progress counts the bytes read through it, so that a long count can say\n// how far it has got.\ntype progress struct {\n\tr io.Reader\n\tn atomic.Int64\n}\n\nfunc (p *progress) Read(b []byte) (int, error) {\n\tn, err := p.r.Read(b)\n\tp.n.Add(int64(n))\n\treturn n, err\n}\n",
      "note": "Um leitor que embrulha outro e conta o que passa por ele, o tipo de composição que a aula 17 do `go-concurrency` monta. O `tally.Count` lê dele sem saber. A contagem é um `atomic.Int64` porque a goroutine abaixo a lê enquanto o `Count` ainda está somando."
    },
    {
      "code": "// watch prints the count on stderr each time one of progressSignals\n// arrives, until the function it returns is called.\nfunc (p *progress) watch(stderr io.Writer) (stop func()) {\n\tif len(progressSignals) == 0 {\n\t\treturn func() {}\n\t}\n\tc := make(chan os.Signal, 1)\n\tsignal.Notify(c, progressSignals...)\n\tdone := make(chan struct{})",
      "note": "**Uma lista vazia quer dizer nenhum sinal.** Sem essa checagem, `signal.Notify(c)` sem nada depois repassaria todo sinal que o processo recebe, o contrário do que quer um sistema sem sinal de progresso."
    },
    {
      "code": "\tgo func() {\n\t\tfor {\n\t\t\tselect {\n\t\t\tcase <-c:\n\t\t\t\tfmt.Fprintf(stderr, \"hits: %d bytes read\\n\", p.n.Load())\n\t\t\tcase <-done:\n\t\t\t\treturn\n\t\t\t}\n\t\t}\n\t}()\n\treturn func() {\n\t\tsignal.Stop(c)\n\t\tclose(done)\n\t}\n}",
      "note": "A goroutine espera num `select`, como na aula 5 do `go-concurrency`, por um sinal ou pelo `stop`. **O `stop` cancela o registro do canal e fecha `done`**, então a goroutine termina junto com a contagem em vez de sobreviver a ela, que é o assunto da aula 6 do `go-concurrency`."
    }
  ]
}
```

O segundo é o `main.go`, que substitui o da aula 1. Ele muda numa função e ganha uma variável; copie
o arquivo inteiro por cima do antigo:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"encoding/json\"\n\t\"errors\"\n\t\"flag\"\n\t\"fmt\"\n\t\"io\"\n\t\"maps\"\n\t\"os\"\n\t\"slices\"\n\t\"text/tabwriter\"\n\t\"time\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "O `main.go` da aula 1 com um import a mais, `time`. **Tudo acima de `summarise` está igual**, e também tudo abaixo de `debugf`."
    },
    {
      "code": "const usage = `usage: hits <command> [flags] [file]\n\ncommands:\n  count   requests per status code\n  top     the paths with the most requests\n\nWith no file, or with -, hits reads standard input.\n`\n\nfunc main() {\n\tos.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))\n}\n\nfunc run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tif len(args) == 0 {\n\t\tfmt.Fprint(stderr, usage)\n\t\treturn 2\n\t}\n\tswitch args[0] {\n\tcase \"count\":\n\t\treturn count(args[1:], stdin, stdout, stderr)\n\tcase \"top\":\n\t\treturn top(args[1:], stdin, stdout, stderr)\n\tcase \"help\", \"-h\", \"-help\", \"--help\":\n\t\tfmt.Fprint(stdout, usage)\n\t\treturn 0\n\t}\n\tfmt.Fprintf(stderr, \"hits: unknown command %q\\n\\n%s\", args[0], usage)\n\treturn 2\n}\n\nfunc count(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"count\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}\n\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, s.ByStatus)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"status\\trequests\")\n\tfor _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {\n\t\tfmt.Fprintf(tw, \"%d\\t%d\\n\", status, s.ByStatus[status])\n\t}\n\treturn flush(tw, stderr)\n}\n\nfunc top(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"top\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tn := fs.Int(\"n\", 3, \"how many paths to show\")\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}\n\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\trows := tally.Top(s, *n)\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, rows)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"path\\trequests\")\n\tfor _, r := range rows {\n\t\tfmt.Fprintf(tw, \"%s\\t%d\\n\", r.Path, r.Hits)\n\t}\n\treturn flush(tw, stderr)\n}\n"
    },
    {
      "code": "// summarise counts the file named in args, or standard input.\nfunc summarise(args []string, stdin io.Reader, stderr io.Writer) (tally.Summary, int) {\n\tin := stdin\n\tswitch {\n\tcase len(args) > 1:\n\t\tfmt.Fprintf(stderr, \"hits: one file at most, got %d\\n\", len(args))\n\t\treturn tally.Summary{}, 2\n\tcase len(args) == 1 && args[0] != \"-\":\n\t\tf, err := os.Open(args[0])\n\t\tif err != nil {\n\t\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\t\treturn tally.Summary{}, 1\n\t\t}\n\t\tdefer f.Close()\n\t\tin = f\n\t}",
      "note": "`summarise` é o da aula 1 até o ponto em que tem uma entrada para ler: um arquivo ou a entrada padrão."
    },
    {
      "code": "\tp := &progress{r: in}\n\tstop := p.watch(stderr)\n\tstart := time.Now()\n\ts, err := tally.Count(p)\n\tstop()\n\tdebugf(stderr, \"%d lines, %d bytes in %v\", s.Lines, p.n.Load(), time.Since(start))\n\tif err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn s, 1\n\t}\n\treturn s, 0\n}\n",
      "note": "**A entrada é embrulhada num `progress` antes de o `tally.Count` lê-la**, e o `watch` fica escutando os sinais de progresso enquanto isso. Depois da contagem vem uma chamada a `debugf` com o que quer quem persegue uma execução lenta: linhas, bytes e o tempo que o `Count` levou."
    },
    {
      "code": "// debugf does nothing in an ordinary build. A file built only with\n// -tags debug replaces it with one that prints.\nvar debugf = func(w io.Writer, format string, a ...any) {}\n",
      "note": "**Uma função numa variável, que não faz nada.** A seção 04 acrescenta um arquivo, compilado só quando alguém pede, que põe no lugar dela uma função que imprime."
    },
    {
      "code": "// flush writes out a table, and encode a value as JSON. A write can fail,\n// on a full disk for one, and that is reported.\nfunc flush(tw *tabwriter.Writer, stderr io.Writer) int {\n\tif err := tw.Flush(); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n\nfunc encode(stdout, stderr io.Writer, v any) int {\n\tif err := json.NewEncoder(stdout).Encode(v); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n\n// flagError turns a failed parse into an exit code. The flag package has\n// already printed the message and the usage.\nfunc flagError(err error) int {\n\tif errors.Is(err, flag.ErrHelp) {\n\t\treturn 0\n\t}\n\treturn 2\n}"
    }
  ]
}
```

O `progress.go` usa `progressSignals` sem defini-la. O primeiro rascunho define do jeito óbvio, num
arquivo próprio, `signals.go`:

```go
package main

import (
	"os"
	"syscall"
)

// progressSignals are the signals that make hits report its progress.
var progressSignals = []os.Signal{syscall.SIGUSR1}
```

## Funciona aqui e em nenhum outro lugar

Compilado e testado num log longo o bastante para dar tempo de olhar. O `genlog` escreve vinte
milhões de linhas num pipe, o shell põe o pipeline em segundo plano com `&`, e `$!` é o número do
processo do `hits`, o último comando dele. Dois `kill -USR1` com um segundo de intervalo pedem o
progresso duas vezes:

```
ana@vm:~/tags$ go build -o hits . && go build -o genlog ./tools/genlog
ana@vm:~/tags$ ./genlog -n 20000000 | ./hits count > /dev/null & sleep 1; kill -USR1 $!; sleep 1; kill -USR1 $!; wait $!
hits: 142302665 bytes read
hits: 290270575 bytes read
```

Cada sinal produziu uma linha na saída de erro, e **a segunda contagem é maior que a primeira**
porque o `hits` continuou lendo no meio-tempo. Os números dependem da velocidade da máquina; os seus
vão ser outros. O `wait $!` segura o prompt até o `hits` terminar, e a saída dele foi para
`/dev/null` porque aqui só as linhas de progresso importam.

Agora o mesmo programa para Windows. `GOOS` nomeia o sistema de destino do build, e a aula 16 trata
dele por inteiro; aqui ele é só o jeito de perguntar se este código compila para Windows:

```
ana@vm:~/tags$ GOOS=windows go build -o hits.exe .; echo $?
# example.com/hits
./signals.go:9:43: undefined: syscall.SIGUSR1
1
```

**`syscall.SIGUSR1` não existe no Windows**, então o `signals.go` não compila lá, e com ele o `hits`
também não. Nada no build para Linux avisou disso. Um `if runtime.GOOS` em volta da linha também não
ajudaria, já que o nome precisa existir para a linha compilar, seja qual for o ramo que rodaria.

## Um arquivo por tipo de sistema

A correção são três arquivos pequenos, cada um definindo `progressSignals`, e uma regra em cada um
dizendo quais builds podem vê-lo. Primeiro o rascunho sai:

```
ana@vm:~/tags$ rm signals.go
```

Para o Linux e o resto do Unix, `progress_unix.go`:

```go
//go:build unix && !darwin

package main

import (
	"os"
	"syscall"
)

// On Linux and the other Unix systems, kill -USR1 asks for progress.
var progressSignals = []os.Signal{syscall.SIGUSR1}
```

Para o macOS, onde o hábito é o Ctrl-T, `progress_darwin.go`:

```go
package main

import (
	"os"
	"syscall"
)

// On macOS, Ctrl-T in the terminal sends SIGINFO, and kill -USR1 works too.
var progressSignals = []os.Signal{syscall.SIGINFO, syscall.SIGUSR1}
```

Para todo o resto, inclusive o Windows, `progress_other.go`:

```go
//go:build !unix

package main

import "os"

// Windows and the other systems have no signal for this.
var progressSignals []os.Signal
```

**A primeira linha de dois deles é uma restrição de build**: `//go:build` e depois uma expressão que
precisa ser verdadeira para o arquivo ser compilado. `unix && !darwin` vale no Linux, no FreeBSD e
nos outros sistemas Unix menos o macOS, e `!unix` vale em todos os demais. O arquivo do macOS não tem
essa linha e mesmo assim só é compilado para macOS, porque o nome termina em `_darwin`; a seção 03
trata de nomes. Juntos, os três arquivos cobrem cada sistema exatamente uma vez, então todo build
encontra uma definição de `progressSignals`, e no Windows essa definição é uma lista vazia, que o
`watch` trata como "nenhum sinal".

Três sistemas, três builds:

```
ana@vm:~/tags$ go build -o hits . && GOOS=darwin go build -o hits-mac . && GOOS=windows go build -o hits.exe . && echo built
built
ana@vm:~/tags$ ./genlog -n 20000000 | ./hits count > /dev/null & sleep 1; kill -USR1 $!; wait $!
hits: 75326472 bytes read
ana@vm:~/tags$ file hits-mac hits.exe | cut -d, -f1,2
hits-mac: Mach-O 64-bit x86_64 executable, flags:<|DYLDLINK|PIE>
hits.exe: PE32+ executable (console) x86-64, for MS Windows
```

**Os três compilaram**, e o `file` confirma que o segundo é um executável de macOS e o terceiro um de
Windows. Nenhum desses dois roda nesta máquina, e a aula 16 trata do que dá para conferir sem uma
delas; o build para Linux respondeu ao sinal como antes.

## As regras da linha

`go help buildconstraint` é a referência, e é curta. As regras que importam na prática:

- **A linha vem antes da cláusula package**, só com linhas em branco e outros comentários acima.
  `//go:build` se escreve sem espaço depois das barras, porque é uma diretiva, da mesma família do
  `//go:embed` da aula 24 do `go-concurrency`.
- **Uma linha em branco vem depois dela**, para ela não ser lida como o começo da documentação do
  pacote. O `gofmt` insere essa linha se ela faltar.
- **As tags se combinam com `&&`, `||`, `!` e parênteses**, que significam o mesmo que em Go:
  `//go:build (linux && 386) || (darwin && !cgo)` é o exemplo que o texto de ajuda dá.
- **Uma linha `//go:build` por arquivo.** Uma segunda é erro, não uma condição a mais.

As tags que um build satisfaz por conta própria são estas. Qualquer outra é falsa a menos que a
linha de comando a cite, que é o assunto da seção 04.

| tag | verdadeira quando |
|---|---|
| `linux`, `darwin`, `windows`, `freebsd`, … | é o sistema de destino, `GOOS` |
| `amd64`, `arm64`, `386`, … | é o processador de destino, `GOARCH` |
| `unix` | o destino é um sistema do tipo Unix: Linux, macOS, os BSDs, Solaris e AIX entre eles |
| `cgo` | o cgo está ligado, o que a aula 16 mostra que não acontece num build cruzado |
| `gc`, `gccgo` | é esse o compilador que está compilando |
| `go1.1` … `go1.27` | a versão do Go é pelo menos essa; o Go 1.27.1 satisfaz todas até `go1.27` |
| `amd64.v3`, `arm64.v8.0`, … | o nível de processador escolhido com `GOAMD64`, `GOARM64` e os demais |

Três sistemas também valem por outro: um build para `android` satisfaz `linux` também, um para `ios`
satisfaz `darwin`, e um para `illumos` satisfaz `solaris`. Um arquivo que nunca deve ser compilado,
como um script rodado à mão com `go run gen.go`, leva `//go:build ignore`: nenhum build define
`ignore`, e a palavra diz por que a linha está ali. Uma tag de versão também faz um segundo serviço.
Num módulo cujo `go.mod` diz 1.21 ou mais, um arquivo restrito por `go1.N` é compilado com a
linguagem daquela versão: um arquivo marcado `//go:build go1.21` não pode fazer `range` sobre um
inteiro, que chegou no Go 1.22, mesmo num módulo que diz `go 1.27.1`.

## Dois erros que compilam

Uma restrição escrita errado muitas vezes nem é erro. O deslize mais comum é um espaço,
`// go:build`, que transforma a diretiva num comentário comum. Aqui está ele em `progress_other.go`,
posto com `sed` e tirado de novo:

```
ana@vm:~/tags$ sed -i 's#^//go:build !unix#// go:build !unix#' progress_other.go; go vet .
# example.com/hits
# [example.com/hits]
vet: ./progress_unix.go:11:5: progressSignals redeclared in this block
ana@vm:~/tags$ sed -i 's#^// go:build#//go:build#' progress_other.go; go vet . && echo clean
clean
```

Com o espaço, o arquivo deixou de ser restrito, então o build para Linux o compilou junto com
`progress_unix.go`, e **o erro informado é uma redeclaração, dois arquivos longe do engano**. Aqui o
engano apareceu porque os dois arquivos definem o mesmo nome. Um arquivo que não define nada que
outro também defina teria sido compilado para todo sistema, em silêncio, sem nada a informar.

Uma restrição abaixo da cláusula package é o outro deslize, e esse o compilador recusa:

```
ana@vm:~/tags$ printf 'package main\n\n//go:build windows\n' > late.go; go build -o hits .; rm late.go
# example.com/hits
./late.go:3:3: misplaced compiler directive
```

## A forma antiga, `// +build`

O Go 1.16 e anteriores escreviam restrições como linhas `// +build`, com vírgulas para "e" e espaços
para "ou", e código mais antigo ainda as carrega. **O `gofmt` escreve o equivalente `//go:build`
acima de uma linha antiga**, e o `go fix` remove a linha antiga de um arquivo que tem as duas:

```
ana@vm:~/tags$ mkdir old && printf '// +build linux,amd64\n\npackage old\n' > old/old.go
ana@vm:~/tags$ gofmt -d old/old.go
diff old/old.go.orig old/old.go
--- old/old.go.orig
+++ old/old.go
@@ -1,3 +1,4 @@
+//go:build linux && amd64
 // +build linux,amd64
 
 package old
ana@vm:~/tags$ gofmt -w old/old.go && go fix -diff ./old
--- /home/ana/tags/old/old.go (old)
+++ /home/ana/tags/old/old.go (new)
@@ -1,4 +1,3 @@
 //go:build linux && amd64
-// +build linux,amd64
 
 package old
```

O `go fix` do Go 1.27.1 roda um conjunto de reescritas, e `plusbuild` é a que apaga linhas
`// +build`; `-diff` imprime o que ela mudaria em vez de mudar. O `go vet` confere se as duas formas
concordam num arquivo que tem ambas. Para o código que você escreve hoje, existe uma forma só, e é a
que o `progress_unix.go` usa.
