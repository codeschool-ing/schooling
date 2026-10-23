---
title: Uma árvore de comandos
version: 1
---

A lição 1 terminou com uma lista do que faltava ao `hits` escrito à mão: uma sugestão para um erro
de digitação, ajuda para cada subcomando, completar com a tecla Tab. **O Cobra é uma biblioteca que
entrega tudo isso. O preço é descrever o programa como uma árvore de valores em vez de escrever o
despacho você mesmo.** Cada nó da árvore é um `cobra.Command`, uma struct com nome, um texto de
ajuda, suas flags e uma função para rodar. O Cobra lê as palavras da linha de comando, desce pela
árvore enquanto elas casam, lê as flags do nó a que chegou e chama a função desse nó.

Muita gente o descreve como um framework que se começa com um gerador, e o gerador existe:
`cobra-cli`, um módulo separado (v1.3.0 no proxy de módulos quando isto foi escrito), que escreve um
diretório `cmd/` com um arquivo por comando. Cada um desses arquivos declara seu comando como
variável de pacote e o liga ao pai numa função `init`. **Esta lição usa só a biblioteca e monta a
árvore dentro de funções.** O motivo importa ao teste da seção 04: um comando guardado numa variável
de pacote mantém os valores de flag da última execução, então um teste que o roda duas vezes vê o
`-n` da primeira na segunda. O gerador não foi usado aqui, e você não precisa dele para acompanhar
a lição.

## O mesmo projeto, uma nova frente

O programa mora num módulo novo, `~/cobra-hits`, para que o `~/hits` da lição 1 fique como está e
os dois possam ser comparados. Monte-o do jeito que a lição 1 montou o `~/hits`, com
`go mod init example.com/hits`. Depois copie dois arquivos sem mudança, **o pacote `tally` da lição
1** (`internal/tally/tally.go`) e o gerador de log (`tools/genlog/main.go`), e escreva o mesmo
`access.log` com `go run ./tools/genlog -n 20000 > access.log`. O caminho do módulo é o mesmo da
lição 1, então o import do `tally` não muda um caractere.

O Cobra é o primeiro módulo que este curso baixa. O `go get` cita uma versão, que o comando go
registra no `go.mod`:

```
ana@vm:~/cobra-hits$ go get github.com/spf13/cobra@v1.10.2
go: added github.com/inconshreveable/mousetrap v1.1.0
go: added github.com/spf13/cobra v1.10.2
go: added github.com/spf13/pflag v1.0.9
```

Numa máquina que nunca os buscou, cada linha `added` vem precedida de uma linha `go: downloading`; o
cache de módulos de Ana já tinha os três. Um pedido trouxe **três módulos**: o próprio Cobra, o
`pflag`, o leitor de flags sobre o qual ele é construído, e o `mousetrap`, que o Cobra usa só no
Windows.

## A linha de comando, como árvore

