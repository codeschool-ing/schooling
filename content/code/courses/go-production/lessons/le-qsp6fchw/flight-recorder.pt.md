---
title: O flight recorder
version: 1
---

Os incidentes que merecem um trace raramente são os que você consegue reproduzir. Uma requisição
que leva dois segundos uma vez por hora não vai acontecer enquanto você olha, e **gravar o trace de
um servidor durante a hora anterior custa gigabytes**: a seção 02 mediu de cinco a sete megabytes por
segundo para o `pcount`. Anotar tudo para o caso de algo dar errado é o formato errado.

Um flight recorder é o formato certo. **Ele guarda em memória o trecho mais recente do trace, joga
fora o que é mais antigo e não grava nada até o programa pedir.** Quando algo lento acontece, o
programa pede, e o snapshot traz os segundos que levaram até ali. Ele chegou no Go 1.25 como
`trace.FlightRecorder`:

| | |
|---|---|
| `trace.NewFlightRecorder(cfg)` | cria um; `cfg` é um `trace.FlightRecorderConfig` |
| `cfg.MinAge` | guardar pelo menos este tanto de trace recente; zero quer dizer alguns segundos |
| `cfg.MaxBytes` | guardar no máximo uns tantos bytes; prevalece sobre o `MinAge` |
| `fr.Start()`, `fr.Stop()` | começar e terminar a gravação na janela |
| `fr.WriteTo(w)` | copiar a janela para `w` e devolver quantos bytes |
| `fr.Enabled()` | se está gravando |

O `go doc runtime/trace.FlightRecorder` acrescenta os limites: só um flight recorder pode estar ativo
num programa, só um `WriteTo` roda por vez, e as duas configurações são sugestões, não garantias. Ele
pode rodar ao mesmo tempo que um `trace.Start`.

## Um programa que flagra o próprio lote lento

O programa conta o log numa goroutine só, em lotes de mil linhas, e cronometra cada lote, como um
servidor cronometraria uma requisição. Uma segunda goroutine divide as contagens e, a cada meio
segundo, segura o lock delas por tempo demais. Nada no laço de contagem sabe disso.
`cmd/flight/main.go`:

