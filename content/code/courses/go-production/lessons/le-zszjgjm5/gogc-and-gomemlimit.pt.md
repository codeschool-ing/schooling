---
title: GOGC e GOMEMLIMIT, medidos
version: 1
---

Os dois ajustes são fáceis de mudar, e os dois costumam ser mudados pelo motivo errado. **`GOGC`
decide quanto o heap pode crescer além do que sobreviveu ao último ciclo; `GOMEMLIMIT` põe um teto
em toda a memória que o runtime segura.** A lição 24 do curso `go` apresentou os dois e os mediu num
programa pequeno. Esta seção os mede num programa com um heap vivo grande, lê a aritmética do pacer
num trace, e termina no caso em que um limite piora muito as coisas.

## Um programa que guarda o que lê

O `hits count` não guarda nada, e por isso a seção 03 viu o `GOGC` decidir muito pouco para ele.
Algumas perguntas precisam de todas as linhas ao mesmo tempo: o percentil 99 das durações, por
exemplo, precisa delas todas ordenadas. Um pacote pequeno em `~/mem-hits` carrega um log inteiro,
construído sobre o `tally.Parse` da lição 1. Salve-o como `internal/keep/keep.go`:

```go
// Package keep holds a whole access log in memory, for the questions that
// need every line at once.
package keep

import (
	"bufio"
	"cmp"
	"fmt"
	"io"
	"slices"

	"example.com/hits/internal/tally"
)

// Load parses every line of r. hint is how many lines the caller expects,
// and 0 means it does not know.
func Load(r io.Reader, hint int) ([]tally.Entry, error) {
	entries := make([]tally.Entry, 0, hint)
	sc := bufio.NewScanner(r)
	for n := 1; sc.Scan(); n++ {
		e, err := tally.Parse(sc.Text())
		if err != nil {
			return nil, fmt.Errorf("line %d: %w", n, err)
		}
		entries = append(entries, e)
	}
	return entries, sc.Err()
}

// BySlowest sorts entries in place, the slowest first.
func BySlowest(entries []tally.Entry) {
	slices.SortFunc(entries, func(a, b tally.Entry) int {
		return cmp.Compare(b.Duration, a.Duration)
	})
}
```

E um comando que o usa:

```schooling-example
{
  "language": "go",
  "file": "cmd/slowest/main.go",
  "parts": [
    {
      "code": "// Command slowest reads a whole access log into memory and prints the 99th\n// percentile of its durations, then what that cost the garbage collector.\npackage main\n\nimport (\n\t\"bufio\"\n\t\"flag\"\n\t\"fmt\"\n\t\"os\"\n\t\"runtime/metrics\"\n\t\"strings\"\n\t\"time\"\n\n\t\"example.com/hits/internal/keep\"\n)\n",
      "note": "Um segundo comando no mesmo módulo, em `cmd/slowest`. Ele importa o `keep`, e por meio dele o `tally` da lição 1."
    },
    {
      "code": "func main() {\n\thint := flag.Int(\"hint\", 0, \"how many lines to expect (0: unknown)\")\n\tflag.Parse()\n\tif flag.NArg() != 1 {\n\t\tfmt.Fprintln(os.Stderr, \"usage: slowest [-hint lines] file\")\n\t\tos.Exit(2)\n\t}\n\tf, err := os.Open(flag.Arg(0))\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, err)\n\t\tos.Exit(1)\n\t}\n\tdefer f.Close()\n",
      "note": "`-hint` vai direto para o `keep.Load`. Fica em 0 até a seção 06, que mede quanto ele vale."
    },
    {
      "code": "\tstart := time.Now()\n\tentries, err := keep.Load(f, *hint)\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, err)\n\t\tos.Exit(1)\n\t}\n\tkeep.BySlowest(entries)\n\tfmt.Printf(\"%d requests, p99 %v, slowest %v\\n\",\n\t\tlen(entries), entries[len(entries)/100].Duration, entries[0].Duration)\n",
      "note": "**O trabalho: cada linha interpretada e guardada, depois ordenada.** O percentil 99 é a duração a um centésimo do caminho na lista ordenada; 1% das requisições levou mais que isso."
    },
    {
      "code": "\ts := []metrics.Sample{{Name: \"/gc/cycles/total:gc-cycles\"}}\n\tmetrics.Read(s)\n\tfmt.Printf(\"%v, %d collections, peak %s\\n\",\n\t\ttime.Since(start).Round(time.Millisecond), s[0].Value.Uint64(), peak())\n}\n",
      "note": "Depois, o que isso custou: o tempo de relógio, o número de coletas que o runtime contou e o pico de memória."
    },
    {
      "code": "// peak is the most memory the process has held at once, as Linux counts it.\nfunc peak() string {\n\tf, err := os.Open(\"/proc/self/status\")\n\tif err != nil {\n\t\treturn \"unknown\"\n\t}\n\tdefer f.Close()\n\tsc := bufio.NewScanner(f)\n\tfor sc.Scan() {\n\t\tif v, ok := strings.CutPrefix(sc.Text(), \"VmHWM:\"); ok {\n\t\t\treturn strings.TrimSpace(v)\n\t\t}\n\t}\n\treturn \"unknown\"\n}",
      "note": "**`VmHWM` é a marca máxima que o kernel registra** para a memória residente do processo, lida em `/proc/self/status`. Ela conta tudo o que o processo já teve na memória de uma vez, não só o que o runtime chama de heap, e por isso é o número que o limite de memória de um contêiner usaria na comparação."
    }
  ]
}
```