O `main.go` substitui o arquivo inteiro da lição 1. Ele mantém a forma que deixou a lição 1
testável, um `main` que só chama o `run`, e passa todo o resto para três construtores, um por
comando. **Ele continua sendo um arquivo só**, porque três comandos em 163 linhas se leem melhor
juntos do que espalhados por um pacote `cmd/`; esse arranjo se paga quando há uma dúzia de comandos,
cada um com funções auxiliares próprias. Salve-o como `main.go`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"encoding/json\"\n\t\"errors\"\n\t\"fmt\"\n\t\"io\"\n\t\"maps\"\n\t\"os\"\n\t\"slices\"\n\t\"text/tabwriter\"\n\n\t\"github.com/spf13/cobra\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "Os imports da lição 1, sem o `flag` e com uma linha a mais. **O Cobra traz seu próprio leitor de flags, o `pflag`**, então nada aqui importa pacote de flags algum."
    },
    {
      "code": "func main() {\n\tos.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))\n}\n",
      "note": "O `main` é o da lição 1, palavra por palavra: os argumentos e os fluxos do processo vão para o `run`, e o que o `run` devolver é o código de saída."
    },
    {
      "code": "// run builds the command tree, executes it on args and turns the result\n// into an exit code: 0, 1 for a run that failed, 2 for a mistake in the\n// command line.\nfunc run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\troot := newRootCmd()\n\troot.SetArgs(args)\n\troot.SetIn(stdin)\n\troot.SetOut(stdout)\n\troot.SetErr(stderr)\n\tcmd, err := root.ExecuteC()\n\tif err == nil {\n\t\treturn 0\n\t}\n\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\tvar failed runError\n\tif errors.As(err, &failed) {\n\t\treturn 1\n\t}\n\tfmt.Fprintf(stderr, \"Run '%s --help' for usage.\\n\", cmd.CommandPath())\n\treturn 2\n}\n",
      "note": "**O `run` mantém a assinatura da lição 1 e troca o corpo.** Ele monta uma árvore de comandos nova, entrega a ela os argumentos e os três fluxos, e deixa o Cobra achar o subcomando. O `ExecuteC` devolve o comando a que chegou além do erro, e é assim que a dica consegue citar `hits top`. A seção 04 trata das três saídas."
    },
    {
      "code": "// runError marks an error from a command that was called correctly and then\n// failed. Every other error Cobra hands back is a mistake in the command line.\ntype runError struct{ err error }\n\nfunc (e runError) Error() string { return e.err.Error() }\nfunc (e runError) Unwrap() error { return e.err }\n",
      "note": "Um invólucro sem comportamento próprio. A única função dele é deixar o `run` distinguir uma execução que falhou de um comando mal digitado, e a seção 04 explica por que o Cobra não faz isso por você."
    },
    {
      "code": "func newRootCmd() *cobra.Command {\n\tvar asJSON bool\n\troot := &cobra.Command{\n\t\tUse:   \"hits\",\n\t\tShort: \"Summarise a web server's access log\",\n\t\tLong: \"hits reads an access log, one request per line, and counts it.\\n\" +\n\t\t\t\"With no file, or with -, it reads standard input.\",\n\t\tSilenceUsage:  true,\n\t\tSilenceErrors: true,\n\t\tRunE: func(cmd *cobra.Command, args []string) error {\n\t\t\treturn errors.New(\"which command? count or top\")\n\t\t},\n\t}\n\troot.PersistentFlags().BoolVar(&asJSON, \"json\", false, \"print JSON instead of a table\")\n\troot.AddCommand(newCountCmd(&asJSON), newTopCmd(&asJSON))\n\treturn root\n}\n",
      "note": "**O comando raiz é o próprio `hits`.** `Use`, `Short` e `Long` são o texto que a ajuda gerada imprime. Os dois campos `Silence` e o `RunE` da raiz estão ali pelos códigos de saída da seção 04. O `--json` é declarado uma vez, na raiz, como flag persistente que os dois subcomandos herdam; a seção 03 trata dessa diferença."
    },
    {
      "code": "func newCountCmd(asJSON *bool) *cobra.Command {\n\treturn &cobra.Command{\n\t\tUse:               \"count [file]\",\n\t\tShort:             \"Requests per status code\",\n\t\tArgs:              cobra.MaximumNArgs(1),\n\t\tValidArgsFunction: logFiles,\n\t\tRunE: func(cmd *cobra.Command, args []string) error {\n\t\t\ts, err := summarise(cmd, args)\n\t\t\tif err != nil {\n\t\t\t\treturn err\n\t\t\t}\n\t\t\tif *asJSON {\n\t\t\t\treturn encode(cmd.OutOrStdout(), s.ByStatus)\n\t\t\t}\n\t\t\ttw := tabwriter.NewWriter(cmd.OutOrStdout(), 0, 0, 2, ' ', 0)\n\t\t\tfmt.Fprintln(tw, \"status\\trequests\")\n\t\t\tfor _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {\n\t\t\t\tfmt.Fprintf(tw, \"%d\\t%d\\n\", status, s.ByStatus[status])\n\t\t\t}\n\t\t\treturn flush(tw)\n\t\t},\n\t}\n}\n",
      "note": "Um subcomando é um `cobra.Command` acrescentado à raiz. `Args: cobra.MaximumNArgs(1)` substitui a verificação \"um arquivo no máximo\" escrita à mão na lição 1. **O `RunE` devolve um erro em vez de um código de saída**, e a tabela vai para `cmd.OutOrStdout()`, que é o writer que o `run` deu à árvore."
    },
    {
      "code": "func newTopCmd(asJSON *bool) *cobra.Command {\n\tvar n int\n\tcmd := &cobra.Command{\n\t\tUse:               \"top [file]\",\n\t\tShort:             \"The paths with the most requests\",\n\t\tArgs:              cobra.MaximumNArgs(1),\n\t\tValidArgsFunction: logFiles,\n\t\tRunE: func(cmd *cobra.Command, args []string) error {\n\t\t\ts, err := summarise(cmd, args)\n\t\t\tif err != nil {\n\t\t\t\treturn err\n\t\t\t}\n\t\t\trows := tally.Top(s, n)\n\t\t\tif *asJSON {\n\t\t\t\treturn encode(cmd.OutOrStdout(), rows)\n\t\t\t}\n\t\t\ttw := tabwriter.NewWriter(cmd.OutOrStdout(), 0, 0, 2, ' ', 0)\n\t\t\tfmt.Fprintln(tw, \"path\\trequests\")\n\t\t\tfor _, r := range rows {\n\t\t\t\tfmt.Fprintf(tw, \"%s\\t%d\\n\", r.Path, r.Hits)\n\t\t\t}\n\t\t\treturn flush(tw)\n\t\t},\n\t}\n\tcmd.Flags().IntVarP(&n, \"number\", \"n\", 3, \"how many paths to show\")\n\treturn cmd\n}\n",
      "note": "O `top` acrescenta uma flag local, `-n`, agora também escrita `--number`. A variável que ela preenche é declarada dentro do construtor, então **toda árvore que o `run` monta começa no padrão 3**."
    },
    {
      "code": "// logFiles is what Tab offers for the file argument: files ending in .log,\n// and nothing once a file has been named.\nfunc logFiles(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {\n\tif len(args) > 0 {\n\t\treturn nil, cobra.ShellCompDirectiveNoFileComp\n\t}\n\treturn []string{\"log\"}, cobra.ShellCompDirectiveFilterFileExt\n}\n",
      "note": "Nada que uma pessoa digite usa isto: aqui se responde ao shell quando alguém aperta Tab. A seção 05 mostra a pergunta e a resposta."
    },
    {
      "code": "// summarise counts the file named in args, or standard input.\nfunc summarise(cmd *cobra.Command, args []string) (tally.Summary, error) {\n\tin := cmd.InOrStdin()\n\tif len(args) == 1 && args[0] != \"-\" {\n\t\tf, err := os.Open(args[0])\n\t\tif err != nil {\n\t\t\treturn tally.Summary{}, runError{err}\n\t\t}\n\t\tdefer f.Close()\n\t\tin = f\n\t}\n\ts, err := tally.Count(in)\n\tif err != nil {\n\t\treturn s, runError{err}\n\t}\n\treturn s, nil\n}\n",
      "note": "O `summarise` da lição 1 sem a contagem de argumentos, que o Cobra agora verifica antes de chamar o `RunE`. **Um arquivo que não abre e uma linha que não se lê voltam embrulhados em `runError`**: a linha de comando estava certa e a execução falhou."
    },
    {
      "code": "// flush writes out a table, and encode a value as JSON. A write that fails\n// is a failed run.\nfunc flush(tw *tabwriter.Writer) error {\n\tif err := tw.Flush(); err != nil {\n\t\treturn runError{err}\n\t}\n\treturn nil\n}\n\nfunc encode(w io.Writer, v any) error {\n\tif err := json.NewEncoder(w).Encode(v); err != nil {\n\t\treturn runError{err}\n\t}\n\treturn nil\n}",
      "note": "Os mesmos dois escritores da lição 1, devolvendo erros em vez de imprimi-los. O `run` imprime todos os erros num lugar só."
    }
  ]
}
```

O `go get` registrou o Cobra como indireto, porque nenhum código o importava ainda. O `go mod tidy`
lê os imports e acerta isso, e então a ferramenta compila:

```
ana@vm:~/cobra-hits$ go mod tidy
ana@vm:~/cobra-hits$ cat go.mod
module example.com/hits

