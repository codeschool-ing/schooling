---
title: Duas palavras que não são uma só
version: 1
---

Quase todo mundo chega a este assunto com uma ideia só sob dois nomes: concorrência é fazer várias
coisas no mesmo instante, e paralelismo também. **As duas palavras dão nome a coisas diferentes, e
o projeto inteiro de Go se apoia nessa diferença.** Rob Pike, um dos criadores de Go, resumiu numa
linha: concorrência é *lidar* com muitas coisas ao mesmo tempo, paralelismo é *fazer* muitas
coisas ao mesmo tempo.

- **Concorrência é uma propriedade do programa.** Ele é escrito como várias atividades
  independentes, cada uma capaz de avançar sem esperar as outras. Em Go cada atividade é uma
  goroutine, o assunto da lição 2.
- **Paralelismo é uma propriedade de uma execução.** É saber se, num dado instante, mais de uma
  dessas atividades está de fato executando, em mais de um processador.

Um programa concorrente pode rodar sem paralelismo nenhum, num processador só, revezando. Um
programa sem concorrência nenhuma não roda em paralelo, por mais processadores que a máquina tenha.
**Você escreve a concorrência; a máquina e o runtime decidem quanto paralelismo você ganha.**

## O mesmo programa, três execuções

A demonstração é um programa de quatro goroutines que fazem a mesma conta e não compartilham nada.
Ele aparece em partes, salvo como `spin.go`:

```schooling-example
{"language": "go", "file": "spin.go", "parts": [{"code": "// Command spin runs four equal pieces of arithmetic at once and times them.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"runtime\"\n\t\"sync\"\n\t\"time\"\n)\n\n", "note": "Só a biblioteca padrão, como tudo neste curso. `runtime` é o pacote que responde perguntas sobre a própria execução do programa."}, {"code": "// work keeps one processor busy for a while and touches nothing shared.\nfunc work() uint64 {\n\tvar x uint64\n\tfor range 500_000_000 {\n\t\tx = x*6364136223846793005 + 1\n\t}\n\treturn x\n}\n\n", "note": "**Meio bilhão de multiplicações, cada uma dependendo da anterior.** Nenhum passo pode ser pulado e nada espera um disco ou uma rede, então a única coisa que deixa isso mais rápido é um processador só para ela."}, {"code": "var sink [4]uint64\n\n", "note": "Cada goroutine escreve o resultado numa posição só dela. Guardar o resultado dá uma utilidade à conta, e quatro posições separadas significam que nada é compartilhado entre as goroutines."}, {"code": "func main() {\n\tstart := time.Now()\n\tvar wg sync.WaitGroup\n\tfor i := range 4 {\n\t\twg.Go(func() { sink[i] = work() })\n\t}\n\twg.Wait()\n", "note": "**Este laço é a concorrência, e ele é o mesmo em toda execução.** Quatro chamadas de `work`, cada uma iniciada como goroutine por `wg.Go`, e depois `wg.Wait` até as quatro retornarem."}, {"code": "\tfmt.Printf(\"GOMAXPROCS=%d: four tasks took %v\\n\",\n\t\truntime.GOMAXPROCS(0), time.Since(start).Round(10*time.Millisecond))\n}\n", "note": "`runtime.GOMAXPROCS(0)` informa uma configuração sem mudá-la: quantas goroutines podem executar código Go no mesmo instante. Esse número é o paralelismo."}]}
```

`GOMAXPROCS` tem como padrão o número de processadores que o programa pode usar, e uma variável de
ambiente com o mesmo nome o substitui numa execução. Então o programa nunca muda, e o paralelismo
que ele recebe muda:

```
ana@vm:~/promise$ nproc
4
ana@vm:~/promise$ go build -o spin spin.go
ana@vm:~/promise$ ./spin
GOMAXPROCS=4: four tasks took 400ms
ana@vm:~/promise$ GOMAXPROCS=1 ./spin
GOMAXPROCS=1: four tasks took 1.57s
ana@vm:~/promise$ GOMAXPROCS=2 ./spin
GOMAXPROCS=2: four tasks took 800ms
```

