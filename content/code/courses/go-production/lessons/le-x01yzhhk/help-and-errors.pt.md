---
title: Ajuda, erros e o código de saída
version: 1
---

O Cobra escreve a ajuda e encontra os erros. **Ele não decide o código de saída**: o `Execute`
devolve um erro ou `nil`, e com que status o processo sai fica por conta do `main`. O modelo do
gerador resolve isso do jeito mais bruto, com `os.Exit(1)` para qualquer erro, o que faria um erro
de digitação e um arquivo inexistente parecerem iguais para um script. A lição 1 seção 05 prometeu
mais do que isso, três códigos com três significados, e esta seção cumpre a promessa.

## Ajuda que ninguém escreveu

Cada `Use`, `Short` e `Long` do `main.go` é uma frase que alguém escreveu uma vez. O Cobra as
organiza, para a raiz e para cada comando:

```
ana@vm:~/cobra-hits$ ./hits --help
hits reads an access log, one request per line, and counts it.
With no file, or with -, it reads standard input.

Usage:
  hits [flags]
  hits [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  count       Requests per status code
  help        Help about any command
  top         The paths with the most requests

Flags:
  -h, --help   help for hits
      --json   print JSON instead of a table

Use "hits [command] --help" for more information about a command.
ana@vm:~/cobra-hits$ ./hits help top | head -4
The paths with the most requests

Usage:
  hits top [file] [flags]
```

Os comandos aparecem em ordem alfabética com o seu `Short`, e dois dos quatro nunca foram escritos:
**`help` e `completion` são acrescentados pelo Cobra a toda raiz que tenha subcomandos.**
`hits help top` imprime a ajuda do próprio `top`, igual a `hits top --help` na seção 03, que é o
segundo item da lista da lição 1 do que faltava. O texto de uso escrito à mão da lição 1, o
`case "help"` e o tratamento do `-h` sumiram do programa.

## Erros, e quem os cometeu

Os mesmos erros da lição 1 seção 04, contra o programa novo:

```
ana@vm:~/cobra-hits$ ./hits cont access.log; echo $?
hits: unknown command "cont" for "hits"

Did you mean this?
	count

Run 'hits --help' for usage.
2
ana@vm:~/cobra-hits$ ./hits; echo $?
hits: which command? count or top
Run 'hits --help' for usage.
2
ana@vm:~/cobra-hits$ ./hits top -n five access.log; echo $?
hits: invalid argument "five" for "-n, --number" flag: strconv.ParseInt: parsing "five": invalid syntax
Run 'hits top --help' for usage.
2
ana@vm:~/cobra-hits$ ./hits top a.log b.log; echo $?
hits: accepts at most 1 arg(s), received 2
Run 'hits top --help' for usage.
2
ana@vm:~/cobra-hits$ ./hits count nope.log; echo $?
hits: open nope.log: no such file or directory
1
```

**`cont` agora ganha uma sugestão**, e o primeiro item da lista da lição 1 está riscado. O Cobra
compara a palavra desconhecida com o nome de cada comando e oferece cada um que esteja a até duas
edições dela, ou cujo nome comece por ela; `cont` está a uma letra de `count`. As outras mensagens
são do Cobra e do pflag, mais técnicas que as da lição 1. `accepts at most 1 arg(s)` vem do
`cobra.MaximumNArgs(1)`, que conferiu os argumentos antes de o `RunE` rodar. E cada linha foi para a
saída de erro, cada engano terminou em 2 e o arquivo que não abriu terminou em 1, **como manda a
tabela da lição 1 seção 05**.

## Como o `run` separa um do outro

Os cinco erros voltaram do `ExecuteC` como valores `error` comuns, e nada no Cobra marca um deles
como erro de uso. A distinção tem de vir do outro lado. **Todo erro que o `RunE` de um comando
devolve por uma execução que falhou vem embrulhado em `runError`; o resto veio do Cobra ou do pflag,
antes de qualquer `RunE` começar, e é erro na linha de comando.** Então o `run` faz uma pergunta só:

```go
	var failed runError
	if errors.As(err, &failed) {
		return 1
	}
```

O `errors.As` procura um `runError` na cadeia de erros embrulhados, e é por isso que o `runError` tem
um método `Unwrap`: quem chama ainda pode perguntar `errors.Is(err, fs.ErrNotExist)` ao erro de
dentro. Um comando desconhecido, uma flag desconhecida, um valor que não converte e argumentos
demais não têm o invólucro e recebem 2, com uma dica que cita o comando que os recusou. A dica copia
as palavras do próprio Cobra, `Run 'hits top --help' for usage.`; o `ExecuteC` devolveu o `top`
além do erro, e é assim que o `run` sabe o que citar.

O `./hits` sozinho pedia mais uma decisão. **Uma raiz com subcomandos e sem `RunE` próprio imprime
a ajuda e devolve `nil`**, então a resposta padrão do Cobra é status 0. Dar à raiz um `RunE` que
devolve um erro comum transforma isso em erro de uso e mantém o 2 da lição 1. O preço aparece na
ajuda acima: o Cobra passa a achar que o `hits` roda sozinho e lista `hits [flags]` como linha de
uso.