```schooling-example
{
  "language": "go",
  "file": "cmd/flight/main.go",
  "parts": [
    {
      "code": "// Command flight counts an access log in batches with the flight recorder\n// running, and writes out the last second of trace when a batch is slow.\npackage main\n\nimport (\n\t\"bufio\"\n\t\"context\"\n\t\"flag\"\n\t\"fmt\"\n\t\"os\"\n\t\"runtime/trace\"\n\t\"sync\"\n\t\"time\"\n\n\t\"example.com/hits/internal/tally\"\n)\n\nconst batchSize = 1000\n",
      "note": "Um terceiro programa no módulo, ao lado do `pcount`. Ele conta em lotes de mil linhas numa goroutine só e trata cada lote como um servidor trata uma requisição: o lote tem uma duração, e um lote lento merece explicação."
    },
    {
      "code": "func main() {\n\tos.Exit(run())\n}\n\nfunc run() int {\n\tslow := flag.Duration(\"slow\", 50*time.Millisecond, \"a batch slower than this writes a snapshot\")\n\tout := flag.String(\"o\", \"slow.trace\", \"the file the snapshot goes to\")\n\tflag.Parse()\n\tif flag.NArg() != 1 {\n\t\tfmt.Fprintln(os.Stderr, \"usage: flight [-slow d] [-o file] access.log\")\n\t\treturn 2\n\t}\n\tf, err := os.Open(flag.Arg(0))\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"flight:\", err)\n\t\treturn 1\n\t}\n\tdefer f.Close()\n",
      "note": "`-slow` é o limite: **um lote que demora mais do que isso é o incidente**. `-o` é para onde vai o snapshot."
    },
    {
      "code": "\tfr := trace.NewFlightRecorder(trace.FlightRecorderConfig{\n\t\tMinAge:   time.Second,\n\t\tMaxBytes: 16 << 20,\n\t})\n\tif err := fr.Start(); err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"flight:\", err)\n\t\treturn 1\n\t}\n\tdefer fr.Stop()\n",
      "note": "**O flight recorder mantém em memória uma janela móvel do trace e não grava nada até alguém pedir.** `MinAge` pede que ele guarde pelo menos o último segundo; `MaxBytes` limita a janela a 16 MiB e vence quando os dois discordam. Os dois são sugestões, como diz o `go doc`."
    },
    {
      "code": "\tvar mu sync.Mutex\n\ts := tally.Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}\n\tdone := make(chan struct{})\n\tdefer close(done)\n\tgo publish(&mu, &s, done)\n",
      "note": "As contagens são divididas com uma segunda goroutine, `publish`, por meio de um mutex. Essa goroutine é a causa dos lotes lentos, e nada no laço de contagem diz isso."
    },
    {
      "code": "\tctx := context.Background()\n\tvar batches int\n\tvar worst time.Duration\n\tsaved := false\n\tbatch := func(b []string) error {\n\t\tstart := time.Now()\n\t\ttrace.WithRegion(ctx, \"batch\", func() {\n\t\t\tmu.Lock()\n\t\t\tdefer mu.Unlock()\n\t\t\tfor _, line := range b {\n\t\t\t\tif e, err := tally.Parse(line); err == nil {\n\t\t\t\t\ts.Lines++\n\t\t\t\t\ts.ByPath[e.Path]++\n\t\t\t\t}\n\t\t\t}\n\t\t})",
      "note": "Um lote: pegar o lock, fazer o parse de mil linhas, soltar o lock, dentro de uma região `batch` para o trace mostrar onde cada um começa e termina. A duração inclui o tempo esperando pelo lock."
    },
    {
      "code": "\t\td := time.Since(start)\n\t\tbatches++\n\t\tworst = max(worst, d)\n\t\tif d <= *slow || saved {\n\t\t\treturn nil\n\t\t}\n\t\tsaved = true\n\t\ttrace.Logf(ctx, \"slow\", \"batch %d took %v\", batches, d)\n\t\tn, err := snapshot(fr, *out)\n\t\tif err != nil {\n\t\t\treturn err\n\t\t}\n\t\tfmt.Printf(\"batch %d took %v: wrote %d bytes to %s\\n\",\n\t\t\tbatches, d.Round(time.Millisecond), n, *out)\n\t\treturn nil\n\t}\n",
      "note": "**O primeiro lote lento tira o snapshot**, e só o primeiro: `WriteTo` copia a janela, e um arquivo basta para explicar o incidente. O `trace.Logf` entra logo antes, para o próprio snapshot dizer de qual lote ele foi tirado."
    },
    {
      "code": "\tsc := bufio.NewScanner(f)\n\tb := make([]string, 0, batchSize)\n\tfor sc.Scan() {\n\t\tb = append(b, sc.Text())\n\t\tif len(b) == batchSize {\n\t\t\tif err := batch(b); err != nil {\n\t\t\t\tfmt.Fprintln(os.Stderr, \"flight:\", err)\n\t\t\t\treturn 1\n\t\t\t}\n\t\t\tb = b[:0]\n\t\t}\n\t}\n\tif err := batch(b); err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"flight:\", err)\n\t\treturn 1\n\t}\n\tif err := sc.Err(); err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"flight:\", err)\n\t\treturn 1\n\t}\n\tfmt.Printf(\"%d lines in %d batches, the slowest %v\\n\",\n\t\ts.Lines, batches, worst.Round(time.Millisecond))\n\treturn 0\n}\n",
      "note": "O laço de leitura: juntar mil linhas, rodá-las como um lote, recomeçar. O último lote, menor, roda depois do laço."
    },
    {
      "code": "// snapshot writes the flight recorder's window to a new file.\nfunc snapshot(fr *trace.FlightRecorder, name string) (int64, error) {\n\tf, err := os.Create(name)\n\tif err != nil {\n\t\treturn 0, err\n\t}\n\tn, err := fr.WriteTo(f)\n\tif cerr := f.Close(); err == nil {\n\t\terr = cerr\n\t}\n\treturn n, err\n}\n",
      "note": "`WriteTo` devolve quantos bytes escreveu. Um erro do `Close` também é guardado, já que um snapshot cortado é um arquivo que o `go tool trace` não consegue ler."
    },
    {
      "code": "// publish takes the lock every half second to read the top paths.\n// The sleep stands for a slow write of them, made while still holding it.\nfunc publish(mu *sync.Mutex, s *tally.Summary, done <-chan struct{}) {\n\ttick := time.NewTicker(500 * time.Millisecond)\n\tdefer tick.Stop()\n\tfor {\n\t\tselect {\n\t\tcase <-done:\n\t\t\treturn\n\t\tcase <-tick.C:\n\t\t\tmu.Lock()\n\t\t\t_ = tally.Top(*s, 3)\n\t\t\ttime.Sleep(100 * time.Millisecond)\n\t\t\tmu.Unlock()\n\t\t}\n\t}\n}",
      "note": "**O culpado**, escrito de propósito: a cada 500 ms ele segura o lock por 100 ms. Um lote que precisa do lock nessa janela espera por ele, e a duração dele só diz que foi lento."
    }
  ]
}
```