O laboratório tem quatro processadores, e a conta custou cerca de 400 milissegundos por tarefa.
**Com um processador as quatro revezaram, e o total fica perto de quatro vezes uma tarefa**: 1,57
segundo. Dois processadores cortaram isso pela metade, para 800 milissegundos, e quatro desceram
para 400. Nada no código-fonte mudou; só o número de faixas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"As mesmas quatro tarefas, de A a D, rodadas duas vezes. Com um processador elas se revezam em fatias curtas numa faixa só, e as quatro terminam depois de cerca de 1,6 segundo. Com quatro processadores cada tarefa tem uma faixa própria e as quatro terminam depois de cerca de 0,4 segundo. O programa é o mesmo; só o paralelismo mudou.\"><defs><marker id=\"l01turns-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um processador: as quatro se revezam</text><text x=\"60\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">P1</text><rect x=\"110.0\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"127.1\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">A</text><rect x=\"146.2\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"163.4\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">B</text><rect x=\"182.5\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"199.6\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">C</text><rect x=\"218.8\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"235.9\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">D</text><rect x=\"255.0\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"272.1\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">A</text><rect x=\"291.2\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"308.4\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">B</text><rect x=\"327.5\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"344.6\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">C</text><rect x=\"363.8\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"380.9\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">D</text><rect x=\"400.0\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"417.1\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">A</text><rect x=\"436.2\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"453.4\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">B</text><rect x=\"472.5\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"489.6\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">C</text><rect x=\"508.7\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"525.9\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">D</text><rect x=\"545.0\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"562.1\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">A</text><rect x=\"581.2\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"598.4\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">B</text><rect x=\"617.5\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"634.6\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">C</text><rect x=\"653.8\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"670.9\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">D</text><text x=\"110\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quatro processadores: as quatro rodam juntas</text><text x=\"60\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">P1</text><rect x=\"110\" y=\"128\" width=\"143.0\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"182.5\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">A</text><text x=\"60\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">P2</text><rect x=\"110\" y=\"160\" width=\"143.0\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"182.5\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">B</text><text x=\"60\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">P3</text><rect x=\"110\" y=\"192\" width=\"143.0\" height=\"26\" rx=\"2\" fill=\"var(--paper)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"182.5\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">C</text><text x=\"60\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">P4</text><rect x=\"110\" y=\"224\" width=\"143.0\" height=\"26\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"182.5\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">D</text><path d=\"M110 268 H700\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01turns-paper-dim)\"></path><path d=\"M110.0 263 V273\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M255.0 263 V273\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"255.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,4 s</text><path d=\"M400.0 263 V273\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"400.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,8 s</text><path d=\"M545.0 263 V273\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"545.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,2 s</text><path d=\"M690.0 263 V273\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"690.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,6 s</text><text x=\"60\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tempo</text><path d=\"M255.0 120 V258\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path></svg>", "caption": "O spin.go duas vezes: a concorrência são as quatro tarefas; o paralelismo é quantas faixas a execução recebeu."}
```

## Concorrência sem paralelismo ainda compensa

Se o paralelismo fosse a única recompensa, um programa concorrente num processador só não teria
sentido. Ele tem, porque a maioria dos programas reais passa o tempo esperando: um disco, um banco
de dados, um servidor em outro continente. Uma goroutine que espera não precisa de processador
nenhum. Aqui as quatro tarefas esperam um segundo cada uma em vez de calcular, salvo como
`wait.go`:

```go
// Command wait starts four tasks that each wait one second.
package main

import (
	"fmt"
	"runtime"
	"sync"
	"time"
)

func main() {
	start := time.Now()
	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() { time.Sleep(time.Second) })
	}
	wg.Wait()
	fmt.Printf("GOMAXPROCS=%d: four waits took %v\n",
		runtime.GOMAXPROCS(0), time.Since(start).Round(10*time.Millisecond))
}
```

```
ana@vm:~/promise$ go build -o wait wait.go
ana@vm:~/promise$ ./wait
GOMAXPROCS=4: four waits took 1s
ana@vm:~/promise$ GOMAXPROCS=1 ./wait
GOMAXPROCS=1: four waits took 1s
```

**Um processador, quatro segundos de espera, um segundo no relógio.** Enquanto uma goroutine dorme,
o runtime não tem nada para rodar por ela, então as quatro esperas se sobrepõem por completo.
Escritas uma depois da outra, as mesmas quatro esperas teriam levado quatro segundos em qualquer
máquina. Esse é o caso para o qual Go foi feito: um servidor com milhares de requisições em
andamento, quase todas esperando alguma coisa, atendidas por um punhado de processadores.

Os dois resultados apontam para o mesmo lado. **Estruture o programa em partes independentes
primeiro**, e ele aproveita o paralelismo que a máquina oferecer sem ser reescrito. A lição 2 mostra
quanto custa uma goroutine, e por que milhares delas são coisa normal.