go 1.27.1

require github.com/spf13/cobra v1.10.2

require (
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/spf13/pflag v1.0.9 // indirect
)
ana@vm:~/cobra-hits$ find . -name "*.go" | sort
./internal/tally/tally.go
./main.go
./tools/genlog/main.go
ana@vm:~/cobra-hits$ go build -o hits . && stat -c "%s bytes  %n" hits
5108043 bytes  hits
ana@vm:~/cobra-hits$ ./hits count access.log
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
ana@vm:~/cobra-hits$ ./hits top -n 5 access.log
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
/api/users      2512
/api/orders/42  2503
```

**As duas tabelas são as da lição 1, dígito por dígito**, que é a verificação que importa depois de
trocar uma linha de comando: a contagem não mudou, então as respostas também não. O `go.mod` agora
diz `require` para o Cobra e `// indirect` para os dois módulos que ele trouxe, já que nada no `hits`
os importa pelo nome.

Os fluxos também sobreviveram à mudança. `SetIn`, `SetOut` e `SetErr` dão à árvore os leitores e
escritores que o `run` recebeu, e dentro de um comando `cmd.InOrStdin()` e `cmd.OutOrStdout()` os
devolvem. Um comando que escrevesse direto em `os.Stdout` funcionaria no terminal e não imprimiria
nada no buffer de um teste, que é a mesma armadilha que a lição 1 evitou passando writers ao `run`.