Compilado, e rodado sobre as dois milhões de linhas da seção 03:

```
ana@vm:~/mem-hits$ go build -o slowest ./cmd/slowest && ./slowest big.log
2000000 requests, p99 396ms, slowest 400ms
1.73s, 20 collections, peak 616320 kB
```

1% das requisições levou 396 ms ou mais e a mais lenta levou 400, que é o teto do `genlog`. **Vinte
coletas em 1,73 segundo, e um pico de 616.320 kB**, uns 600 MiB, para um arquivo de 91 MB. Cada
linha é guardada duas vezes: a `Entry`, e o texto da linha, para dentro do qual as strings `Method` e
`Path` ainda apontam, o efeito que a lição 24 do curso `go` mostrou com uma substring de 16 bytes.

## A aritmética do pacer

Duas linhas seguidas do trace, da parte da execução em que o heap está crescendo:

```
ana@vm:~/mem-hits$ GODEBUG=gctrace=1 ./slowest big.log 2>&1 | grep -E "^gc 1[45] "
gc 14 @0.306s 6%: 0.018+12+1.9 ms clock, 0.073+0/11/13+7.7 ms cpu, 98->98->92 MB, 107 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 15 @0.385s 5%: 0.13+23+0.031 ms clock, 0.52+0/18/41+0.12 ms cpu, 156->158->79 MB, 184 MB goal, 0 MB stacks, 0 MB globals, 4 P
ana@vm:~/mem-hits$ sed -n 1295p /usr/local/go/src/runtime/mgcpacer.go
		gcPercentHeapGoal = c.heapMarked + (c.heapMarked+c.lastStackScan.Load()+c.globalsScan.Load())*uint64(gcPercent)/100
```

**A meta de cada ciclo é fixada pelo anterior.** O `gc 14` achou 92 MB vivos, e o `gc 15` mirou
terminar abaixo de 184 MB, o dobro. A linha do `mgcpacer.go` é a regra inteira: o heap marcado como
vivo, mais esse heap e as pilhas e variáveis de pacote escaneadas multiplicados por `GOGC` sobre 100.
Pilhas e globais dão 0 MB aqui, então a meta é 92 + 92 × 100/100. Um programa com cem mil goroutines
profundas veria as pilhas aumentarem a meta também, e por isso o trace as informa.

O `gc 15` também começou em 156 MB, bem antes da meta: o runtime inicia um ciclo cedo o bastante
para a marcação terminar antes de o heap chegar à meta, julgando pelo jeito como o ciclo anterior
correu. Os seus 23 ms de marcação rodaram ao lado do programa.

## O GOGC na mesa

O mesmo binário sob cinco ajustes, a última linha do programa em cada um:

```
ana@vm:~/mem-hits$ for g in 50 100 200 400 off; do echo "GOGC=$g: $(GOGC=$g ./slowest big.log | tail -1)"; done
GOGC=50: 1.852s, 25 collections, peak 518160 kB
GOGC=100: 1.598s, 15 collections, peak 682448 kB
GOGC=200: 1.52s, 9 collections, peak 577992 kB
GOGC=400: 1.417s, 5 collections, peak 746924 kB
GOGC=off: 1.287s, 0 collections, peak 1016500 kB
```

Leia as colunas separadamente, porque elas não andam juntas.

