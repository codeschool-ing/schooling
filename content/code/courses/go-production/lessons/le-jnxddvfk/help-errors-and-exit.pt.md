---
title: Ajuda, erros e o código de saída
version: 1
---

Uma biblioteca que escreve a sua ajuda e lê as suas flags também decide o que acontece quando a
leitura falha, e **os padrões dela não são o contrato da lição 1**. A seção 05 da lição 1 fixou três
promessas: resultados na saída padrão, reclamações na saída de erro, e um status de saída 0, 1 ou 2
com que um script possa agir. O `main.go` da seção 02 usa o formato que a própria documentação da
urfave/cli mostra, e quebra as três na primeira flag digitada errado. Esta seção mostra onde, depois
reescreve o `main.go` com três ganchos que a biblioteca oferece e uma função `run` como a da lição
1, e o testa.

## O que os padrões fazem

Um valor que não é número, primeiro com os dois fluxos na tela e depois com a saída de erro jogada
fora:

```
ana@vm:~/cli-hits$ ./hits top -n five access.log; echo $?
Incorrect Usage: invalid value "five" for flag -n: strconv.ParseInt: parsing "five": invalid syntax

NAME:
   hits top - the paths with the most requests

USAGE:
   hits top [file]

OPTIONS:
   -n int, --limit int  how many paths to show (default: 3) [$HITS_TOP]
   --json               print JSON instead of a table
   --help, -h           show help
hits: invalid value "five" for flag -n: strconv.ParseInt: parsing "five": invalid syntax
1
ana@vm:~/cli-hits$ ./hits top -n five access.log 2>/dev/null | head -3
NAME:
   hits top - the paths with the most requests
```

Três coisas estão erradas de uma vez. **A reclamação sai duas vezes**, uma pela biblioteca, como
`Incorrect Usage`, e outra pelo `main`, que imprimiu o erro devolvido pelo `Run`. O status de saída
é 1, que na tabela da lição 1 quer dizer "chamado do jeito certo, e a execução falhou", para uma
chamada claramente errada. E o segundo comando mostra para onde foi a ajuda: **com a saída de erro
descartada, a listagem chegou assim mesmo, então foi escrita na saída padrão**. Num pipeline, o
programa seguinte leria `NAME:` e `hits top - the paths with the most requests` como dados.

Depois, um erro de digitação no comando, nenhum comando e dois arquivos:

```
ana@vm:~/cli-hits$ ./hits cont access.log; echo $?
No help topic for 'cont'
3
ana@vm:~/cli-hits$ ./hits >/dev/null; echo $?
0
ana@vm:~/cli-hits$ ./hits top a.log b.log; echo $?
hits: one file at most, got 2
2
```

O `cont` terminou com **status 3**, um código que a lição 1 nunca usou, e uma mensagem sobre tópicos
de ajuda. Sem comando, a biblioteca imprimiu a ajuda da raiz e chamou isso de sucesso. Os dois
arquivos saíram certos, 2 e uma linha, e vale saber o motivo. Aquele erro foi criado pelo
`cli.Exit` no `summarise`, e **por padrão a biblioteca trata um `ExitCoder` ela mesma, imprimindo a
mensagem e chamando `os.Exit` de dentro do `Run`**. O `os.Exit(1)` do `main` nunca rodou. O erro de
digitação foi pelo mesmo caminho: a biblioteca criou um `cli.Exit(…, 3)` próprio e encerrou.

Esse último comportamento é o que importa além da aparência. Uma função que pode encerrar o processo
lá de dentro não pode ser chamada por um teste, porque o binário de teste é o processo.

## Três ganchos e um `run`

