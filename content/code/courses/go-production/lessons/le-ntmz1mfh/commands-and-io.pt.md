---
title: Comandos, para o trabalho que leva tempo
version: 1
---

O lugar tentador para ler o log é o próprio `Init` ou o `Update`: abrir o arquivo, contar, guardar
as linhas. Compila e até funciona com um arquivo pequeno, mas **o laço só chama o `View` depois que
o `Update` retorna**, então enquanto um arquivo grande está sendo lido o terminal não mostra nada e
toda tecla apertada espera numa fila. O `Update` precisa retornar rápido, sempre. Trabalho que leva
o tempo que levar vai num comando.

**Um `tea.Cmd` é uma função, `func() tea.Msg`. O programa a roda numa goroutine própria, e o que ela
devolver é entregue ao `Update` como a próxima mensagem.** O `go doc` o descreve como "an IO
operation that returns a message when it's complete", uma operação de I/O que devolve uma mensagem
quando termina. No código do Bubble Tea, cada comando que o `Update` devolve é iniciado com `go
func()` e o resultado é mandado de volta ao laço, então a tela continua atendendo teclas enquanto o
comando roda.

O `internal/tui/load.go` guarda o `Init` e a contagem:

```schooling-example
{
  "language": "go",
  "file": "internal/tui/load.go",
  "parts": [
    {
      "code": "package tui\n\nimport (\n\t\"bufio\"\n\t\"fmt\"\n\t\"io\"\n\n\ttea \"charm.land/bubbletea/v2\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "O terceiro arquivo do pacote, e o que toca o mundo lá fora: ele importa o `tally` da lição 1 para usar `Parse` e `Top`."
    },
    {
      "code": "// loaded is the message the count sends when it has finished.\ntype loaded struct {\n\trows []row\n\terr  error\n}\n",
      "note": "**Um tipo de mensagem do próprio programa**, não exportado, porque nada fora do pacote o envia. Ele leva as linhas ou o erro, e o `Update` copia os dois para o modelo."
    },
    {
      "code": "// Init starts the count. The program runs the command it returns in a\n// goroutine of its own, and hands its result to Update.\nfunc (m Model) Init() tea.Cmd {\n\treturn count(m.in)\n}\n",
      "note": "**O `Init` não lê o arquivo; ele devolve a função que vai ler.** O programa chama o `Init` uma vez, antes da primeira tela, e roda o comando numa goroutine própria."
    },
    {
      "code": "// count reads the whole log and tallies each path's statuses.\nfunc count(r io.Reader) tea.Cmd {\n\treturn func() tea.Msg {",
      "note": "O `count` monta o comando: uma closure sobre o leitor que devolve uma `tea.Msg` quando termina. Nada nele toca no modelo ou na tela."
    },
    {
      "code": "\t\tbyPath := map[string]map[int]int{}\n\t\thits := map[string]int{}\n\t\tsc := bufio.NewScanner(r)\n\t\tfor n := 1; sc.Scan(); n++ {\n\t\t\te, err := tally.Parse(sc.Text())\n\t\t\tif err != nil {\n\t\t\t\treturn loaded{err: fmt.Errorf(\"line %d: %w\", n, err)}\n\t\t\t}\n\t\t\tif byPath[e.Path] == nil {\n\t\t\t\tbyPath[e.Path] = map[int]int{}\n\t\t\t}\n\t\t\tbyPath[e.Path][e.Status]++\n\t\t\thits[e.Path]++\n\t\t}\n\t\tif err := sc.Err(); err != nil {\n\t\t\treturn loaded{err: err}\n\t\t}",
      "note": "O mesmo laço de leitura do `tally.Count` da lição 1, guardando um mapa de status por caminho. Uma linha que não pode ser lida encerra a contagem, e a mensagem leva o erro com o número da linha."
    },
    {
      "code": "\t\trows := make([]row, 0, len(hits))\n\t\tfor _, pc := range tally.Top(tally.Summary{ByPath: hits}, len(hits)) {\n\t\t\trows = append(rows, row{pc.Path, pc.Hits, byPath[pc.Path]})\n\t\t}\n\t\treturn loaded{rows: rows}\n\t}\n}",
      "note": "O `tally.Top` ordena os caminhos como o `hits top` faz, mais requisições primeiro e empates em ordem alfabética, então os dois comandos listam os caminhos na mesma ordem. **`rows` é criado vazio em vez de ficar `nil`**, para um log vazio desenhar uma lista vazia em vez de `counting` para sempre."
    }
  ]
}
```

