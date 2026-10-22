---
title: O escalonador que as roda
version: 1
---

Alguma coisa tem de decidir qual de cem mil goroutines roda em qual de quatro processadores. Na
maioria das linguagens isso é tarefa do sistema operacional, feita thread por thread. **Em Go é
tarefa do runtime: um escalonador compilado dentro de todo programa, que distribui muitas goroutines
por poucas threads.** O sistema operacional só vê as threads.

Ele trabalha com três tipos de coisa, chamados por uma letra só no código-fonte do runtime:

- **G** é uma goroutine: a pilha dela, e até onde ela tinha chegado.
- **M** é uma máquina, a palavra do runtime para uma thread do sistema operacional.
- **P** é um processador, uma licença para rodar código Go. Há exatamente `GOMAXPROCS` deles, e um
  M precisa segurar um P para rodar um G.

Cada P mantém uma fila de goroutines prontas para rodar, e existe uma fila global além delas. Um M
com um P pega o próximo G da fila do seu P; quando essa fila está vazia, pega da fila global, ou
**rouba metade da fila de outro P**, para que nenhum processador fique parado enquanto outro está
atrasado. Quando uma goroutine bloqueia numa chamada de sistema, o M dela bloqueia junto, e o P passa
para outro M, para as outras goroutines continuarem rodando. É por isso que um programa Go tem
algumas threads a mais do que processadores.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O escalonador de Go no momento do trace de 505 milissegundos. Quatro Ps, de P0 a P3, cada um seguro por uma thread, de M0 a M3, e cada um rodando uma goroutine. Duas goroutines esperam na fila global, e P0 e P3 têm mais uma cada na fila local. Uma quinta thread, M4, não segura P nenhum e espera. O sistema operacional só vê as cinco threads.\"><rect x=\"250\" y=\"14\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fila global</text><rect x=\"318\" y=\"33\" width=\"36\" height=\"16\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"336\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">G</text><rect x=\"366\" y=\"33\" width=\"36\" height=\"16\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"384\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">G</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">threads: tudo o que o sistema operacional vê</text><rect x=\"30\" y=\"96\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">M0</text><path d=\"M90 122 V140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"30\" y=\"140\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">P0</text><rect x=\"60\" y=\"184\" width=\"60\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">G</text><text x=\"90\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rodando</text><rect x=\"30\" y=\"238\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"90\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fila local</text><rect x=\"72\" y=\"262\" width=\"36\" height=\"16\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">G</text><rect x=\"190\" y=\"96\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">M1</text><path d=\"M250 122 V140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"190\" y=\"140\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">P1</text><rect x=\"220\" y=\"184\" width=\"60\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"250\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">G</text><text x=\"250\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rodando</text><rect x=\"190\" y=\"238\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"250\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fila local</text><rect x=\"350\" y=\"96\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">M2</text><path d=\"M410 122 V140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"350\" y=\"140\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">P2</text><rect x=\"380\" y=\"184\" width=\"60\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"410\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">G</text><text x=\"410\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rodando</text><rect x=\"350\" y=\"238\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"410\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fila local</text><rect x=\"510\" y=\"96\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">M3</text><path d=\"M570 122 V140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"510\" y=\"140\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">P3</text><rect x=\"540\" y=\"184\" width=\"60\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"570\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">G</text><text x=\"570\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rodando</text><rect x=\"510\" y=\"238\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"570\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fila local</text><rect x=\"552\" y=\"262\" width=\"36\" height=\"16\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"570\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">G</text><rect x=\"650\" y=\"96\" width=\"50\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"675\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">M4</text><text x=\"675\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sobra, sem P</text><path d=\"M20 90 H705\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"360\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">GOMAXPROCS=4</text></svg>", "caption": "Oito goroutines em quatro Ps e cinco threads, como a linha do schedtrace de 505ms as contou.", "same": ["GOMAXPROCS=4"]}
```

O runtime descreve isso enquanto acontece. `GODEBUG=schedtrace=500` faz ele imprimir uma linha
sobre o escalonador a cada 500 milissegundos.

O programa em que isso é medido mantém oito goroutines calculando por um segundo e meio, o dobro dos
processadores do laboratório, salvo como `busy.go`:

```go
// Command busy keeps eight goroutines computing for a second and a half.
package main

