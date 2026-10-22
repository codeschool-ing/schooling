---
title: Gravando um trace
version: 1
---

Um profile e um trace parecem duas configurações da mesma ferramenta, e não são. **O profile de CPU
da lição 12 faz amostragem**: umas cem vezes por segundo ele pergunta qual função está num
processador, e a resposta é uma contagem. **Um trace de execução registra eventos**: cada vez que
uma goroutine é criada, começa a rodar, bloqueia, acorda ou faz uma chamada de sistema, o runtime
anota o que aconteceu, em qual thread e processador, com um timestamp em nanossegundos e quase
sempre uma pilha. Nada é estimado, e o custo acompanha quanto acontece, não quanto tempo o programa
roda.

Essa diferença decide o que cada um consegue ver. Uma goroutine parada num mutex não está em
processador nenhum, então nenhuma amostra cai nela. Num trace, o momento em que ela parou e o
momento em que acordou são eventos, e o intervalo entre os dois é tempo que dá para medir.

## Três jeitos de começar um

| como | o que grava | quando serve |
|---|---|---|
| `trace.Start(w)` e `trace.Stop()` | o programa, entre as duas chamadas | um comando ao qual você pode dar uma flag |
| `go test -trace=arquivo` | uma execução dos testes de um pacote | um teste ou benchmark que mostra o problema |
| `import _ "net/http/pprof"` | `/debug/pprof/trace` num servidor rodando | um processo de vida longa, consultado por HTTP |

O terceiro é o mesmo tracer atrás de um handler HTTP, e o `go doc runtime/trace` o menciona; esta
lição usa os dois primeiros, porque nenhum deles precisa de servidor.

## Um programa que vale um trace

O `hits` da lição 1 conta numa goroutine só, o que dá a um trace muito pouco a dizer. O programa
aqui conta o mesmo log com várias, do jeito que a lição 7 de `go-concurrency` montou um worker pool:
uma goroutine lê as linhas, um número fixo de workers faz o parse, e as contagens dos workers são
somadas no fim. Ele mora num módulo próprio, `~/trace-hits`, criado com
`go mod init example.com/hits`, com os arquivos `tools/genlog/main.go` e `internal/tally/tally.go`
da lição 1 copiados sem mudança. O programa novo é o `cmd/pcount/main.go`:

```schooling-example
{
  "language": "go",
  "file": "cmd/pcount/main.go",
  "parts": [
    {
      "code": "// Command pcount counts an access log with several goroutines: one reads\n// the lines, the workers parse them, and their tallies are merged at the end.\npackage main\n\nimport (\n\t\"bufio\"\n\t\"context\"\n\t\"flag\"\n\t\"fmt\"\n\t\"io\"\n\t\"os\"\n\t\"runtime/trace\"\n\t\"sync\"\n\t\"time\"\n\n\t\"example.com/hits/internal/tally\"\n)\n\nconst batchSize = 1000\n",
      "note": "Um segundo programa no mesmo módulo do `hits`, em `cmd/`, que usa o pacote `tally` da lição 1 para o parse. `runtime/trace` é o único import que esta lição acrescenta."
    },
    {
      "code": "func main() {\n\tos.Exit(run())\n}\n\nfunc run() int {\n\tworkers := flag.Int(\"workers\", 4, \"how many goroutines parse lines\")\n\tshared := flag.Bool(\"shared\", false, \"share one summary behind one mutex, held for each line\")\n\tout := flag.String(\"trace\", \"\", \"write an execution trace to this file\")\n\tflag.Parse()\n\tif flag.NArg() != 1 {\n\t\tfmt.Fprintln(os.Stderr, \"usage: pcount [-workers N] [-shared] [-trace file] access.log\")\n\t\treturn 2\n\t}\n\tf, err := os.Open(flag.Arg(0))\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"pcount:\", err)\n\t\treturn 1\n\t}\n\tdefer f.Close()\n",
      "note": "Três flags: quantos workers, um jeito propositalmente ruim de dividir as contagens de que a seção 04 precisa, e **o arquivo onde gravar o trace**. Sem `-trace`, nada é gravado e o programa não paga nada por isso."
    },
    {
      "code": "\tif *out != \"\" {\n\t\tstop, err := startTrace(*out)\n\t\tif err != nil {\n\t\t\tfmt.Fprintln(os.Stderr, \"pcount:\", err)\n\t\t\treturn 1\n\t\t}\n\t\tdefer func() {\n\t\t\tif err := stop(); err != nil {\n\t\t\t\tfmt.Fprintln(os.Stderr, \"pcount:\", err)\n\t\t\t}\n\t\t}()\n\t}\n\n\tstart := time.Now()\n\ts, bad, err := count(context.Background(), f, *workers, *shared)\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"pcount:\", err)\n\t\treturn 1\n\t}\n\tfmt.Printf(\"%d lines (%d bad), %d paths, %d workers, %v\\n\",\n\t\ts.Lines, bad, len(s.ByPath), *workers, time.Since(start).Round(time.Millisecond))\n\treturn 0\n}\n",
      "note": "**O trace começa antes do trabalho e para depois dele**, numa chamada adiada. O `run` devolve um código de saída em vez de chamar `os.Exit` ele mesmo, porque o `os.Exit` pula as chamadas adiadas e o trace nunca seria concluído."
    },
    {
      "code": "// startTrace starts the execution tracer writing to a new file, and returns\n// the function that stops it and closes the file.\nfunc startTrace(name string) (func() error, error) {\n\tf, err := os.Create(name)\n\tif err != nil {\n\t\treturn nil, err\n\t}\n\tif err := trace.Start(f); err != nil {\n\t\tf.Close()\n\t\treturn nil, err\n\t}\n\treturn func() error {\n\t\ttrace.Stop()\n\t\treturn f.Close()\n\t}, nil\n}\n",
      "note": "`trace.Start` aceita qualquer `io.Writer` e escreve nele enquanto o programa roda. `trace.Stop` só retorna depois que todas as escritas do trace terminaram, então o arquivo é fechado depois dele, e não antes."
    },
    {
      "code": "// count reads r on this goroutine and hands batches of lines to the workers.\nfunc count(ctx context.Context, r io.Reader, workers int, shared bool) (tally.Summary, int, error) {\n\tctx, task := trace.NewTask(ctx, \"count\")\n\tdefer task.End()\n",
      "note": "**`trace.NewTask` dá nome a uma operação lógica** e a coloca no contexto. Tudo o que for gravado com esse contexto fica ligado à tarefa, e `task.End` marca quando ela terminou."
    },
    {
      "code": "\tbatches := make(chan []string, workers)\n\tparts := make(chan part, workers)\n\tvar mu sync.Mutex\n\ttotal := part{s: newSummary()}\n",
      "note": "Dois canais: lotes de linhas indo para os workers e a contagem de cada worker voltando. Os dois têm buffer de uma vaga por worker."
    },
    {
      "code": "\tvar wg sync.WaitGroup\n\tfor range workers {\n\t\twg.Go(func() {\n\t\t\town := part{s: newSummary()}\n\t\t\tfor b := range batches {\n\t\t\t\ttrace.WithRegion(ctx, \"parse\", func() {\n\t\t\t\t\tfor _, line := range b {\n\t\t\t\t\t\tif shared {\n\t\t\t\t\t\t\tmu.Lock()\n\t\t\t\t\t\t\ttotal.add(line)\n\t\t\t\t\t\t\tmu.Unlock()\n\t\t\t\t\t\t} else {\n\t\t\t\t\t\t\town.add(line)\n\t\t\t\t\t\t}\n\t\t\t\t\t}\n\t\t\t\t})\n\t\t\t}\n\t\t\tparts <- own\n\t\t})\n\t}\n",
      "note": "O worker pool da lição 7 de `go-concurrency`, com o `WaitGroup.Go` (Go 1.25) fazendo o `Add` e o `Done`. **Cada worker conta no seu próprio `part`**, então duas goroutines nunca mexem no mesmo map. O `-shared` faz cada linha passar por um mutex só, segurado enquanto a linha é lida; `trace.WithRegion` marca cada lote como uma região `parse`."
    },
    {
      "code": "\tsc := bufio.NewScanner(r)\n\tb := make([]string, 0, batchSize)\n\tfor sc.Scan() {\n\t\tb = append(b, sc.Text())\n\t\tif len(b) == batchSize {\n\t\t\tbatches <- b\n\t\t\tb = make([]string, 0, batchSize)\n\t\t}\n\t}",
      "note": "A leitora é esta goroutine: ela junta as linhas em lotes de mil e envia cada um. Um envio bloqueia quando todas as vagas do canal estão ocupadas, que é o que acontece quando os workers ficam para trás."
    },
    {
      "code": "\tbatches <- b\n\tclose(batches)\n\twg.Wait()\n\tclose(parts)\n\n\ttrace.WithRegion(ctx, \"merge\", func() {\n\t\tfor p := range parts {\n\t\t\ttotal.merge(p)\n\t\t}\n\t})\n\ttrace.Logf(ctx, \"lines\", \"%d\", total.s.Lines)\n\treturn total.s, total.bad, sc.Err()\n}\n",
      "note": "Sai o último lote, incompleto; fechar o canal encerra o `range` de cada worker, e as contagens são somadas quando todos terminam. `trace.Logf` deixa uma mensagem no trace: o número de linhas."
    },
    {
      "code": "// part is one worker's tally, and the lines it could not parse.\ntype part struct {\n\ts   tally.Summary\n\tbad int\n}\n\nfunc newSummary() tally.Summary {\n\treturn tally.Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}\n}\n\nfunc (p *part) add(line string) {\n\te, err := tally.Parse(line)\n\tif err != nil {\n\t\tp.bad++\n\t\treturn\n\t}\n\tp.s.Lines++\n\tp.s.ByStatus[e.Status]++\n\tp.s.ByPath[e.Path]++\n\tp.s.Total += e.Duration\n}\n\nfunc (p *part) merge(q part) {\n\tp.s.Lines += q.s.Lines\n\tp.bad += q.bad\n\tfor k, v := range q.s.ByStatus {\n\t\tp.s.ByStatus[k] += v\n\t}\n\tfor k, v := range q.s.ByPath {\n\t\tp.s.ByPath[k] += v\n\t}\n\tp.s.Total += q.s.Total\n}",
      "note": "`add` lê uma linha com `tally.Parse` e a conta, ou a conta como ruim. `merge` soma uma contagem na outra. Nenhum dos dois sabe de goroutines."
    }
  ]
}
```

