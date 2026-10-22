---
title: Resultados fora de ordem
version: 1
---

O fan-out pega os jobs em ordem e os termina na ordem que o trabalho permitir. **Um resultado que
volta por um canal chega na ordem em que o trabalho terminou, e não na ordem em que começou**, e um
programa que imprime ou guarda os resultados conforme chegam abriu mão, sem alarde, da ordem da
entrada.

O programa abaixo mede quatro palavras em paralelo; uma palavra mais longa demora mais para ser
medida. Cada goroutine devolve o resultado por um canal só, e o `main` os imprime conforme chegam.
Ele é salvo em `~/fanout/arrival` como `arrival.go`:

```go
// Command arrival measures four words in parallel and prints the results as they arrive.
package main

import (
	"fmt"
	"time"
)

type result struct {
	index int
	word  string
	size  int
}

// measure stands for slow work whose time depends on its input.
func measure(word string) int {
	time.Sleep(time.Duration(len(word)) * 10 * time.Millisecond)
	return len(word)
}

func main() {
	words := []string{"concurrency", "is", "not", "parallelism"}
	results := make(chan result)
	for i, w := range words {
		go func() { results <- result{i, w, measure(w)} }()
	}
	for range words {
		r := <-results
		fmt.Println(r.index, r.word, r.size)
	}
}
```

```
ana@vm:~/fanout$ go run ./arrival
1 is 2
2 not 3
0 concurrency 11
3 parallelism 11
```

A entrada era `concurrency is not parallelism`. A saída começa com `is`, a palavra mais curta e o
job mais rápido, e as duas palavras longas vêm por último. Nada deu errado: a ordem de chegada é a
ordem de término.

## Dois jeitos de recuperar a ordem

O resultado carrega o seu `index`, e essa é a primeira correção: quem recebe os resultados pode pôr
cada um no lugar certo, numa slice do tamanho certo ou ordenando depois. Carregar o índice custa um
campo e mantém o canal, o que importa quando os resultados alimentam um estágio seguinte, como na
lição 15.

A segunda correção não precisa de canal nenhum. **Cada goroutine escreve a resposta no seu próprio
elemento de uma slice criada antes**, e o `main` lê a slice quando todas as goroutines terminaram.
Ele é salvo em `~/fanout/inplace` como `inplace.go`:

```go
// Command inplace measures four words in parallel and keeps the input's order.
package main

import (
	"fmt"
	"sync"
	"time"
)

func measure(word string) int {
	time.Sleep(time.Duration(len(word)) * 10 * time.Millisecond)
	return len(word)
}

func main() {
	words := []string{"concurrency", "is", "not", "parallelism"}
	sizes := make([]int, len(words))
	var wg sync.WaitGroup
	for i, w := range words {
		wg.Go(func() { sizes[i] = measure(w) })
	}
	wg.Wait()
	for i, w := range words {
		fmt.Println(i, w, sizes[i])
	}
}
```

```
ana@vm:~/fanout$ go run -race ./inplace
0 concurrency 11
1 is 2
2 not 3
3 parallelism 11
```

A ordem da entrada, e o detector de corridas, rodando o tempo todo, não relatou nada. Quatro
goroutines escreveram numa slice ao mesmo tempo e isso não foi uma corrida, porque **cada elemento
de uma slice é uma variável separada**: `sizes[0]` e `sizes[3]` são memórias diferentes, e a
definição de corrida da lição 1 exige duas goroutines mexendo na mesma memória. O que torna isso
seguro é a disciplina de cada goroutine escrever só o próprio índice, e de o `main` só ler depois
de `wg.Wait`, cuja promessa da lição 1 torna toda escrita visível.

A mesma disciplina não se estende ao `append`. Fazer append numa slice compartilhada a partir de
várias goroutines lê e escreve o tamanho dela, que é compartilhado, e isso é uma corrida que a lição
16 mostra. Dimensione a slice antes e escreva por índice, ou envie os resultados por um canal.
