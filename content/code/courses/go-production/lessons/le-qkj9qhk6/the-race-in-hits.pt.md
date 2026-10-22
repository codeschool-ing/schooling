---
title: Uma corrida que passa por todas as outras checagens
version: 1
---

A lição 16 de `go-concurrency` rodou o detector de corrida à mão, em programas pequenos escritos
para ter uma corrida. Esta lição trata da execução que ninguém precisa lembrar de digitar. **Uma
corrida não se anuncia: o build funciona, o `go vet` fica quieto, os testes passam e o programa
imprime um número com cara de contagem.** A única coisa que a encontra é uma execução com `-race`, e
o único jeito de garantir que essa execução acontece é fazer o pipeline rodá-la. Por isso a lição
começa com uma corrida no `hits` que passa por todo o resto.

## Contando com quatro workers

O `Count` da lição 1 lê uma linha por vez numa goroutine só. Numa máquina com quatro CPUs, o passo
óbvio seguinte é dividir o parsing. A lição trabalha em `~/race-hits`, uma cópia do `hits` da lição
1: o mesmo `go.mod`, o mesmo `access.log` de 20.000 linhas e os quatro arquivos que a lição 1
imprimiu, `tools/genlog/main.go`, `internal/tally/tally.go`, `main.go` e `main_test.go`. Ao lado do
`tally.go`, salve `internal/tally/parallel.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tally/parallel.go",
  "parts": [
    {
      "code": "package tally\n\nimport (\n\t\"bufio\"\n\t\"errors\"\n\t\"fmt\"\n\t\"io\"\n\t\"runtime\"\n\t\"sync\"\n)\n",
      "note": "Um segundo arquivo no mesmo pacote, ao lado do `tally.go` da lição 1. Ele usa o `Parse` e o `Summary` daquele arquivo e não muda nenhum dos dois."
    },
    {
      "code": "// CountParallel does what Count does, with several workers parsing the\n// lines at once. With workers below 1 it starts one per CPU, as GOMAXPROCS\n// counts them. It reports every line it cannot parse, not only the first.\nfunc CountParallel(r io.Reader, workers int) (Summary, error) {\n\tif workers < 1 {\n\t\tworkers = runtime.GOMAXPROCS(0)\n\t}",
      "note": "**Zero ou um número negativo de workers significa um por CPU**, que é o que `runtime.GOMAXPROCS(0)` informa. A seção 03 mostra por que essa frase importa para um teste."
    },
    {
      "code": "\tvar lines []string\n\tsc := bufio.NewScanner(r)\n\tfor sc.Scan() {\n\t\tlines = append(lines, sc.Text())\n\t}\n\tif err := sc.Err(); err != nil {\n\t\treturn Summary{}, err\n\t}\n",
      "note": "As linhas são lidas primeiro, por uma goroutine, para que os workers dividam um slice em vez de um scanner, que não é seguro chamar de duas goroutines."
    },
    {
      "code": "\ts := Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}\n\terrs := make([]error, workers)\n\tvar mu sync.Mutex\n\tvar wg sync.WaitGroup",
      "note": "Um `Summary` para todos os workers, um mutex e **um espaço de erro por worker**: o worker `w` escreve só em `errs[w]`, então os espaços não precisam de lock."
    },
    {
      "code": "\tfor w := range workers {\n\t\twg.Go(func() {\n\t\t\tfor i := w; i < len(lines); i += workers {\n\t\t\t\te, err := Parse(lines[i])\n\t\t\t\tif err != nil {\n\t\t\t\t\terrs[w] = errors.Join(errs[w], fmt.Errorf(\"line %d: %w\", i+1, err))\n\t\t\t\t\tcontinue\n\t\t\t\t}\n\t\t\t\ts.Lines++\n\t\t\t\ts.Total += e.Duration\n\t\t\t\tmu.Lock() // two goroutines must never write a map at once\n\t\t\t\ts.ByStatus[e.Status]++\n\t\t\t\ts.ByPath[e.Path]++\n\t\t\t\tmu.Unlock()\n\t\t\t}\n\t\t})\n\t}",
      "note": "O worker `w` pega as linhas `w`, `w+workers`, `w+2*workers` e assim por diante, então nenhuma linha é lida duas vezes. Os dois contadores sobem primeiro, e depois os dois mapas são atualizados sob o lock."
    },
    {
      "code": "\twg.Wait()\n\treturn s, errors.Join(errs...)\n}",
      "note": "O `errors.Join` descarta os espaços nil e devolve nil quando todos são nil."
    }
  ]
}
```