O `tea.Quit`, que o `Update` devolve no `q`, também é um comando. Ele é uma função exatamente desse
tipo, que devolve `tea.QuitMsg`, e quando essa mensagem dá a volta no laço o programa para e o `Run`
retorna. **Um comando é o único jeito de um modelo pedir qualquer coisa**: ler, esperar, sair. Ele
nunca faz a coisa por conta própria.

## Ligando tudo ao `hits`

O subcomando é um arquivo novo no pacote `main`, `browse.go`:

```schooling-example
{
  "language": "go",
  "file": "browse.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"os\"\n\n\ttea \"charm.land/bubbletea/v2\"\n\t\"golang.org/x/term\"\n\n\t\"example.com/hits/internal/tui\"\n)\n",
      "note": "Um arquivo novo ao lado do `main.go`, no pacote `main`. Ele importa o Bubble Tea, o `golang.org/x/term` e o pacote `tui`."
    },
    {
      "code": "// browse runs the interactive screen. It needs a terminal on standard\n// output; a script, a pipe and a screen reader are sent to hits top.\nfunc browse(args []string, stdout, stderr io.Writer) int {\n\tif f, ok := stdout.(*os.File); !ok || !term.IsTerminal(int(f.Fd())) {\n\t\tfmt.Fprintln(stderr, \"hits: browse draws on a terminal, and standard output is not one; use hits top\")\n\t\treturn 2\n\t}",
      "note": "**A primeira coisa que o `browse` confere é se a saída padrão é um terminal**, e a seção 05 diz por que a verificação é `term.IsTerminal` e não algo mais simples. Um pipe, um arquivo ou o buffer de um teste é recusado com status 2 e mandado para o `hits top`."
    },
    {
      "code": "\tif len(args) != 1 {\n\t\tfmt.Fprintf(stderr, \"hits: browse wants one file, got %d\\n\", len(args))\n\t\treturn 2\n\t}\n\tf, err := os.Open(args[0])\n\tif err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\tdefer f.Close()\n",
      "note": "Um arquivo só, aberto antes de a tela aparecer, então um arquivo inexistente vira uma mensagem comum num terminal comum. A entrada padrão não é oferecida: num terminal ela é o teclado, e é lá que o Bubble Tea lê as teclas."
    },
    {
      "code": "\tvar opts []tea.ProgramOption\n\tif path := os.Getenv(\"HITS_DEBUG\"); path != \"\" {\n\t\tw, err := os.Create(path)\n\t\tif err != nil {\n\t\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\t\treturn 1\n\t\t}\n\t\tdefer w.Close()\n\t\topts = append(opts, tea.WithFilter(func(_ tea.Model, msg tea.Msg) tea.Msg {\n\t\t\tline := fmt.Sprintf(\"%T %v\", msg, msg)\n\t\t\tfmt.Fprintln(w, line[:min(len(line), 72)])\n\t\t\treturn msg\n\t\t}))\n\t}\n",
      "note": "Um interruptor para ver o programa trabalhando. Com `HITS_DEBUG` definido, o `tea.WithFilter` vê cada mensagem antes do `Update` e grava o tipo e o valor dela, cortados em 72 caracteres, nesse arquivo. O filtro devolve a mensagem sem mudança, então o programa se comporta igual com ele ou sem ele."
    },
    {
      "code": "\tfinal, err := tea.NewProgram(tui.New(args[0], f), opts...).Run()\n\tif err == nil {\n\t\terr = final.(tui.Model).Err()\n\t}\n\tif err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}",
      "note": "**O `Run` toma o terminal, roda o laço e devolve o último modelo quando o laço termina.** Um erro do próprio Bubble Tea, ou um que o modelo guardou, é impresso agora, depois de a tela alternativa ter sumido e as linhas do shell terem voltado."
    }
  ]
}
```

