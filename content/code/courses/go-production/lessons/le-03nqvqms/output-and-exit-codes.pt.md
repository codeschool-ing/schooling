---
title: Dois fluxos e um código de saída
version: 1
---

Um programa de linha de comando tem três jeitos de responder, e **um script que o lê usa cada um
para uma pergunta diferente**. A saída padrão responde "o que você encontrou". A saída de erro
responde "o que deu errado", para a pessoa olhando. O código de saída responde "funcionou?", para o
programa que o iniciou. Misturar os três não quebra a ferramenta quando uma pessoa a roda à mão;
quebra na primeira vez que alguém a coloca num pipeline, num cron ou num passo de CI.

## Resultados num fluxo, reclamações no outro

Toda mensagem que o `hits` imprime sobre um problema vai para `stderr`, que o `run` recebe como
parâmetro. A diferença é invisível num terminal, onde os dois fluxos caem na mesma tela, e óbvia no
momento em que um deles é redirecionado:

```
ana@vm:~/hits$ ./hits count nope.log; echo $?
hits: open nope.log: no such file or directory
1
ana@vm:~/hits$ ./hits count nope.log 2>/dev/null; echo $?
1
ana@vm:~/hits$ ./hits top a.log b.log 2>&1 >/dev/null | wc -l
1
```

O `2>/dev/null` jogou fora a saída de erro, e a mensagem foi junto, enquanto o código de saída
ficou. A terceira linha é o truque contrário: ela aponta a saída de erro para o pipe e a saída
padrão para lugar nenhum, e o `wc` contou a única linha de reclamação. **Se essa reclamação tivesse
ido para a saída padrão, o próximo programa do pipeline a leria como dado**, e um relatório montado
com `hits top` ganharia uma linha dizendo `hits: one file at most, got 2`.

A mensagem começa com o nome do programa pelo mesmo motivo. Num pipeline de quatro ferramentas, uma
linha na tela dizendo `open nope.log: no such file or directory` não diz quem não conseguiu abrir.

## O código de saída responde "funcionou?"

| código | o que o `hits` quer dizer com ele | exemplos acima |
|---|---|---|
| `0` | fez o que foi pedido | uma tabela, um array JSON, uma ajuda pedida |
| `1` | foi chamado corretamente e a execução falhou | um arquivo que não abre, uma linha que não converte |
| `2` | foi chamado errado | sem comando, comando desconhecido, flag errada, dois arquivos |

Só o `0` é universal: ele quer dizer sucesso para todo shell, todo `make`, todo sistema de CI. A
separação entre 1 e 2 é uma convenção que o pacote flag segue, o `grep` segue e o `hits` segue.
Vale mantê-la porque um script distingue "conserte a chamada" de "conserte os dados" sem ler uma
palavra em inglês. Um script de shell a usa direto, em `if ./hits count "$f"; then` ou com
`set -e`, que para o script no primeiro comando que devolver qualquer coisa diferente de 0.

## Lendo a entrada padrão

Sem arquivo, ou com `-`, o `hits` lê a entrada padrão, o que o deixa ficar na ponta de um pipe:

```
ana@vm:~/hits$ echo "not a log line" | ./hits count; echo $?
hits: line 1: want 5 fields, got 4
1
ana@vm:~/hits$ go run ./tools/genlog -n 1000 -seed 3 | ./hits top -n 2
path             requests
/static/app.css  137
/api/users       135
ana@vm:~/hits$ ./hits count -json - < access.log
{"200":7554,"201":1256,"204":1248,"301":1192,"304":1229,"400":1223,"401":1226,"404":2549,"500":1269,"503":1254}
```

O erro cita a linha, porque a entrada pode ter um milhão de linhas e vir de um programa que já foi
embora. O `genlog` e o `hits` rodaram ao mesmo tempo no segundo comando, um escrevendo e o outro
lendo, e nenhum arquivo foi criado. O terceiro lê o mesmo arquivo pelo `<` do shell, e as contagens
batem exatamente com a tabela da seção 04.

## Quando o leitor para antes

Um pipe também pode fechar pela outra ponta. O `head` lê as linhas que quer e sai, e o programa que
escreve no pipe fica sem ninguém ouvindo:

```
ana@vm:~/hits$ ./hits top -n 8 access.log | head -2; echo ${PIPESTATUS[@]}
path             requests
/login           2576
0 0
ana@vm:~/hits$ go build -o genlog ./tools/genlog && ./genlog -n 1000000 | head -1; echo ${PIPESTATUS[@]}
2026-10-01T09:00:01Z POST /api/users 404 115ms
141 0
```

O `PIPESTATUS` guarda o código de saída de cada comando do último pipeline. A tabela do `hits` era
pequena o bastante para ser escrita inteira antes de o `head` sair, então os dois são 0. O `genlog`
ainda escrevia a milionésima linha quando o `head` foi embora, e o status dele é **141**, que é 128
mais 13, o número do sinal `SIGPIPE`. Essa é a regra do runtime do Go para a saída padrão e a saída
de erro: uma escrita num pipe cujo leitor sumiu mata o programa com `SIGPIPE`, em silêncio, como o
`cat` e qualquer outra ferramenta Unix. Em qualquer outro descritor, um pipe quebrado é um erro
comum, e um disco cheio também, em qualquer descritor; esses são os erros que `flush` e `encode`
informam.

## A recompensa do `run`

O `main` entrega ao `run` os argumentos e os três fluxos, em vez de deixá-lo buscar `os.Args` e
`os.Stdout`. Isso custa quatro parâmetros e compra uma linha de comando que dá para testar como uma
função comum, com strings entrando e saindo. O `main_test.go`, ao lado do `main.go`:

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
		{"no command", nil, "", 2, "", "usage: hits"},
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
ana@vm:~/hits$ go test -v .
=== RUN   TestRun
=== RUN   TestRun/count_from_stdin
=== RUN   TestRun/no_command
=== RUN   TestRun/bad_line
=== RUN   TestRun/two_files
--- PASS: TestRun (0.00s)
    --- PASS: TestRun/count_from_stdin (0.00s)
    --- PASS: TestRun/no_command (0.00s)
    --- PASS: TestRun/bad_line (0.00s)
    --- PASS: TestRun/two_files (0.00s)
PASS
ok  	example.com/hits	0.003s
```

É a forma orientada a tabela que a lição 26 do `go-concurrency` ensinou, com uma linha por contrato
que a ferramenta assume: o fluxo para onde cada coisa vai e o código de saída que a acompanha.
**Nenhum processo foi iniciado e nenhum arquivo foi escrito**, então o teste roda em milissegundos e
em paralelo com todo o resto. Um programa cujo `main` faz o trabalho sozinho só pode ser testado
compilando e rodando o binário, e esse é um teste que ninguém escreve para os caminhos de erro.