Quem escreveu esse código esbarrou primeiro no problema do mapa. Duas goroutines gravando no mesmo
mapa ao mesmo tempo é algo que o runtime do Go detecta e pelo qual encerra o programa, então as
atualizações dos mapas foram para baixo de um mutex e a queda sumiu. **As duas linhas acima do lock
ficaram onde estavam**, porque `s.Lines++` e `s.Total += e.Duration` nunca derrubaram nada.

O teste compara o `CountParallel` com o `Count`, em que a lição 1 já confia, sobre quatro linhas.
Uma função auxiliar recebe o número de workers, porque a seção 03 a chama mais duas vezes. O
benchmark é para a seção 04. `internal/tally/parallel_test.go`:

```go
package tally

import (
	"maps"
	"strings"
	"testing"
)

const sample = "2026-10-01T09:00:01Z GET / 200 5ms\n" +
	"2026-10-01T09:00:02Z GET /login 404 7ms\n" +
	"2026-10-01T09:00:03Z POST /login 200 9ms\n" +
	"2026-10-01T09:00:04Z GET / 304 1ms\n"

// checkParallel compares CountParallel, with this many workers, with Count.
func checkParallel(t *testing.T, workers int) {
	t.Helper()
	want, err := Count(strings.NewReader(sample))
	if err != nil {
		t.Fatal(err)
	}
	got, err := CountParallel(strings.NewReader(sample), workers)
	if err != nil {
		t.Fatal(err)
	}
	if got.Lines != want.Lines || got.Total != want.Total ||
		!maps.Equal(got.ByStatus, want.ByStatus) || !maps.Equal(got.ByPath, want.ByPath) {
		t.Errorf("CountParallel(%d workers) = %+v, want %+v", workers, got, want)
	}
}

func TestCountParallel(t *testing.T) { checkParallel(t, 2) }

func BenchmarkCountParallel(b *testing.B) {
	log := strings.Repeat(sample, 5000) // 20,000 lines
	for b.Loop() {
		if _, err := CountParallel(strings.NewReader(log), 4); err != nil {
			b.Fatal(err)
		}
	}
}
```

E um comando pequeno o bastante para ler de relance, que roda o `CountParallel` sobre a entrada
padrão com um worker por CPU. `tools/pcount/main.go`:

```go
// Command pcount counts a log from standard input with tally.CountParallel,
// one worker per CPU, and prints how many lines and how much time it found.
package main

import (
	"fmt"
	"os"

	"example.com/hits/internal/tally"
)

func main() {
	s, err := tally.CountParallel(os.Stdin, 0)
	if err != nil {
		fmt.Fprintln(os.Stderr, "pcount:", err)
		os.Exit(1)
	}
	fmt.Println(s.Lines, "lines,", s.Total, "in total")
}
```

## Tudo passa

```
ana@vm:~/race-hits$ go vet ./... && go test -count=1 ./...
ok  	example.com/hits	0.005s
ok  	example.com/hits/internal/tally	0.003s
?   	example.com/hits/tools/genlog	[no test files]
?   	example.com/hits/tools/pcount	[no test files]
ana@vm:~/race-hits$ go build -o pcount ./tools/pcount && for i in 1 2 3 4 5 6; do ./pcount < access.log; done
20000 lines, 1h6m37.778s in total
19998 lines, 1h6m37.524s in total
19999 lines, 1h6m37.275s in total
19994 lines, 1h6m36.788s in total
19992 lines, 1h6m36.31s in total
19909 lines, 1h6m18.232s in total
```

**O `go vet` não achou nada e os dois pacotes de teste passaram.** Depois, seis execuções do
`pcount` sobre o mesmo arquivo de 20.000 linhas imprimiram seis contagens diferentes. A primeira acertou. As outras cinco ficaram entre 1 e 91 linhas abaixo, e nenhuma parecia errada: 19.994 é um
número de requisições perfeitamente crível, e nada na saída diz que ele esteve em dúvida algum dia.
O tempo total oscilou junto com a contagem, descendo até `1h6m18.232s` a partir do `1h6m37.778s` da
execução certa. Se a primeira tivesse sido a única, como seria numa conferência rápida à mão, o bug
pareceria resolvido.