Cada padrão tem um campo que o substitui. Reescreva o `main.go` em `~/cli-hits`; o `report.go`
continua como está:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"context\"\n\t\"errors\"\n\t\"fmt\"\n\t\"io\"\n\t\"os\"\n\n\t\"github.com/urfave/cli/v3\"\n)\n",
      "note": "Os mesmos imports da versão da seção 02, mais `errors` e `io` para o ponto de entrada testável."
    },
    {
      "code": "func main() {\n\tos.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))\n}\n",
      "note": "**O `main` volta a ter a linha única da lição 1.** Os argumentos e os fluxos do processo vão para o `run`, e a resposta dele é o status de saída."
    },
    {
      "code": "// run builds the command, runs it on args and turns what comes back into\n// lesson 1's exit codes: 0 it worked, 1 the run failed, 2 the call was wrong.\nfunc run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\terr := newApp(stdin, stdout, stderr).Run(context.Background(), append([]string{\"hits\"}, args...))\n\tif err == nil {\n\t\treturn 0\n\t}\n\tvar exit cli.ExitCoder\n\tif errors.As(err, &exit) {\n\t\tif msg := err.Error(); msg != \"\" {\n\t\t\tfmt.Fprintln(stderr, msg)\n\t\t}\n\t\treturn exit.ExitCode()\n\t}\n\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\treturn 1\n}\n",
      "note": "O `run` recoloca o nome do programa na frente, porque o `Run` espera o `os.Args` inteiro. **Todo erro que leva um código foi criado pelo `cli.Exit`**, aqui ou no `report.go`, então ele é impresso e o código devolvido. Qualquer outro é uma falha que ninguém classificou, e recebe 1."
    },
    {
      "code": "func newApp(stdin io.Reader, stdout, stderr io.Writer) *cli.Command {\n\treturn &cli.Command{\n\t\tName:                  \"hits\",\n\t\tUsage:                 \"summarise a web server's access log\",\n\t\tReader:                stdin,\n\t\tWriter:                stdout,\n\t\tErrWriter:             stderr,\n\t\tExitErrHandler:        func(context.Context, *cli.Command, error) {},\n\t\tOnUsageError:          usageError,\n\t\tEnableShellCompletion: true,\n\t\tAction:                noCommand,",
      "note": "**`Reader`, `Writer` e `ErrWriter` são os três fluxos**, e os subcomandos os herdam, e é por isso que o `report.go` pôde escrever em `cmd.Writer` desde o começo. O `ExitErrHandler` é a linha que mais importa: uma função vazia faz a biblioteca nunca chamar `os.Exit` ela mesma, e a decisão volta para o `run`."
    },
    {
      "code": "\t\tCommands: []*cli.Command{\n\t\t\t{\n\t\t\t\tName:         \"count\",\n\t\t\t\tUsage:        \"requests per status code\",\n\t\t\t\tArgsUsage:    \"[file]\",\n\t\t\t\tFlags:        []cli.Flag{jsonFlag()},\n\t\t\t\tOnUsageError: usageError,\n\t\t\t\tAction:       count,\n\t\t\t},\n\t\t\t{\n\t\t\t\tName:      \"top\",\n\t\t\t\tUsage:     \"the paths with the most requests\",\n\t\t\t\tArgsUsage: \"[file]\",\n\t\t\t\tFlags: []cli.Flag{\n\t\t\t\t\t&cli.IntFlag{\n\t\t\t\t\t\tName:      \"n\",\n\t\t\t\t\t\tAliases:   []string{\"limit\"},\n\t\t\t\t\t\tValue:     3,\n\t\t\t\t\t\tUsage:     \"how many paths to show\",\n\t\t\t\t\t\tSources:   cli.EnvVars(\"HITS_TOP\"),\n\t\t\t\t\t\tValidator: atLeastOne,\n\t\t\t\t\t},\n\t\t\t\t\tjsonFlag(),\n\t\t\t\t},\n\t\t\t\tOnUsageError: usageError,\n\t\t\t\tAction:       top,\n\t\t\t},\n\t\t},\n\t}\n}\n",
      "note": "Os dois comandos são os da seção 02, cada um com `OnUsageError` acrescentado. **O gancho não é herdado**: um comando sem ele cai na resposta da biblioteca, com ajuda na saída padrão e tudo."
    },
    {
      "code": "// usageError replaces the library's answer to a bad flag, which prints the\n// whole help to standard output, with one line on standard error and 2.\nfunc usageError(ctx context.Context, cmd *cli.Command, err error, _ bool) error {\n\treturn cli.Exit(fmt.Sprintf(\"%s: %v (see '%s --help')\", cmd.FullName(), err, cmd.FullName()), 2)\n}\n",
      "note": "Chamado com o comando cujas flags falharam, então o `cmd.FullName()` diz `hits top` e não `hits`. Embrulhar a mensagem em `cli.Exit(…, 2)` é o que diz ao `run` que código usar."
    },
    {
      "code": "// noCommand runs when no subcommand matched: either none was given, or the\n// first word is not one of them.\nfunc noCommand(ctx context.Context, cmd *cli.Command) error {\n\tif !cmd.Args().Present() {\n\t\treturn cli.Exit(\"hits: no command given (see 'hits --help')\", 2)\n\t}\n\tname := cmd.Args().First()\n\treturn cli.Exit(fmt.Sprintf(\"hits: unknown command %q, did you mean %q?\", name, cli.SuggestCommand(cmd.Commands, name)), 2)\n}\n",
      "note": "**A `Action` da raiz é o recurso para uma primeira palavra que não cita comando nenhum.** Sem ela, a biblioteca responderia `No help topic` com status 3. O `cli.SuggestCommand` é a busca do nome mais próximo da própria biblioteca, exportada."
    },
    {
      "code": "func jsonFlag() cli.Flag {\n\treturn &cli.BoolFlag{Name: \"json\", Usage: \"print JSON instead of a table\"}\n}\n\nfunc atLeastOne(n int) error {\n\tif n < 1 {\n\t\treturn fmt.Errorf(\"must be at least 1, got %d\", n)\n\t}\n\treturn nil\n}",
      "note": "Iguais aos da seção 02."
    }
  ]
}
```

**O `ExitErrHandler` com uma função que não faz nada é a mudança em que todo o resto se apoia.** A
biblioteca ainda monta cada `cli.Exit`, mas agora o devolve pelo `Run` em vez de agir sobre ele, e
o `run` imprime a mensagem e devolve o código. Por onde cada tipo de falha entra está desenhado
abaixo; as três caixas à direita são os três lugares em que este programa decide um código de
saída.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Para onde vai cada falha do hits na segunda versão. Dentro de cmd.Run, três etapas rodam em ordem: ler as flags, achar o comando, rodar a Action. Uma flag ou um valor ruim é pego pelo OnUsageError, que devolve cli.Exit com 2. Nenhum comando, ou um desconhecido, chega à Action da raiz, que devolve cli.Exit com 2. Um arquivo que não abre ou uma linha que não se lê volta do summarise como cli.Exit com 1, e dois arquivos como cli.Exit com 2. Todo erro passa então pelo ExitErrHandler, que não faz nada, então o Run o devolve, e o run imprime a mensagem e devolve o código como status de saída.\"><defs><marker id=\"ue-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ue-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"222\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dentro de cmd.Run, em ordem</text><rect x=\"40\" y=\"52\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ler as flags</text><line x1=\"120\" y1=\"88\" x2=\"120\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ue-ph)\"></line><rect x=\"40\" y=\"117\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">achar o comando</text><line x1=\"120\" y1=\"153\" x2=\"120\" y2=\"181\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ue-ph)\"></line><rect x=\"40\" y=\"182\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">rodar a Action</text><text x=\"345\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma flag ou um valor ruim</text><text x=\"345\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nenhum comando, ou um desconhecido</text><text x=\"345\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um arquivo que não abre,</text><text x=\"345\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma linha ruim, ou dois arquivos</text><line x1=\"200\" y1=\"70\" x2=\"238\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><line x1=\"452\" y1=\"70\" x2=\"488\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><line x1=\"200\" y1=\"135\" x2=\"238\" y2=\"135\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><line x1=\"452\" y1=\"135\" x2=\"488\" y2=\"135\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><line x1=\"200\" y1=\"200\" x2=\"238\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><line x1=\"452\" y1=\"200\" x2=\"488\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ue-am)\"></line><rect x=\"490\" y=\"48\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">OnUsageError</text><text x=\"595\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cli.Exit(..., 2)</text><rect x=\"490\" y=\"113\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a Action da raiz</text><text x=\"595\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cli.Exit(..., 2)</text><rect x=\"490\" y=\"178\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">summarise</text><text x=\"595\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cli.Exit(..., 1 ou 2)</text><line x1=\"595\" y1=\"222\" x2=\"595\" y2=\"262\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ue-ph)\"></line><rect x=\"400\" y=\"264\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ExitErrHandler</text><text x=\"550\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não faz nada, então o Run devolve o erro</text><line x1=\"400\" y1=\"289\" x2=\"318\" y2=\"289\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ue-ph)\"></line><rect x=\"20\" y=\"264\" width=\"296\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"168\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">run(args, stdin, stdout, stderr) int</text><text x=\"168\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">imprime a mensagem, devolve o código</text></svg>", "caption": "Por onde cada falha entra com o segundo main.go, e o que responde por ela. As três respostas terminam em cli.Exit, e o run lê o código de volta."}
```