O `main.go` ganha um caso e duas linhas de uso. Aqui está ele inteiro, porque um arquivo que a lição
muda é impresso inteiro; só as partes com nota diferem da lição 1:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"encoding/json\"\n\t\"errors\"\n\t\"flag\"\n\t\"fmt\"\n\t\"io\"\n\t\"maps\"\n\t\"os\"\n\t\"slices\"\n\t\"text/tabwriter\"\n\n\t\"example.com/hits/internal/tally\"\n)\n\nconst usage = `usage: hits <command> [flags] [file]\n\ncommands:\n  count   requests per status code\n  top     the paths with the most requests\n  browse  the same paths on an interactive screen; needs a terminal\n\nWith no file, or with -, count and top read standard input.\n`\n",
      "note": "**Duas linhas diferem da lição 1 aqui**: o uso cita o `browse`, e a última linha diz quais comandos leem a entrada padrão, já que o `browse` não lê."
    },
    {
      "code": "func main() {\n\tos.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))\n}\n\nfunc run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tif len(args) == 0 {\n\t\tfmt.Fprint(stderr, usage)\n\t\treturn 2\n\t}\n\tswitch args[0] {\n\tcase \"count\":\n\t\treturn count(args[1:], stdin, stdout, stderr)\n\tcase \"top\":\n\t\treturn top(args[1:], stdin, stdout, stderr)\n\tcase \"browse\":\n\t\treturn browse(args[1:], stdout, stderr)\n\tcase \"help\", \"-h\", \"-help\", \"--help\":\n\t\tfmt.Fprint(stdout, usage)\n\t\treturn 0\n\t}\n\tfmt.Fprintf(stderr, \"hits: unknown command %q\\n\\n%s\", args[0], usage)\n\treturn 2\n}\n",
      "note": "Um caso novo. O `browse` não recebe a entrada padrão, pelo motivo dado nas notas do `browse.go`."
    },
    {
      "code": "func count(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"count\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}\n\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, s.ByStatus)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"status\\trequests\")\n\tfor _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {\n\t\tfmt.Fprintf(tw, \"%d\\t%d\\n\", status, s.ByStatus[status])\n\t}\n\treturn flush(tw, stderr)\n}\n\nfunc top(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"top\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tn := fs.Int(\"n\", 3, \"how many paths to show\")\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}\n\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\trows := tally.Top(s, *n)\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, rows)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"path\\trequests\")\n\tfor _, r := range rows {\n\t\tfmt.Fprintf(tw, \"%s\\t%d\\n\", r.Path, r.Hits)\n\t}\n\treturn flush(tw, stderr)\n}\n\n// summarise counts the file named in args, or standard input.\nfunc summarise(args []string, stdin io.Reader, stderr io.Writer) (tally.Summary, int) {\n\tin := stdin\n\tswitch {\n\tcase len(args) > 1:\n\t\tfmt.Fprintf(stderr, \"hits: one file at most, got %d\\n\", len(args))\n\t\treturn tally.Summary{}, 2\n\tcase len(args) == 1 && args[0] != \"-\":\n\t\tf, err := os.Open(args[0])\n\t\tif err != nil {\n\t\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\t\treturn tally.Summary{}, 1\n\t\t}\n\t\tdefer f.Close()\n\t\tin = f\n\t}\n\ts, err := tally.Count(in)\n\tif err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn s, 1\n\t}\n\treturn s, 0\n}\n\n// flush writes out a table, and encode a value as JSON. A write can fail,\n// on a full disk for one, and that is reported.\nfunc flush(tw *tabwriter.Writer, stderr io.Writer) int {\n\tif err := tw.Flush(); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n\nfunc encode(stdout, stderr io.Writer, v any) int {\n\tif err := json.NewEncoder(stdout).Encode(v); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n\n// flagError turns a failed parse into an exit code. The flag package has\n// already printed the message and the usage.\nfunc flagError(err error) int {\n\tif errors.Is(err, flag.ErrHelp) {\n\t\treturn 0\n\t}\n\treturn 2\n}",
      "note": "Daqui até o fim, o arquivo é o da lição 1, seção 03, sem mudança."
    }
  ]
}
```

Com os cinco arquivos no lugar, o módulo se arruma, compila e lista o subcomando novo:

```
ana@vm:~/tea-hits$ go mod tidy
ana@vm:~/tea-hits$ find . -name "*.go" | sort
./browse.go
./internal/tally/tally.go
./internal/tui/load.go
./internal/tui/model.go
./internal/tui/update.go
./main.go
./main_test.go
./tools/genlog/main.go
ana@vm:~/tea-hits$ go build -o hits . && stat -c "%s bytes  %n" hits
6773596 bytes  hits
ana@vm:~/tea-hits$ go list -deps -f "{{if not .Standard}}{{.ImportPath}}{{end}}" . | grep -v ^example.com | grep -c .
19
ana@vm:~/tea-hits$ ./hits
usage: hits <command> [flags] [file]

commands:
  count   requests per status code
  top     the paths with the most requests
  browse  the same paths on an interactive screen; needs a terminal