## Por que os dois campos `Silence` estão ligados

Deixado por conta própria, o Cobra imprime o erro ele mesmo, como `Error: ` seguido da mensagem, e
depois a listagem de uso inteira do comando. O `run` liga `SilenceErrors` e `SilenceUsage` e imprime
a linha que quer, por um motivo fácil de passar despercebido. **O Cobra imprime o uso com `Println`,
que escreve no writer dado ao `SetOut` e só recorre à saída de erro quando não há nenhum.** O `run`
dá à árvore a saída padrão dele, então a listagem depois de uma flag ruim ou de argumentos em
número errado teria ido para a saída padrão, para dentro do pipe ou do arquivo destinado aos
resultados. Silenciar os dois e imprimir no `run` põe toda reclamação na saída de erro, onde a lição
1 seção 05 as pôs.

Sobra uma brecha, e ela é do Cobra:

```
ana@vm:~/cobra-hits$ ./hits help cont 2>/dev/null | head -2; echo ${PIPESTATUS[0]}
Unknown help topic [`cont`]
Usage:
0
```

O comando `help` embutido responde a um tópico desconhecido na saída padrão, com status 0, e o
`2>/dev/null` não o escondeu. É o único caminho deste programa que quebra o contrato, e a correção
seria um comando `help` seu, definido com `SetHelpCommand`. O `hits` deixa como está, porque quem
chamou pediu ajuda e recebeu, mesmo que não a que queria.

## O teste, reescrito

O `run` manteve a assinatura da lição 1, então o teste de tabela da lição 1 passa quase linha por
linha. As linhas mudam para o que o Cobra diz, e três são novas: flags depois do arquivo, o erro de
digitação com a sugestão, e o `-json` da lição 1. O `main_test.go`, ao lado do `main.go`:

```go
package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestRun(t *testing.T) {
	log := "2026-10-01T09:00:01Z GET / 200 5ms\n" +
		"2026-10-01T09:00:02Z GET /login 404 7ms\n" +
		"2026-10-01T09:00:03Z POST /login 200 9ms\n"
	tests := []struct {
		name   string
		args   []string
		stdin  string
		code   int
		stdout string
		stderr string // what standard error starts with
	}{
		{"count from stdin", []string{"count", "--json"}, log, 0, "{\"200\":2,\"404\":1}\n", ""},
		{"flags after the file", []string{"top", "-", "-n", "1", "--json"}, log, 0, "[{\"path\":\"/login\",\"hits\":2}]\n", ""},
		{"no command", []string{}, "", 2, "", "hits: which command?"}, // nil would read os.Args
		{"typo", []string{"cont"}, "", 2, "", "hits: unknown command \"cont\" for \"hits\"\n\nDid you mean this?\n\tcount\n"},
		{"old flag spelling", []string{"top", "-json"}, log, 2, "", "hits: unknown shorthand flag: 'j' in -json\n"},
		{"bad line", []string{"count"}, "oops\n", 1, "", "hits: line 1: want 5 fields, got 1\n"},
		{"two files", []string{"top", "a.log", "b.log"}, "", 2, "", "hits: accepts at most 1 arg(s), received 2\n"},
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
ana@vm:~/cobra-hits$ go test -v .
=== RUN   TestRun
=== RUN   TestRun/count_from_stdin
=== RUN   TestRun/flags_after_the_file
=== RUN   TestRun/no_command
=== RUN   TestRun/typo
=== RUN   TestRun/old_flag_spelling
=== RUN   TestRun/bad_line
=== RUN   TestRun/two_files
--- PASS: TestRun (0.00s)
    --- PASS: TestRun/count_from_stdin (0.00s)
    --- PASS: TestRun/flags_after_the_file (0.00s)
    --- PASS: TestRun/no_command (0.00s)
    --- PASS: TestRun/typo (0.00s)
    --- PASS: TestRun/old_flag_spelling (0.00s)
    --- PASS: TestRun/bad_line (0.00s)
    --- PASS: TestRun/two_files (0.00s)
PASS
ok  	example.com/hits	0.009s
```

**Cada linha monta uma árvore nova**, porque o `run` chama `newRootCmd` toda vez. Esse é o motivo
que a seção 02 deu para preferir construtores a comandos em variáveis de pacote: o `n` do `top` é
uma variável nova em cada linha, então a linha que passa `-n 1` não pode deixar o 1 para a próxima.
Dois detalhes da tabela são do Cobra. A linha `no command` passa uma fatia vazia e não `nil`, porque
o `ExecuteC` entende `nil` como "nenhum argumento foi definido" e lê o `os.Args`, que dentro de um
binário de teste guarda as flags do próprio executor de testes. E o `-` da segunda linha é a entrada
padrão: o pflag trata um traço sozinho como argumento, não como flag.