import (
	"sync"
	"time"
)

func main() {
	stop := time.Now().Add(1500 * time.Millisecond)
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			for time.Now().Before(stop) {
			}
		})
	}
	wg.Wait()
}
```

```
ana@vm:~/goroutines$ go build -o busy busy.go
ana@vm:~/goroutines$ GODEBUG=schedtrace=500 ./busy
SCHED 0ms: gomaxprocs=4 idleprocs=2 threads=5 spinningthreads=1 needspinning=0 idlethreads=2 runqueue=0 [ 0 0 0 0 ] schedticks=[ 1 0 0 2 ]
SCHED 505ms: gomaxprocs=4 idleprocs=0 threads=5 spinningthreads=0 needspinning=1 idlethreads=0 runqueue=2 [ 1 0 0 1 ] schedticks=[ 22 21 22 24 ]
SCHED 1011ms: gomaxprocs=4 idleprocs=0 threads=5 spinningthreads=0 needspinning=1 idlethreads=0 runqueue=2 [ 1 1 0 0 ] schedticks=[ 44 44 44 46 ]
```

Leia a linha de 505ms da esquerda para a direita. `gomaxprocs=4` são os quatro Ps, e
`idleprocs=0` diz que todos estão ocupados. `threads=5` são os Ms: quatro rodando código Go e uma de
sobra, para oito goroutines. `runqueue=2` é a fila global, e `[ 1 0 0 1 ]` são as quatro filas
locais, um número por P. Dois mais um mais um dá quatro goroutines esperando, e com as quatro
rodando são as oito. Em 1011ms as que esperam estão em outros Ps, porque o escalonador as moveu.
`schedticks` conta quantas vezes cada P escolheu uma goroutine, e os quatro números andam juntos: o
trabalho foi dividido por igual. A primeira linha, em 0ms, pegou o programa antes de a maioria das
goroutines começar.

**Oito goroutines rodaram em cinco threads**, e cem mil teriam rodado em quase tão poucas.

## Um laço que nunca chama nada

Um escalonador tem de tomar o processador de volta de uma goroutine que não o devolve. Este programa
pede um processador, inicia uma goroutine que repete um laço para sempre sem chamar função nenhuma,
e depois faz `main` dormir e imprimir, salvo como `hog.go`:

```go
// Command hog runs a loop that never calls a function, on one processor.
package main

import (
	"fmt"
	"runtime"
	"time"
)

func main() {
	runtime.GOMAXPROCS(1)
	go func() {
		for {
		}
	}()
	time.Sleep(100 * time.Millisecond)
	fmt.Println("main got the processor back")
}
```

```
ana@vm:~/goroutines$ go build -o hog hog.go
ana@vm:~/goroutines$ ./hog
main got the processor back
ana@vm:~/goroutines$ GODEBUG=asyncpreemptoff=1 timeout 3 ./hog; echo "exit status: $?"
exit status: 124
```

Com as configurações padrão `main` imprimiu a sua linha: depois de 100 milissegundos o runtime
interrompeu a goroutine do laço, deu o único processador a `main`, e o programa terminou. Desde o
Go 1.14 o escalonador **preempta** uma goroutine que rodou por uns dez milissegundos, mandando um
sinal à thread dela, mesmo num laço sem chamada de função nenhuma.

`GODEBUG=asyncpreemptoff=1` desliga esse sinal, e sobra só o tipo mais antigo de preempção, o que
acontece numa chamada de função. O laço não chama nada, então nunca chega a uma, `main` nunca mais
roda, e o `timeout` teve de matar o programa depois de três segundos: o status de saída 124 é o
`timeout` informando que fez isso. Versões mais antigas de Go se comportavam como a segunda execução.

**Você não vai escrever `for {}` de propósito**, e nunca precisa de `Gosched` nem de uma chamada para
ceder a vez. O que o experimento mostra é que nenhuma goroutine consegue impedir as outras de rodar,
por pior que se comporte, e que a ordem em que elas ganham a vez é escolha do escalonador, nunca do
programa.