With no file, or with -, count and top read standard input.
```

**O binário foi dos 4.031.903 bytes da lição 1 para 6.773.596**, e o `go list -deps` conta 19
pacotes de fora da biblioteca padrão compilados nele, sem contar os do próprio `hits`: o Bubble Tea
e o `ultraviolet`, a camada de terminal por baixo dele, bibliotecas que interpretam sequências de
escape e medem quantas colunas um caractere ocupa, e o `golang.org/x/term`. O Cobra da lição 2
custou 1.076.140 bytes por ajuda e autocompletar; uma tela custa umas duas vezes e meia isso.

## Vendo as mensagens chegarem

O `HITS_DEBUG` anota cada mensagem antes de o `Update` vê-la. Este é o arquivo da execução que
desenhou a primeira tela da seção 02, em que `j` foi apertado duas vezes e depois `q`:

```
ana@vm:~/tea-hits$ cat msgs.log
tea.ColorProfileMsg ANSI256
tea.WindowSizeMsg {72 14}
tea.EnvMsg [HITS_DEBUG=msgs.log PWD=/home/ana/tea-hits TZ=America/Sao_Pa
tui.loaded {[{/login 2576 map[200:967 201:159 204:156 301:147 304:163 40
tea.ModeReportMsg {2026 0}
tea.ModeReportMsg {2027 0}
tea.KeyPressMsg j
tea.KeyPressMsg j
tea.KeyPressMsg q
tea.QuitMsg {}
```

Leia de cima para baixo. **`tui.loaded` chega em quarto lugar, depois das primeiras mensagens do
próprio Bubble Tea**: a contagem rodou na goroutine dela enquanto o programa se preparava, e o
resultado entrou na fila como qualquer outra coisa. A ordem não é fixa. Em outra execução da mesma
captura, as duas primeiras linhas vieram trocadas, porque elas também vêm de goroutines diferentes.
As 20.000 linhas foram contadas rápido demais para se ver, mas com um arquivo mil vezes maior a tela
mostraria `counting access.log ...` e atenderia o `q` o tempo todo.

As outras mensagens são o Bubble Tea contando ao modelo sobre o terminal. A `ColorProfileMsg` diz
quantas cores ele mostra, e a `EnvMsg` traz o ambiente. As duas linhas `ModeReportMsg` são as
respostas do terminal a duas perguntas que o Bubble Tea fez sobre os modos `2026` e `2027`: se ele
consegue desenhar um quadro inteiro de uma vez, e se mede os caracteres do jeito moderno do Unicode.
O `0` em cada resposta quer dizer "não reconhecido". **Elas chegam quer o modelo queira, quer não**,
e o type switch do `Update` as deixa cair em `return m, nil`. Em outro terminal essas linhas mudam,
porque aquele terminal responde de outro jeito, e a seção 05 volta a esse ponto.

## O erro vem depois da tela

Um programa de tela cheia é dono do terminal até sair, e na saída a tela alternativa é desligada, o
que devolve as linhas do shell e apaga tudo o que o programa desenhou. Por isso **um erro precisa
ser impresso depois que o `Run` retorna**, ou some junto com a tela. É por isso que o `count` põe o
erro numa mensagem, o `Update` o guarda no modelo e sai, e o `browse` pede `Err` ao modelo final.
Três enganos, digitados num terminal de verdade, com um arquivo de uma linha ruim criado antes:

```
ana@vm:~/tea-hits$ printf 'oops\n' > bad.log
```

```
ana@vm:~/tea-hits$ ./hits browse; echo $?
hits: browse wants one file, got 0
2
ana@vm:~/tea-hits$ ./hits browse nope.log; echo $?
hits: open nope.log: no such file or directory
1
ana@vm:~/tea-hits$ ./hits browse bad.log; echo $?
hits: line 1: want 5 fields, got 1
^[[?2026;0$y^[[?2027;0$y1
ana@vm:~/tea-hits$ 2026;0$y2027;0$y
```

Os dois primeiros nem abrem a tela: o arquivo é conferido antes do `Run`, e as mensagens são linhas
comuns num terminal comum, com os códigos da lição 1, 2 para uma chamada errada e 1 para uma
execução que falhou. O terceiro abriu, por um instante: a contagem achou a linha 1 ilegível, o
`Update` devolveu `tea.Quit`, a tela alternativa sumiu e só então o `browse` imprimiu a linha.

**As duas últimas linhas são algo que ninguém digitou.** `^[[?2026;0$y` e `^[[?2027;0$y` são as
respostas do terminal às mesmas duas perguntas do `msgs.log`. Esta execução saiu antes de elas
voltarem, então elas chegaram ao shell: o bash as ecoou como se tivessem sido digitadas, na frente
do `1` do `echo`, e o que ele não engoliu ficou esperando no prompt seguinte. Nada quebrou, e um
Ctrl+C limpa a linha, mas um programa que sai quase assim que começa e deixa resíduo na tela é uma
boa prévia do argumento da seção 05.