Três arquivos e um log grande o bastante para ocupar quatro goroutines por um segundo. O `genlog`
escreve três milhões de linhas com a semente padrão da lição 1, então o seu arquivo tem estes mesmos
bytes:

```
ana@vm:~/trace-hits$ find . -name "*.go" | sort
./cmd/pcount/main.go
./internal/tally/tally.go
./tools/genlog/main.go
ana@vm:~/trace-hits$ go run ./tools/genlog -n 3000000 > big.log && stat -c "%s bytes  %n" big.log
137194124 bytes  big.log
ana@vm:~/trace-hits$ go build -o pcount ./cmd/pcount && ./pcount -h
Usage of ./pcount:
  -shared
    	share one summary behind one mutex, held for each line
  -trace string
    	write an execution trace to this file
  -workers int
    	how many goroutines parse lines (default 4)
```

## Gravando, e quanto custa

Cada execução abaixo grava um trace ao lado do log:

```
ana@vm:~/trace-hits$ ./pcount -workers 4 -trace w4.trace big.log
3000000 lines (0 bad), 8 paths, 4 workers, 958ms
ana@vm:~/trace-hits$ ./pcount -workers 1 -trace w1.trace big.log
3000000 lines (0 bad), 8 paths, 1 workers, 1.357s
ana@vm:~/trace-hits$ stat -c "%s bytes  %n" w1.trace w4.trace
9453261 bytes  w1.trace
5257509 bytes  w4.trace
```