- As coletas caem com limpeza: 25, 15, 9, 5, 0. Dobrar o `GOGC` corta-as mais ou menos pela
  metade, porque cada ciclo deixa o heap crescer o dobro.
- O tempo cai um pouco: de 1,85 para 1,29 segundo, do início ao fim, em quatro processadores
  onde a maior parte da marcação rodou em paralelo com o programa.
- O pico não acompanha o ajuste entre 50 e 400: 518.160 kB, depois 682.448, 577.992 e 746.924.
  Só o `off` se destaca, com 1.016.500 kB, tudo o que o programa alocou na vida.

O pico é ruidoso porque **as maiores alocações deste programa são dele mesmo**. O `Load` faz a fatia
crescer com `append`, e cada vez que o array enche, um maior é alocado ao lado e o conteúdo antigo é
copiado. Perto do fim os dois arrays existem ao mesmo tempo, e onde um ciclo cai em relação a esse
momento decide o pico mais do que o `GOGC`. A seção 06 remove essas cópias e o pico cai um terço. Um
botão no coletor não conserta memória que o próprio programa pede.

O que o `off` compra aparece melhor no tempo de processador:

```
ana@vm:~/mem-hits$ time ./slowest big.log > /dev/null

real	0m1.609s
user	0m1.256s
sys	0m0.550s
ana@vm:~/mem-hits$ time GOGC=off ./slowest big.log > /dev/null

real	0m1.393s
user	0m0.739s
sys	0m0.596s
```

**Sem coleta, o programa usou 0,74 segundo de tempo de usuário em vez de 1,26**, a marcação que ele
deixou de fazer. O relógio andou só de 1,61 para 1,39 segundo, porque essa marcação vinha
rodando em processadores que estariam ociosos. Numa máquina com processadores e memória sobrando, um
`GOGC` maior sai quase de graça. Numa ocupada, ou pequena, esses 0,5 segundo de processador são
tirados de outra coisa.

## GOMEMLIMIT: um teto, e onde ele deixa de ajudar

O limite de memória de um contêiner é um número de bytes; o `GOGC` é uma proporção, e não sabe nada
do contêiner. **O runtime não procura esse limite por conta própria.** Ele lê a cota de processador
do contêiner, para definir o `GOMAXPROCS`, e essa é a única coisa que o seu código de control groups
lê:

```
ana@vm:~/mem-hits$ grep -n "^func" /usr/local/go/src/runtime/cgroup_linux.go
45:func defaultGOMAXPROCSInit() {
75:func defaultGOMAXPROCSUpdateGODEBUG() {
85:func defaultGOMAXPROCS(ncpu int32) int32 {
109:func adjustCgroupGOMAXPROCS(procs int32, cpu cgroup.CPU) int32 {
```

Então o limite precisa ser passado, e o padrão útil para um programa sozinho num contêiner de tamanho
conhecido é desligar a regra proporcional e deixar só o limite disparar coletas:

```
ana@vm:~/mem-hits$ GOGC=off GOMEMLIMIT=400MiB ./slowest big.log
2000000 requests, p99 396ms, slowest 400ms
1.639s, 3 collections, peak 464288 kB
```

**Três coletas em vez de vinte, e um pico de 464.288 kB**, que são 453 MiB, acima do limite de
400 MiB. Duas coisas permitem isso, e um contêiner precisa de margem para as duas. O limite é
flexível: ele faz o runtime coletar com mais força, e não consegue liberar memória que o programa
ainda usa. E ele conta o que o runtime administra, não tudo o que o Linux conta como residente: a
documentação de `runtime/debug.SetMemoryLimit` lista o que fica de fora, o próprio binário e a
memória que código C ou o kernel seguram para o processo entre eles.

Agora o outro sentido: um limite de 100 MiB, bem abaixo do que este programa mantém vivo, como o
trace vai mostrar:

```
ana@vm:~/mem-hits$ GOMEMLIMIT=100MiB ./slowest big.log
2000000 requests, p99 396ms, slowest 400ms
3.13s, 66 collections, peak 343024 kB
ana@vm:~/mem-hits$ GOMEMLIMIT=100MiB GODEBUG=gctrace=1 ./slowest big.log 2>&1 | grep -E "^gc 3[89] "
gc 38 @1.530s 18%: 0.11+41+0.037 ms clock, 0.45+0/36/68+0.14 ms cpu, 161->164->162 MB, 161 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 39 @1.578s 18%: 0.34+66+0.036 ms clock, 1.3+7.0/58/115+0.14 ms cpu, 162->168->166 MB, 162 MB goal, 0 MB stacks, 0 MB globals, 4 P
```