As mesmas chamadas no binário recompilado, e mais uma que falha por um motivo próprio:

```
ana@vm:~/cli-hits$ go build -o hits .
ana@vm:~/cli-hits$ ./hits top -n five access.log; echo $?
hits top: invalid value "five" for flag -n: strconv.ParseInt: parsing "five": invalid syntax (see 'hits top --help')
2
ana@vm:~/cli-hits$ ./hits top -n five access.log 2>/dev/null | wc -c
0
ana@vm:~/cli-hits$ ./hits cont access.log; echo $?
hits: unknown command "cont", did you mean "count"?
2
ana@vm:~/cli-hits$ ./hits; echo $?
hits: no command given (see 'hits --help')
2
ana@vm:~/cli-hits$ ./hits top a.log b.log; echo $?
hits: one file at most, got 2
2
ana@vm:~/cli-hits$ ./hits count nope.log; echo $?
hits: open nope.log: no such file or directory
1
```

**Toda mensagem agora é uma linha na saída de erro**: o `wc -c` contou zero bytes na saída padrão
para o valor ruim, onde a versão da seção 02 tinha escrito uma tela inteira de ajuda. Os códigos
são os da lição 1, 2 para cada erro na chamada e 1 para o arquivo que não abriu, e o erro de
digitação ganhou uma sugestão do `cli.SuggestCommand`. A ajuda pedida com `--help` continua indo
para a saída padrão, como deve: nesse caso a ajuda é o resultado.

