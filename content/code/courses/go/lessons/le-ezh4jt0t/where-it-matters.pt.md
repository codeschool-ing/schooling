---
title: Onde o array é o tipo certo
version: 1
---

Depois da lição 12 dá vontade de concluir que arrays são o encanamento da slice, algo de que a
linguagem precisa por baixo e que um programa nunca quer para si. As seções 02 e 03 encontraram duas
funções que discordam, `sha256.Sum256` e `netip.AddrFrom4`. **Um array é o tipo certo quando o
tamanho faz parte do que o valor significa, e em troca ele faz duas coisas que uma slice não faz:
ser comparado com `==` e ser chave de map.**

## `==` funciona em arrays

A lição 11 comparou dois arrays com `==`. É nos checksums que isso compensa, porque comparar dois
checksums de 32 bytes faz as vezes de comparar dois conteúdos inteiros:

```go
package main

import (
	"bytes"
	"crypto/sha256"
	"fmt"
)

func main() {
	x := []byte("hello")
	y := []byte("hello")
	fmt.Println(sha256.Sum256(x) == sha256.Sum256(y))
	fmt.Println(bytes.Equal(x, y))
}
```

```
ana@vm:~/slicearray-eq$ go run .
true
true
```

A primeira linha compara dois valores `[32]byte`, elemento por elemento, com o operador. A segunda
compara as próprias slices e precisa de uma função para isso, porque entre duas slices o operador é
recusado, como a lição 11 mostrou: `slice can only be compared to nil`. A lição 11 também deu o
motivo. Duas slices poderiam ser iguais em dois sentidos que discordam, os mesmos elementos ou a
mesma janela sobre o mesmo array, então Go obriga você a dizer qual quer, aqui com `bytes.Equal`.
**Um array não tem essa ambiguidade: ele é os seus elementos, então `==` tem um significado só**, e
é esse significado único que deixa um array ser chave de map.

## Um array como chave de map

Um map precisa de chaves que ele consiga comparar, então a mesma regra decide quais tipos podem ser
chave. Maps são assunto da lição 14; o que este programa precisa deles é que `seen[sum]` devolve o
nome guardado sob `sum`, ou a string vazia se não houver nenhum:

```go
package main

import (
	"crypto/sha256"
	"fmt"
)

func main() {
	names := []string{"a.txt", "b.txt", "c.txt", "d.txt"}
	bodies := []string{"hello", "world", "hello", "hello\n"}

	seen := map[[32]byte]string{}
	for i := 0; i < len(names); i++ {
		sum := sha256.Sum256([]byte(bodies[i]))
		if seen[sum] != "" {
			fmt.Println(names[i], "has the same contents as", seen[sum])
			continue
		}
		seen[sum] = names[i]
	}
	fmt.Println(len(seen), "different contents")
}
```

```
ana@vm:~/slicearray-dedup$ go run .
c.txt has the same contents as a.txt
3 different contents
```

Quatro arquivos e três conteúdos diferentes: `c.txt` repete `a.txt` byte a byte, e `d.txt` é a
mesma palavra com uma quebra de linha depois, o que dá outro checksum. A chave é o array inteiro de
32 bytes, comparado exatamente. Com `[]byte` como tipo de chave o programa não compilaria, e a lição
14 mostra essa recusa; converter cada checksum em `string` funcionaria, e seria uma segunda
representação de algo que já tinha um tipo perfeitamente bom.

O preço disso tudo é o que a lição 11 descreveu: array é valor, então atribuí-lo ou passá-lo copia
todos os elementos. Para 32 bytes isso não merece nem um pensamento. Para um array de um milhão de
elementos é um custo real, e a lição 22 o mede. **Deixe os arrays para valores de tamanho pequeno e
fixo que significa alguma coisa, e as slices para tudo o que é lista.**
