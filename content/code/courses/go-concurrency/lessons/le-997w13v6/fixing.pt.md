---
title: Quatro jeitos de consertar uma, e como escolher
version: 1
---

Uma corrida são duas goroutines mexendo na mesma memória sem nada que as ordene. **Então existem
exatamente dois tipos de conserto: pôr alguma coisa entre os dois acessos, ou impedir que eles
mexam na mesma memória.** O primeiro tipo tem três ferramentas em Go, e o segundo tem uma ideia.
Cada corrida desta lição recebe a que lhe cabe, e cada conserto é provado do mesmo jeito: o detector
roda de novo e não diz nada.

| a corrida | o conserto | por que esse |
|---|---|---|
| um número, aumentado numa goroutine e lido em outra | um atômico | um inteiro só, e nada mais precisa mudar junto |
| um map escrito por várias goroutines | um mutex | vários passos numa estrutura, que precisam parecer um passo só |
| um slice ao qual toda goroutine faz append | parar de compartilhar | cada goroutine pode ser dona da sua posição |
| resultados passados de workers para um coletor | um canal | lições 3 a 15: o valor se move, e a memória vai junto |

## Um atômico, para um número

O `stats.go` da seção 03 aumenta um `int` numa goroutine e o lê em outra. O pacote `sync/atomic`
tem tipos cujas operações são todas indivisíveis e sincronizadas, então uma leitura por `Load` vê
um valor inteiro escrito por `Add`, e o detector sabe que eles estão ordenados. Editado, salvo de
novo como `stats.go`:

```go
// Command stats counts requests in one goroutine while main reports them.
package main

import (
	"fmt"
	"sync/atomic"
	"time"
)

type stats struct {
	served atomic.Int64
}

func main() {
	s := &stats{}
	go serve(s)
	time.Sleep(10 * time.Millisecond)
	fmt.Println("served so far:", s.served.Load())
}

func serve(s *stats) {
	for {
		s.served.Add(1)
		time.Sleep(time.Millisecond)
	}
}
```

```
ana@vm:~/races$ go run -race stats.go
served so far: 10
```

O campo mudou de tipo, e é esse o sentido dos atômicos tipados: **um `atomic.Int64` não tem `++`**,
então o compilador recusa todo acesso comum que você possa esquecer. Um atômico serve para um
contador ou uma flag. Dois campos que precisam mudar juntos não são dois atômicos, porque um leitor
poderia ver um mudado e o outro não; isso pede uma trava.

## Um mutex, para uma estrutura

O `tally.go` faz várias coisas no map a cada `counts[w]++`: procura a chave, soma um, guarda o
resultado, talvez aumente a tabela. Um mutex, o assunto da lição 8, faz dessa sequência inteira um
passo só para qualquer outra goroutine. Editado, salvo de novo como `tally.go`:

```go
// Command tally counts words from several goroutines into one map.
package main

import (
	"fmt"
	"strings"
	"sync"
)

func main() {
	lines := []string{"the cat sat", "the dog ran", "a cat ran", "the end"}
	counts := map[string]int{}
	var mu sync.Mutex
	var wg sync.WaitGroup
	for _, line := range lines {
		wg.Go(func() {
			for _, w := range strings.Fields(line) {
				mu.Lock()
				counts[w]++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	fmt.Println(counts)
}
```

```
ana@vm:~/races$ go run -race tally.go
map[a:1 cat:2 dog:1 end:1 ran:2 sat:1 the:3]
```

A mesma saída das execuções normais antes do conserto, e vale dizer com todas as letras: **o
conserto não mudou a resposta, porque a resposta estava certa por sorte o tempo todo.** O que mudou
é que agora ela está certa por construção, e o detector concorda.

## Parar de compartilhar, para um slice

O terceiro programa junta os quadrados de mil números, cada um calculado numa goroutine própria,
fazendo append num único slice. Salvo como `collect.go`:

```go
// Command collect squares a thousand numbers in a thousand goroutines.
package main

import (
	"fmt"
	"sync"
)

func main() {
	var results []int
	var wg sync.WaitGroup
	for i := range 1000 {
		wg.Go(func() { results = append(results, i*i) })
	}
	wg.Wait()
	fmt.Println("results:", len(results))
}
```

```
ana@vm:~/races$ for i in 1 2 3; do go run collect.go; done
results: 865
results: 984
results: 868
ana@vm:~/races$ go run -race collect.go 2>&1 | tail -3
results: 578
Found 4 data race(s)
exit status 66
```

Este falha sem o detector. O `append` lê o tamanho do slice, escreve o elemento novo e guarda um
tamanho novo, e duas goroutines que leem o mesmo tamanho escrevem na mesma posição, então
quadrados somem: entraram 1.000 e as execuções guardaram menos, um número diferente a cada vez. O
último comando guarda só o fim da saída do detector; os relatórios têm o formato que a seção 03 leu.

Um mutex em volta do `append` funcionaria. Mas nada aqui precisa que as goroutines compartilhem um
slice que cresce. **O número de resultados é conhecido antes da primeira goroutine começar**, então
o slice pode ser criado com o tamanho todo e cada goroutine receber o seu próprio elemento.
Elementos diferentes de um slice são memória diferente, e o detector concorda. Editado, salvo de
novo como `collect.go`:

```go
// Command collect squares a thousand numbers in a thousand goroutines.
package main

import (
	"fmt"
	"sync"
)

func main() {
	results := make([]int, 1000)
	var wg sync.WaitGroup
	for i := range 1000 {
		wg.Go(func() { results[i] = i * i })
	}
	wg.Wait()
	fmt.Println("results:", len(results), "last:", results[999])
}
```

```
ana@vm:~/races$ go run -race collect.go
results: 1000 last: 998001
```

**Nenhuma trava, nenhum atômico, nenhum canal, e nenhuma corrida**, porque duas goroutines nunca
mexem no mesmo elemento; os resultados ainda voltam em ordem, o que a versão com append nunca
prometeu. Quando o desenho deixa cada goroutine ser dona da sua memória, esse é o conserto mais
barato que existe.

## Escolhendo

A quarta linha da tabela é a que as lições 3 a 15 percorreram: quando um valor é entregue por um
canal, quem envia para de usá-lo e quem recebe começa, então não sobra nada para compartilhar.
Escolha perguntando o que é a coisa compartilhada. **Um número: um atômico. Uma estrutura
atualizada em vários passos: um mutex. Trabalho cujos resultados podem ser divididos: dê a cada
goroutine o seu. Um valor que passa de uma goroutine para outra: um canal.** E escolha o que
escolher, rode o detector de novo; um conserto que ninguém rodou de novo é um palpite.