## Onde os padrões ainda aparecem

Duas chamadas passam pelos três ganchos:

```
ana@vm:~/cli-hits$ ./hits help nope; echo $?
No help topic for 'nope'
3
ana@vm:~/cli-hits$ HITS_TOP=x ./hits top access.log; echo $?
hits: could not parse "x" as int value from environment variable "HITS_TOP" for flag n: strconv.ParseInt: parsing "x": invalid syntax
1
```

**O comando `help` embutido tem o próprio caminho de "não encontrado"**, e ele devolve o
`cli.Exit(…, 3)` da biblioteca sem consultar a `Action` da raiz; o `run` repassa o 3 fielmente. Um
valor do ambiente que não converte é checado depois da leitura das flags, fora do caminho que o
`OnUsageError` cobre, e chega ao `run` como erro comum, então recebe o 1 reservado aos erros que
ninguém classificou. Os dois são erros de quem chamou, e os dois precisariam de mais código para
sair como 2: o `help` poderia ser escondido com `HideHelpCommand` e substituído, e o `run` poderia
olhar o texto do erro. Nada disso é feito aqui, e esse é um retrato justo de um framework: **os
padrões dele continuam chegando ao usuário por caminhos que você não escreveu**. Um contrato se
mantém testando-o, não supondo que a biblioteca concorda com ele.

O campo `Suggest`, que você pode ver na documentação da biblioteca, acrescenta uma linha "Did you
mean" à mensagem de erro de uso dela, aquela que o `OnUsageError` substitui aqui, e é por isso que o
`hits` calcula a sugestão por conta própria.

## A completação vem de graça

O `EnableShellCompletion: true` acrescentou um comando escondido, `completion`, que imprime um
script para bash, zsh, fish ou PowerShell, e uma flag escondida que o script usa para perguntar ao
programa o que pode vir em seguida:

```
ana@vm:~/cli-hits$ ./hits completion bash | head -1
# This is a shell completion script auto-generated by https://github.com/urfave/cli for bash.
ana@vm:~/cli-hits$ ./hits --generate-shell-completion
count:requests per status code
top:the paths with the most requests
help:Shows a list of commands or help for one command
/home/user/schooling/content/code/courses/go-production/lessons/le-jnxddvfk/help-errors-and-exit.md: 0 blocks printing main_test.go, and this needs exactly one
```

**O script chama o próprio `hits` toda vez que se aperta Tab**, com `--generate-shell-completion`
no fim do que já foi digitado, e oferece o que volta. O `hits completion --help` diz como
carregá-lo: `source <(hits completion bash)` no `~/.bashrc`. O script se registra para o nome de
comando `hits`, então o binário precisa estar no seu `PATH`, em `~/go/bin` depois de um
`go install`, por exemplo. Esse passo não foi rodado aqui, porque uma transcrição não aperta Tab. A
versão da lição 1 não tinha completação nenhuma, e esta custou um único campo.

## O contrato, testado

O teste tem o formato do da lição 1: uma tabela de listas de argumentos, cada uma com o código de
saída e o começo da saída de erro que deve produzir, passadas pelo `run` com buffers no lugar dos
fluxos. Salve-o como `main_test.go`, ao lado do `main.go`:

```go
package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestRun(t *testing.T) {
	log := "2026-10-01T09:00:01Z GET / 200 5ms\n" +
		"2026-10-01T09:00:02Z GET /login 404 7ms\n"
	tests := []struct {
		name   string
		args   []string
		stdin  string
		code   int
		stdout string
		stderr string // what standard error starts with
	}{
		{"count from stdin", []string{"count", "-json"}, log, 0, "{\"200\":1,\"404\":1}\n", ""},
		{"flags after the file", []string{"top", "-", "-n", "1", "-json"}, log, 0, "[{\"path\":\"/\",\"hits\":1}]\n", ""},
		{"no command", nil, "", 2, "", "hits: no command given"},
		{"typo", []string{"cont"}, "", 2, "", "hits: unknown command \"cont\", did you mean \"count\"?\n"},
		{"bad value", []string{"top", "-n", "0"}, "", 2, "", "hits top: invalid value \"0\" for flag -n"},
		{"bad line", []string{"count"}, "oops\n", 1, "", "hits: line 1: want 5 fields, got 1\n"},
		{"two files", []string{"top", "a.log", "b.log"}, "", 2, "", "hits: one file at most, got 2\n"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			code := run(tt.args, strings.NewReader(tt.stdin), &stdout, &stderr)
			if code != tt.code {
				t.Errorf("exit code %d, want %d", code, tt.code)
			}
			if stdout.String() != tt.stdout {
				t.Errorf("stdout %q, want %q", stdout.String(), tt.stdout)
			}
			if !strings.HasPrefix(stderr.String(), tt.stderr) {
				t.Errorf("stderr %q, want it to start with %q", stderr.String(), tt.stderr)
			}
		})
	}
}
```

```
ana@vm:~/cli-hits$ go test -v .
# example.com/hits
main_test.go:1:1: expected 'package', found 'EOF'
FAIL	example.com/hits [setup failed]
FAIL
```

**A segunda linha, `flags after the file`, é um teste em que a versão da lição 1 falharia**, e a
linha `typo` fixa a sugestão. Agora apague a linha do `ExitErrHandler` e rode os testes de novo:

```
ana@vm:~/cli-hits$ sed -i '/ExitErrHandler/d' main.go; go test .
# example.com/hits
main_test.go:1:1: expected 'package', found 'EOF'
FAIL	example.com/hits [setup failed]
FAIL
```

**O binário de teste morreu na terceira linha.** O `no command` devolveu um `cli.Exit`, o tratador
padrão da biblioteca imprimiu a mensagem e chamou `os.Exit(2)`, e as linhas restantes nunca
rodaram. A mensagem também caiu no terminal e não no buffer da linha, porque o tratador padrão
escreve no `cli.ErrWriter` do pacote, que é o `os.Stderr`, e não no `ErrWriter` do comando. Ponha a
linha de volta antes de seguir; o `go test .` então responde `ok` de novo.