## Quanto custou

Uma biblioteca é código que você não escreveu e mesmo assim entrega. Três perguntas a medem: de
quantos módulos o seu build passa a depender, quantos deles acabam no binário e quanto o binário
cresce.

```
ana@vm:~/cobra-hits$ go list -m all
example.com/hits
github.com/cpuguy83/go-md2man/v2 v2.0.6
github.com/inconshreveable/mousetrap v1.1.0
github.com/russross/blackfriday/v2 v2.1.0
github.com/spf13/cobra v1.10.2
github.com/spf13/pflag v1.0.9
go.yaml.in/yaml/v3 v3.0.4
gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405
ana@vm:~/cobra-hits$ go version -m hits | grep dep
	dep	github.com/spf13/cobra	v1.10.2	h1:DMTTonx5m65Ic0GOoRY2c16WCbHxOOw6xxezuLaBpcU=
	dep	github.com/spf13/pflag	v1.0.9	h1:9exaQaMOCwffKiiiYk6/BndUBv+iRViNW+4lEMi0PvY=
ana@vm:~/cobra-hits$ go list -deps . | grep template
text/template/parse
text/template
```

**O `go list -m all` imprime o grafo de módulos, e ele é maior do que o que se compila.** O `hits`
da lição 1 tinha uma linha aqui, o próprio módulo; este tem oito. Três são os módulos que o `go get`
acrescentou. Os outros quatro chegam pelo `go.mod` do Cobra e pelos arquivos a que ele leva. O
`go-md2man`, e o `blackfriday` de que ele precisa, servem ao gerador de páginas de manual do pacote
`doc` do Cobra; o `yaml` serve à saída YAML do mesmo pacote, e o `check.v1` é com o que o `yaml`
testa a si mesmo. O comando go precisa das versões deles para resolver o grafo, embora o `hits` não
importe nenhum. O `go version -m` lê a lista que o linker gravou no binário, e **só dois módulos
foram compilados**: Cobra e `pflag`. A biblioteca padrão também cresceu: o Cobra monta a ajuda com o
`text/template`, um pacote que o programa da lição 1 não usava.

| | lição 1, biblioteca padrão | esta lição, Cobra |
|---|---|---|
| módulos no grafo (`go list -m all`) | 1 | 8 |
| módulos compilados (`go version -m`) | 0 além do `hits` | 2 |
| binário | 4.031.903 bytes | 5.108.043 bytes |
| `main.go` | 144 linhas | 163 linhas |

O binário ficou **1.076.140 bytes maior**, cerca de 27%, para um programa cujo código próprio quase
não mudou; a lição 17 trata de diminuir binários com flags do compilador e do linker. A última linha
é a surpresa: o `main.go` não encolheu. O que foi para a biblioteca não são linhas do `hits`, e sim
recursos que o `hits` nunca teve:

```
ana@vm:~/cobra-hits$ wc -l main.go
163 main.go
ana@vm:~/cobra-hits$ cd $(go env GOMODCACHE)/github.com/spf13 && cat $(ls cobra@v1.10.2/*.go pflag@v1.0.9/*.go | grep -v _test) | wc -l
12370
```

**12.370 linhas de Cobra e `pflag`**, sem contar os testes, agora estão por trás daquelas 163. O
texto de uso escrito à mão da lição 1, o `switch` sobre a primeira palavra e o `flagError` sumiram;
no lugar deles estão três construtores e o código que as seções 04 e 05 explicam. Se essa troca vale
um megabyte é a pergunta que a lição 3 faz de novo, ao urfave/cli.