Duas coisas mantiveram o teste verde. Quatro linhas divididas entre dois workers dão a cada goroutine
duas linhas de trabalho, que terminam antes de a outra começar direito, então os incrementos quase
nunca se sobrepõem no tempo. E um incremento perdido exige que duas goroutines leiam o mesmo valor
antigo de `s.Lines` nos mesmos poucos nanossegundos. Com 20.000 linhas e quatro workers isso
aconteceu de nenhuma a 91 vezes por execução, e com quatro linhas praticamente nunca acontece.
**Um teste que confere resultados só falha quando o tempo dá errado durante aquela execução**, e aqui
ele não tinha motivo para isso.

## Uma flag

O mesmo teste, com o detector e com `GORACE=halt_on_error=1`, para que a execução pare no primeiro
relatório, a configuração que a lição 16 de `go-concurrency` usou para deixar a saída com um
relatório só:

```
ana@vm:~/race-hits$ GORACE=halt_on_error=1 go test -race -count=1 ./internal/tally
==================
WARNING: DATA RACE
Read at 0x00c0000301e0 by goroutine 9:
  example.com/hits/internal/tally.CountParallel.func1()
      /home/ana/race-hits/internal/tally/parallel.go:40 +0x3f8

Previous write at 0x00c0000301e0 by goroutine 10:
  example.com/hits/internal/tally.CountParallel.func1()
      /home/ana/race-hits/internal/tally/parallel.go:40 +0x410

Goroutine 9 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
  example.com/hits/internal/tally.checkParallel()
      /home/ana/race-hits/internal/tally/parallel_test.go:21 +0x1f8
  example.com/hits/internal/tally.TestCountParallel()
      /home/ana/race-hits/internal/tally/parallel_test.go:31 +0x2b
  testing.tRunner()
      /usr/local/go/src/testing/testing.go:2193 +0x21c
  testing.(*T).Run.gowrap1()
      /usr/local/go/src/testing/testing.go:2258 +0x38

Goroutine 10 (finished) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
  example.com/hits/internal/tally.checkParallel()
      /home/ana/race-hits/internal/tally/parallel_test.go:21 +0x1f8
  example.com/hits/internal/tally.TestCountParallel()
      /home/ana/race-hits/internal/tally/parallel_test.go:31 +0x2b
  testing.tRunner()
      /usr/local/go/src/testing/testing.go:2193 +0x21c
  testing.(*T).Run.gowrap1()
      /usr/local/go/src/testing/testing.go:2258 +0x38
==================
FAIL	example.com/hits/internal/tally	0.010s
FAIL
```

**O teste que passou há pouco agora falha, e falha sempre**: o detector não espera dois incrementos
colidirem, ele percebe que duas goroutines tocaram `s.Lines` sem nada ordenando os dois acessos. O
relatório se lê do jeito que a lição 16 de `go-concurrency` ensinou. Os dois acessos estão na linha
40 de `parallel.go`, `s.Lines++`, uma leitura pela goroutine 9 e uma escrita anterior pela goroutine 10. O `++` lê o valor antigo e grava o novo, e as duas goroutines fizeram isso sem lock entre elas.

Os locais de nascimento pedem um fato a mais do que aquela lição deu. Abaixo de
`sync.(*WaitGroup).Go()` o quadro seguinte é `checkParallel()` na linha 21 do teste, a chamada ao `CountParallel`.
**O quadro do próprio `CountParallel`, cujo laço chamou `wg.Go`, não está lá.** O
detector monta essas pilhas a partir de um registro que o compilador acrescenta na entrada e na
saída de cada função, e o toolchain deixa esse registro de fora do pacote `sync`. Então o quadro
abaixo de `sync.(*WaitGroup).Go()` é quem chamou a função que você procura, um nível acima, e a
função que você quer é a que esse quadro estava chamando.

Sem `halt_on_error` o detector segue em frente, e a execução inteira tem dois relatórios, o segundo
contando a mesma história para `s.Total` na linha 41:

```
ana@vm:~/race-hits$ go test -race -count=1 ./internal/tally 2>&1 | grep -c "WARNING: DATA RACE"
2
ana@vm:~/race-hits$ go build -race -o pcount-race ./tools/pcount && ./pcount-race < access.log 2>/dev/null; echo $?
19666 lines, 1h5m34.74s in total
66
```

O último comando é o `pcount` compilado com `-race`. Ele imprimiu 19.666 linhas, errado de novo, e
**saiu com status 66**, o código do detector para "esta execução teve uma corrida", mesmo com a
saída de erro, para onde iam os relatórios, jogada fora. Um script que ignora cada palavra da saída
continua recebendo a resposta, e é sobre isso que a seção 05 monta um pipeline.

A seção 03 mantém esta versão quebrada mais um pouco, porque a próxima pergunta é a incômoda: quando
o `-race` a teria deixado passar?
