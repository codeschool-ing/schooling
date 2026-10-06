---
title: Sem ordem, de propósito
version: 1
---

Um dicionário Python devolve as chaves na ordem em que foram inseridas, e um objeto JavaScript faz
o mesmo com a maioria das chaves, então quem chega de qualquer um dos dois espera que um map tenha
*alguma* ordem. **Um map de Go não tem nenhuma.** Percorrê-lo com `range`, o laço da lição 17,
visita cada chave uma vez, e a ordem da visita é sorteada de novo a cada vez:

```go
package main

import "fmt"

func main() {
	ages := map[string]int{
		"ana": 31, "bia": 27, "caio": 45, "davi": 19, "eva": 38,
		"fabio": 52, "gil": 23, "hana": 29, "igor": 61, "joana": 34,
	}
	var walked []string
	for name, age := range ages {
		walked = append(walked, fmt.Sprint(name, ":", age))
	}
	fmt.Println(walked)
	fmt.Println(ages)
}
```

```
ana@vm:~/maps-order$ go run .
[caio:45 davi:19 gil:23 ana:31 bia:27 eva:38 fabio:52 hana:29 igor:61 joana:34]
map[ana:31 bia:27 caio:45 davi:19 eva:38 fabio:52 gil:23 hana:29 igor:61 joana:34]
ana@vm:~/maps-order$ go run .
[bia:27 caio:45 davi:19 fabio:52 hana:29 igor:61 joana:34 ana:31 eva:38 gil:23]
map[ana:31 bia:27 caio:45 davi:19 eva:38 fabio:52 gil:23 hana:29 igor:61 joana:34]
```

O mesmo programa, o mesmo map, executado duas vezes: o percurso começou em `caio` numa e em `bia`
na seguinte. A segunda linha de cada execução é idêntica, e é aí que está a armadilha. **O
`fmt.Println` ordena as chaves de um map antes de imprimi-lo**, então a ferramenta que um
iniciante usa para olhar um map é justamente a que mostra uma ordem que o map não tem. A ordenação
está no código-fonte do `fmt`, que chama o pacote interno `fmtsort` para ordenar as chaves; o map
em si nunca é ordenado.

## Aleatório por projeto

A variação não é efeito colateral do jeito como o map por acaso é guardado. Ela é posta ali. No
código-fonte do runtime do go1.27.1, `internal/runtime/maps/table.go`, todo percurso de um map
começa com `it.entryOffset = rand()`, que inicia a visita num lugar sorteado. A documentação diz o
mesmo em palavras, aqui para `maps.Keys`, que entrega as chaves de um map uma de cada vez:

```
ana@vm:~/maps-small$ go doc maps.Keys
package maps // import "maps"

func Keys[Map ~map[K]V, K comparable, V any](m Map) iter.Seq[K]
    Keys returns an iterator over keys in m. The iteration order is not
    specified and is not guaranteed to be the same from one call to the next.
```

Os colchetes na assinatura são generics, das lições 30 e 31; o que importa aqui é a frase abaixo
dela. O sorteio existe para que um programa não consiga passar a depender de uma ordem, e funciona
melhor em maps grandes. Num pequeno ele é mais fraco do que parece. Um map que nunca guardou mais
de oito chaves mantém todas num único grupo de oito posições. O início sorteado só escolhe em
que posição começar, então quatro chaves saem na ordem em que entraram, giradas:

```go
package main

import "fmt"

func main() {
	steps := map[string]int{"build": 1, "test": 2, "push": 3, "deploy": 4}
	var walked []string
	for step := range steps {
		walked = append(walked, step)
	}
	fmt.Println(walked)
}
```

```
ana@vm:~/maps-small$ go build && for i in 1 2 3 4 5 6; do ./small; done
[build test push deploy]
[test push deploy build]
[build test push deploy]
[deploy build test push]
[build test push deploy]
[build test push deploy]
```

Quatro execuções em seis deram a ordem em que o literal foi escrito. **Um teste que percorre um map
pequeno e espera essa ordem passa na maior parte das vezes e falha em algumas.** É o tipo de teste mais caro que existe,
porque as primeiras falhas levam a culpa na máquina. O grupo de oito é
como o go1.27.1 constrói maps, não uma promessa da linguagem, e a única ordem que a linguagem
promete é nenhuma.

## Uma ordem que você escolhe

Quando a ordem importa, numa saída que alguém lê ou num arquivo que precisa sair igual duas vezes,
tire as chaves, ordene-as e percorra a slice ordenada:

```go
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	ages := map[string]int{
		"ana": 31, "bia": 27, "caio": 45, "davi": 19, "eva": 38,
		"fabio": 52, "gil": 23, "hana": 29, "igor": 61, "joana": 34,
	}
	names := slices.Sorted(maps.Keys(ages))
	var walked []string
	for i := 0; i < len(names); i++ {
		walked = append(walked, fmt.Sprint(names[i], ":", ages[names[i]]))
	}
	fmt.Println(walked)
}
```

```
ana@vm:~/maps-sorted$ go run .
[ana:31 bia:27 caio:45 davi:19 eva:38 fabio:52 gil:23 hana:29 igor:61 joana:34]
```

`maps.Keys(ages)` produz as chaves na ordem aleatória do próprio map, e `slices.Sorted` as recolhe
numa `[]string` nova e a ordena. Dali em diante é uma slice comum, percorrida por índice como nas
lições 11 a 13, e cada busca `ages[names[i]]` acha a sua chave. **O map responde "qual é o valor
desta chave"; a slice ordenada responde "em que ordem".** Manter os dois trabalhos separados é a
técnica inteira, e custa uma slice de chaves.
