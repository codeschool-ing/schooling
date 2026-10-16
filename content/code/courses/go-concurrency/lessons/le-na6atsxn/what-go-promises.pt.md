---
title: O que Go promete, e o que não promete
version: 1
---

Um programa com goroutines é um programa cujos passos já não vêm numa ordem fixa, e o primeiro
instinto é tomar a ordem que você vê pela ordem que existe. **Go promete muito pouco sobre a ordem
em que as goroutines rodam, e muito sobre o que acontece quando elas se sincronizam.** Separar essas
duas coisas é boa parte deste curso.

## A ordem não é prometida

O `order.go`, da seção 02, inicia três goroutines que imprimem uma linha cada. Compilado uma vez e
rodado cinco:

```
ana@vm:~/promise$ go build -o order order.go
ana@vm:~/promise$ for i in 1 2 3 4 5; do ./order | paste -sd " "; done
hello from caio hello from bia hello from ana
hello from caio hello from ana hello from bia
hello from caio hello from ana hello from bia
hello from caio hello from ana hello from bia
hello from caio hello from ana hello from bia
```

`paste -sd " "` junta as três linhas de cada execução numa só, então cada linha acima é uma
execução. Quatro das cinco concordam, e o laço iniciou `ana` primeiro, mas `caio` imprimiu primeiro
todas as vezes. É o escalonador do runtime trabalhando: a goroutine criada por último espera numa
posição só dela e tende a rodar primeiro quando `main` para para esperar. A lição 2 abre o
escalonador. Na seção 02 o mesmo programa, compilado com o detector de corridas, imprimiu `ana`,
`bia`, `caio`.

**Nenhuma dessas ordens faz parte da linguagem.** Outra versão, uma máquina mais ocupada ou outro
`GOMAXPROCS` as mudam, e um programa cuja correção depende de alguma delas funciona até o dia em
que deixa de funcionar. Se a ordem importa, o programa tem de dizer isso, com um canal ou uma
trava, que é para o que servem as lições 3 e 8.

## Memória compartilhada sem regra é uma corrida

O segundo programa faz quatro goroutines somarem um à mesma variável, cem mil vezes cada uma, salvo
como `count.go`:

```go
// Command count adds one to a shared number from four goroutines at once.
package main

import (
	"fmt"
	"sync"
)

func main() {
	total := 0
	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() {
			for range 100_000 {
				total++
			}
		})
	}
	wg.Wait()
	fmt.Println("total:", total)
}
```

Quatro goroutines vezes cem mil dá 400.000. Cinco execuções:

```
ana@vm:~/promise$ go build -o count count.go
ana@vm:~/promise$ for i in 1 2 3 4 5; do ./count; done
total: 281276
total: 400000
total: 351796
total: 341664
total: 197620
```

Quatro respostas erradas e uma certa, e **a certa é a linha mais perigosa da tela**. Um teste que
rodasse uma vez e recebesse 400.000 teria passado, e o programa teria sido entregue com o defeito
dentro.

A causa é que `total++` não é um passo só. Ele lê o número, soma um e escreve o resultado de volta,
e entre a leitura e a escrita outra goroutine pode fazer o mesmo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma atualização perdida, passo a passo. total vale 7. A goroutine 10 lê 7, depois a goroutine 11 lê 7. A goroutine 10 soma um e escreve 8. A goroutine 11 soma um ao 7 que leu e também escreve 8. Aconteceram dois incrementos e total subiu um.\"><defs><marker id=\"l01lost-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01lost-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"130\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">goroutine 10</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">total, na memória</text><text x=\"590\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">goroutine 11</text><rect x=\"330\" y=\"55\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">7</text><rect x=\"50\" y=\"55\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lê 7</text><path d=\"M328 70 H212\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01lost-phosphor)\"></path><rect x=\"330\" y=\"105\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">7</text><rect x=\"510\" y=\"105\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lê 7</text><path d=\"M392 120 H508\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01lost-phosphor)\"></path><rect x=\"330\" y=\"155\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">8</text><rect x=\"50\" y=\"155\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">escreve 8</text><path d=\"M210 170 H328\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01lost-amber)\"></path><rect x=\"330\" y=\"205\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">8</text><rect x=\"510\" y=\"205\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">escreve 8</text><path d=\"M510 220 H392\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01lost-amber)\"></path><rect x=\"220\" y=\"252\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"267\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">dois incrementos, um perdido</text></svg>", "caption": "total++ é uma leitura, uma soma e uma escrita. Duas goroutines intercalando esses três passos perdem um incremento.", "same": ["goroutine 10", "goroutine 11"]}
```

Isto é uma **corrida de dados** (*data race*): duas goroutines mexem na mesma memória ao mesmo
tempo, pelo menos uma delas escreve, e nada ordena as duas. O modelo de memória de Go, o documento
que diz o que um programa pode supor sobre memória compartilhada entre goroutines, não dá a um
programa com corrida de dados nenhuma resposta em que se possa confiar. Os totais acima são a cara
disso.

## O que Go promete

As promessas de Go são sobre **sincronização**. Quando uma goroutine entrega um valor a outra por um
canal, tudo o que a primeira fez antes do envio fica visível para a segunda depois do recebimento.
Quando uma trava é liberada e tomada de novo, tudo o que foi feito antes da liberação fica visível
depois da tomada. Quando `wg.Wait` retorna, tudo o que as goroutines esperadas fizeram fica visível
para quem esperou. É por isso que ler `total` depois de `wg.Wait` é seguro. O problema são os
incrementos competindo entre si, dentro das goroutines.

O provérbio de Go para isso é *não se comunique compartilhando memória; compartilhe memória se
comunicando*. As lições 3 a 7 são a comunicação; as lições 8 e 9 são as travas, para quando
compartilhar é mais simples.

E uma promessa é uma ferramenta, não uma regra. **O detector de corridas relata uma corrida de dados
que acontece enquanto ele observa**, com os dois lugares do código que colidiram:

```
ana@vm:~/promise$ go run -race count.go
==================
WARNING: DATA RACE
Read at 0x00c000018108 by goroutine 11:
  main.main.func1()
      /home/ana/promise/count.go:15 +0x37

Previous write at 0x00c000018108 by goroutine 10:
  main.main.func1()
      /home/ana/promise/count.go:15 +0x49

Goroutine 11 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72

Goroutine 10 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
==================
==================
WARNING: DATA RACE
Write at 0x00c000018108 by goroutine 11:
  main.main.func1()
      /home/ana/promise/count.go:15 +0x49

Previous write at 0x00c000018108 by goroutine 10:
  main.main.func1()
      /home/ana/promise/count.go:15 +0x49

Goroutine 11 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72

Goroutine 10 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
==================
total: 353574
Found 2 data race(s)
exit status 66
```

Dois relatórios, ambos apontando para a linha 15 de `count.go`, que é `total++`: uma leitura pela
goroutine 11 depois de uma escrita pela goroutine 10, e depois uma escrita depois de uma escrita. O
programa ainda imprimiu um total errado, porque o detector relata em vez de consertar, e saiu com o
status 66 para um script perceber. **Ele só vê as corridas que acontecem na execução que observa**,
então uma corrida num caminho que a execução não percorreu fica sem relato. A lição 16 lê esses
relatórios linha a linha e conserta o que eles encontram.