**O tamanho de um trace acompanha os eventos, não o trabalho.** As duas execuções leram os mesmos
três milhões de linhas, e a de um worker gravou 9.453.261 bytes contra 5.257.509, porque rodou por
mais tempo e o runtime continuou produzindo eventos o tempo todo: só o coletor de lixo já é uma
torrente deles, como a seção 03 conta. Isso dá entre cinco e sete megabytes por segundo deste
programa; uma hora nesse ritmo seriam uns vinte gigabytes, e esse é o problema que a seção 05
resolve.

O custo em tempo é mais difícil de ver, e o jeito honesto de mostrá-lo é tentar. Três pares de
execuções, cada um primeiro sem trace e depois com:

```
ana@vm:~/trace-hits$ for i in 1 2 3; do printf "plain   "; ./pcount big.log; printf "traced  "; ./pcount -trace x.trace big.log; done
plain   3000000 lines (0 bad), 8 paths, 4 workers, 1.021s
traced  3000000 lines (0 bad), 8 paths, 4 workers, 689ms
plain   3000000 lines (0 bad), 8 paths, 4 workers, 953ms
traced  3000000 lines (0 bad), 8 paths, 4 workers, 878ms
plain   3000000 lines (0 bad), 8 paths, 4 workers, 883ms
traced  3000000 lines (0 bad), 8 paths, 4 workers, 737ms
```

Toda execução com trace foi mais rápida que a sem trace logo antes, e ninguém acredita nisso. **O
ruído entre duas execuções idênticas foi maior do que o custo do trace**, numa máquina de laboratório
com quatro CPUs divididas com outros trabalhos, e três pares não separam uma coisa da outra. O que
dá para dizer é que o custo não foi grande o bastante para aparecer através desse ruído. Medi-lo
direito pede muitas execuções numa máquina quieta e uma comparação estatística, a disciplina que a
lição 29 de `go-concurrency` aplica a benchmarks. **Todo tempo desta lição veio dessa máquina**,
então leia cada um como uma execução só.

## A partir de um teste

O `go test -trace` não pede nada no código. Um teste para o `count` que confere os dois jeitos de
dividir as contagens contra o `tally.Count`, em `cmd/pcount/main_test.go`:

```go
package main

import (
	"context"
	"fmt"
	"reflect"
	"strings"
	"testing"

	"example.com/hits/internal/tally"
)

// TestCountAgrees checks that both ways of counting in parallel find what
// tally.Count finds on its own.
func TestCountAgrees(t *testing.T) {
	var log strings.Builder
	for i := range 20000 {
		fmt.Fprintf(&log, "2026-10-01T09:00:01Z GET /p%d %d %dms\n", i%7, 200+i%3, i%50)
	}
	want, err := tally.Count(strings.NewReader(log.String()))
	if err != nil {
		t.Fatal(err)
	}
	for _, shared := range []bool{false, true} {
		got, bad, err := count(context.Background(), strings.NewReader(log.String()), 4, shared)
		if err != nil || bad != 0 {
			t.Fatalf("shared=%t: %d bad lines, error %v", shared, bad, err)
		}
		if !reflect.DeepEqual(got, want) {
			t.Errorf("shared=%t: got %+v, want %+v", shared, got, want)
		}
	}
}
```

```
ana@vm:~/trace-hits$ go test -count=1 -trace=test.trace ./cmd/pcount
ok  	example.com/hits/cmd/pcount	0.027s
ana@vm:~/trace-hits$ stat -c "%s bytes  %n" test.trace
21214 bytes  test.trace
```

O arquivo vai para o diretório de onde o `go test` foi rodado, e cobre o binário de teste inteiro:
as duas chamadas a `count` estão nele, cada uma como sua própria tarefa `count`. **Um teste é o lugar
mais barato para gravar o trace de algo que já se reproduz**, porque a execução é curta, a entrada é
fixa e nada no programa muda para gravá-lo.
