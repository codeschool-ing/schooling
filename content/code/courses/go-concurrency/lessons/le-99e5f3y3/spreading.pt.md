---
title: Espalhando trabalho entre goroutines
version: 1
---

**Fan-out são várias goroutines lendo de um canal só**, para que um fluxo de trabalho seja dividido
entre elas. A lição 7 montou o pool de workers para pôr um limite em quanto roda ao mesmo tempo.
Esta lição trata da outra metade da mesma forma: quem pega qual pedaço, em que ordem as respostas
voltam, e o que acontece quando um pedaço falha.

A imagem que as pessoas trazem é a de um carteador numa mesa, entregando o job 1 ao primeiro
worker, o job 2 ao segundo, e de novo. **Ninguém distribui.** Cada worker pede ao canal o próximo
job quando fica livre, e o canal entrega cada valor a exatamente uma das goroutines que o esperam. O
programa abaixo envia doze jobs de tamanhos diferentes, de 10 a 40 milissegundos cada e 300 no
total, a três workers. Cada um registra os jobs que pegou, sob uma trava da lição 8. Ele é salvo em
`~/fanout/spread` como `spread.go`:

```go
// Command spread hands twelve jobs of different sizes to three workers through one channel.
package main

import (
	"fmt"
	"sync"
	"time"
)

func main() {
	jobs := make(chan int)
	var mu sync.Mutex
	took := map[string][]int{}

	var wg sync.WaitGroup
	for _, name := range []string{"w1", "w2", "w3"} {
		wg.Go(func() {
			for job := range jobs {
				time.Sleep(time.Duration(job%4+1) * 10 * time.Millisecond)
				mu.Lock()
				took[name] = append(took[name], job)
				mu.Unlock()
			}
		})
	}

	start := time.Now()
	for job := 1; job <= 12; job++ {
		jobs <- job
	}
	close(jobs)
	wg.Wait()

	for _, name := range []string{"w1", "w2", "w3"} {
		fmt.Println(name, took[name])
	}
	fmt.Println("twelve jobs, 300ms of work, took", time.Since(start).Round(10*time.Millisecond))
}
```

Rodado duas vezes:

```
ana@vm:~/fanout$ go run ./spread
w1 [2 5 8 10]
w2 [3 7 11]
w3 [1 4 6 9 12]
twelve jobs, 300ms of work, took 120ms
ana@vm:~/fanout$ go run ./spread
w1 [2 5 8 9 11]
w2 [3 7 12]
w3 [1 4 6 10]
twelve jobs, 300ms of work, took 120ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Fan-out no spread.go. main envia os jobs de 1 a 12 num único canal sem buffer, jobs. Três workers percorrem o mesmo canal, e cada job vai para exatamente um deles, o que estiver livre. Na primeira execução w1 pegou 2, 5, 8 e 10; w2 pegou 3, 7 e 11; w3 pegou 1, 4, 6, 9 e 12. Fechar jobs encerra os três laços.\"><defs><marker id=\"l13fan-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main</text><text x=\"80\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">envia 1 … 12, depois fecha</text><rect x=\"210\" y=\"105\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">jobs</text><text x=\"285\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um canal, três leitores</text><path d=\"M142 125 H207\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13fan-phosphor)\"></path><rect x=\"470\" y=\"40\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">w1</text><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2 5 8 10</text><path d=\"M362 125 L467 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13fan-phosphor)\"></path><rect x=\"470\" y=\"110\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">w2</text><text x=\"610\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">3 7 11</text><path d=\"M362 125 L467 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13fan-phosphor)\"></path><rect x=\"470\" y=\"180\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">w3</text><text x=\"610\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1 4 6 9 12</text><path d=\"M362 125 L467 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13fan-phosphor)\"></path><text x=\"470\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada job chega a exatamente um worker</text></svg>", "caption": "A primeira execução do spread.go. Ninguém distribui os jobs: o worker que estiver livre pega o próximo."}
```

Três coisas nessas oito linhas são o padrão inteiro.

- **Cada job foi feito uma vez.** Os doze números aparecem exatamente uma vez nas três listas, nas
  duas execuções. Um canal nunca entrega um valor a dois receptores, então o fan-out não precisa de
  controle nenhum para evitar fazer um job duas vezes.
- **A divisão segue a velocidade, não a vez.** `w3` pegou cinco jobs na primeira execução e quatro
  na segunda; `w2` pegou três nas duas. Um worker que tirou jobs curtos voltou antes e tirou mais. É
  exatamente o que se quer de uma fila compartilhada, e é por isso que a divisão muda entre
  execuções.
- **O total foi de 120 milissegundos para 300 de trabalho**, perto de um terço, porque três workers
  dividiram. Passou de 100 porque os últimos jobs entregues não se dividem, e algum worker sempre
  termina por último.

**Fechar `jobs` é o sinal de que não há mais trabalho**, e ele chega a todos os workers de uma vez:
cada laço `for job := range jobs` termina quando o canal está fechado e vazio, como a lição 3
mostrou. O `main` o fecha depois do último envio, porque quem envia é quem sabe quando o envio
acabou, e depois espera os três com `wg.Wait`.

Um worker lendo um canal é um laço. Vários lendo o mesmo canal são fan-out, e a única mudança no
código é quantas goroutines rodam esse laço.