**Sessenta e seis coletas e 3,13 segundos, contra vinte e 1,73.** As duas linhas do trace mostram o
motivo. `161->164->162 MB, 161 MB goal`: o ciclo começou na meta, marcou, e achou 162 MB vivos dos
164. Não liberou nada que valesse, o heap já passou do limite, então a próxima meta é o heap como
está, e o próximo ciclo começa quase em seguida. O `gc 38` e o `gc 39` começaram com 48 ms de
diferença. O `18%` é a fatia da execução inteira gasta coletando; a execução sem limite imprimiu 6% e
5% com um heap de tamanho parecido.

Sem um freio, esse laço é uma **espiral da morte**: quanto mais o heap vivo se aproxima do limite,
mais vezes o coletor roda, até tomar todos os processadores e o programa não avançar mais nada. O
runtime tem um freio exatamente para isso:

```
ana@vm:~/mem-hits$ sed -n 9,14p /usr/local/go/src/runtime/mgclimit.go
// gcCPULimiter is a mechanism to limit GC CPU utilization in situations
// where it might become excessive and inhibit application progress (e.g.
// a death spiral).
//
// The core of the limiter is a leaky bucket mechanism that fills with GC
// CPU time and drains with mutator time. Because the bucket fills and
```

O resto desse comentário explica que a aritmética do balde equivale a um limite de 50%: além dele, o
coletor é contido e o heap pode passar do limite. **O programa terminou, devagar, e é isso que
flexível quer dizer**, um resultado melhor do que um processo encerrado por usar memória demais. Mas
continua sendo um programa rodando a meia velocidade sem que ninguém saiba por quê, e uma linha de
`gctrace` em que início, fim, heap vivo e meta são todos o mesmo número é o sinal a procurar.

## Definindo-os de dentro do programa

As variáveis de ambiente são o jeito de um operador escolher; o `runtime/debug` tem uma função para
cada uma, para um programa que escolhe por si. As duas devolvem o valor antigo, o que também as
torna úteis para ler. Em `~/mem-knobs`, `main.go`:

```go
// Command knobs reads the collector's two settings from inside a program,
// and changes one of them.
package main

import (
	"fmt"
	"runtime/debug"
)

func main() {
	old := debug.SetGCPercent(200)
	fmt.Printf("GOGC was %d, and is now 200\n", old)
	limit := debug.SetMemoryLimit(-1) // a negative value changes nothing
	fmt.Printf("the memory limit is %d bytes\n", limit)
}
```

```
ana@vm:~/mem-knobs$ go run .
GOGC was 100, and is now 200
the memory limit is 9223372036854775807 bytes
ana@vm:~/mem-knobs$ GOGC=off GOMEMLIMIT=512MiB go run .
GOGC was -1, and is now 200
the memory limit is 536870912 bytes
```

`GOGC=off` volta como -1, que é também o que `SetGCPercent(-1)` define. **Sem limite informado, o
limite é de 9.223.372.036.854.775.807 bytes, `math.MaxInt64`**, o jeito do runtime de dizer que não
há nenhum, e `512MiB` é lido como 536.870.912 bytes, em potências de dois, como a documentação
promete.

## Quando mexer neles

Raramente, e com um número na mão. Um ajuste mudado porque um post de blog mandou custa memória ou
processador numa direção que ninguém mediu.

| situação | o que os números dizem | o que fazer |
|---|---|---|
| uma CLI como o `hits count` | `#%` entre 0 e 1%, heap vivo perto de 0 | nada: não há o que ganhar |
| um contêiner com limite rígido de memória | o processo é encerrado perto do limite | definir `GOMEMLIMIT` com uma margem abaixo dele, talvez com `GOGC=off` |
| memória sobrando, processadores ocupados | `#%` alto, heap vivo bem abaixo da máquina | aumentar o `GOGC`, e medir o pico |
| a memória é a restrição | pico alto demais, `#%` baixo | baixar o `GOGC`, ou manter menos coisa viva |
| o heap é quase todo crescimento do próprio programa | pico ruidoso seja qual for o `GOGC` | mudar o programa: seção 06 |

A primeira coluna de uma linha de `gctrace` que importa é o `#%`, e a segunda é o heap vivo. Se a
primeira é pequena, nenhum ajuste vai deixar o programa visivelmente mais rápido, e se o limite está
abaixo da segunda, nenhum ajuste vai deixá-lo menor.