Compilado e rodado com o limite padrão de 50 ms:

```
ana@vm:~/trace-hits$ go build -o flight ./cmd/flight && ./flight big.log
batch 1594 took 100ms: wrote 1606654 bytes to slow.trace
3000000 lines in 3001 batches, the slowest 101ms
```

Um lote normal leva bem menos de um milissegundo, e **o lote 1.594 levou 100ms**, que são os 100ms em
que o `publish` segura o lock. O programa percebeu, gravou um snapshot de 1.606.654 bytes e seguiu
até o fim. Até onde o snapshot volta no tempo é assunto da configuração: pelo menos o último
segundo, como o `MinAge` pediu, e nunca muito mais que 16 MiB.

## Lendo o snapshot

O snapshot é um arquivo de trace comum, e todas as ferramentas desta lição o leem. A mensagem que o
`trace.Logf` deixou logo antes de tirá-lo está lá dentro, e é assim que você distingue um snapshot de
outro uma semana depois:

```
ana@vm:~/trace-hits$ go tool trace -d=parsed slow.trace | grep 'Category="slow"'
M=20599 P=0 G=1 Log Time=900271165120 Task=0 Category="slow" Message="batch 1594 took 100.38373ms"
```

E a pergunta que a duração do lote não respondia, o que ele fazia naqueles 100ms:

```
ana@vm:~/trace-hits$ go tool trace -pprof=sync slow.trace > slow.pprof && go tool pprof -top -focus=Mutex slow.pprof
Main binary filename not available.
Type: delay
Active filters:
   focus=Mutex
Showing nodes accounting for 100.89ms, 7.78% of 1296.33ms total
      flat  flat%   sum%        cum   cum%
  100.89ms  7.78%  7.78%   100.89ms  7.78%  sync.(*Mutex).Lock
         0     0%  7.78%   100.16ms  7.73%  main.main
         0     0%  7.78%     0.74ms 0.057%  main.publish
         0     0%  7.78%   100.16ms  7.73%  main.run
         0     0%  7.78%   100.16ms  7.73%  main.run.func1
         0     0%  7.78%   100.16ms  7.73%  main.run.func1.1
         0     0%  7.78%   100.16ms  7.73%  runtime/trace.WithRegion
```

**100,89ms bloqueado em `sync.(*Mutex).Lock`**, que é o lote lento inteiro. O lote não foi lento no
parse; ele estava esperando um lock, e neste programa só uma outra goroutine pega esse lock. No
`go tool trace slow.trace`, as regiões `batch` da página User-defined regions colocam aquele lote de
100ms ao lado de três mil lotes rápidos. A causa apareceu sem ninguém reproduzir o incidente.

Um limite acima da trava não tira snapshot nenhum, que é a outra metade do contrato:

```
ana@vm:~/trace-hits$ ./flight -slow 200ms -o none.trace big.log; ls none.trace
3000000 lines in 3001 batches, the slowest 101ms
ls: cannot access 'none.trace': No such file or directory
```

## Usando num programa de verdade

**O limite é uma afirmação sobre o que conta como incidente**, e ele precisa ficar acima do ruído
normal. Baixo demais, ele flagra qualquer outra coisa que tenha atrasado um lote, uma máquina
ocupada por exemplo, e o snapshot passa a explicar isso. Num servidor, o gatilho comum é uma
requisição mais lenta que algum múltiplo da latência normal, ou um erro que não deveria acontecer.
Duas escolhas a mais saem da API:

- **Tire um snapshot por incidente e espere.** O `flight` para depois do primeiro. Um servidor
  permitiria um a cada poucos minutos; o `WriteTo` se recusa a rodar duas vezes ao mesmo tempo de
  qualquer jeito, e cem snapshots da mesma trava não explicam nada além do que um explica.
- **O recorder custa o que o trace custa, o tempo todo.** Ele mantém o tracer do runtime ligado do
  `Start` ao `Stop`, e só a gravação espera pelo `WriteTo`. A seção 02 não conseguiu ver esse custo
  através do ruído de uma máquina ocupada; na máquina que importa para você, meça antes de deixá-lo
  ligado.
