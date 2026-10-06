---
title: Criar, preencher e esvaziar um map
version: 1
---

As lições 11 a 13 guardaram valores em fila e acharam cada um pela posição. Um **map** acha um
valor por uma chave: um nome, um código, um checksum. O tipo dele nomeia as duas metades, então
`map[string]int` é um map de strings para ints. O runtime o mantém como uma tabela hash, o que
quer dizer que uma busca vai direto à chave em vez de passar por todas as entradas antes dela.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tages := map[string]int{\n\t\t\"ana\": 31,\n\t\t\"bia\": 27,\n\t}\n\tfmt.Println(ages, len(ages))\n",
      "note": "**Um literal de map é o tipo seguido de pares `chave: valor` entre `{` e `}`.** A vírgula depois do último par é obrigatória quando o `}` final fica numa linha só dele, como aqui. `len` conta as chaves."
    },
    {
      "code": "\n\tages[\"caio\"] = 45\n\tages[\"ana\"] = 32\n\tfmt.Println(ages, len(ages))\n",
      "note": "**Atribuir a `m[chave]` acrescenta a chave se ela é nova e troca o valor se não é.** Não existe um insert separado: `caio` chegou e `ana` mudou, então o comprimento foi de 2 para 3, e não para 4."
    },
    {
      "code": "\n\tdelete(ages, \"bia\")\n\tdelete(ages, \"zeca\")\n\tfmt.Println(ages, len(ages))\n",
      "note": "`delete` é uma função embutida e remove uma chave junto com o valor. Apagar uma chave que não está lá, `zeca`, não faz nada e não é erro."
    },
    {
      "code": "\n\tstock := make(map[string]int)\n\tstock[\"pear\"] = 3\n\tfmt.Println(stock, len(stock))\n}\n",
      "note": "**`make(map[K]V)` devolve um map vazio, pronto para receber escritas**, o mesmo que o literal `map[string]int{}`. O `make` também aceita um tamanho, `make(map[string]int, 1000)`, que reserva espaço para essa quantidade de chaves e não muda mais nada."
    }
  ],
  "output": "map[ana:31 bia:27] 2\nmap[ana:32 bia:27 caio:45] 3\nmap[ana:32 caio:45] 2\nmap[pear:3] 1"
}
```

O `fmt.Println` escreve um map como `map[chave:valor …]`, e nesta saída as chaves por acaso saem em
ordem alfabética. Isso é o `fmt` ordenando as chaves antes de imprimir, não a ordem que o map
guarda, e a seção 03 mostra a diferença.

Uma chave aparece uma vez só. Um literal que nomeia a mesma chave duas vezes é recusado na
compilação, já que um dos dois valores seria jogado fora sem ninguém perceber:

```go
package main

import "fmt"

func main() {
	ages := map[string]int{
		"ana": 31,
		"bia": 27,
		"ana": 32,
	}
	fmt.Println(ages)
}
```

```
ana@vm:~/maps-dup$ go run .
# example.com/dup
./main.go:9:3: duplicate key "ana" in map literal
```

## O map nil: leia, nunca escreva

A lição 6 imprimiu o valor zero de um map como `map[string]int(nil)`. **Um map declarado com `var`
e nunca criado é nil, e um map nil se comporta como um map vazio em tudo, menos numa coisa**: não
dá para guardar nada nele.

```go
package main

import "fmt"

func main() {
	var prices map[string]int
	fmt.Println(prices["pear"], len(prices), prices == nil)

	prices["pear"] = 3
	fmt.Println("this line is never reached")
}
```

```
ana@vm:~/maps-nil$ go run .
0 0 true
panic: assignment to entry in nil map

goroutine 1 [running]:
main.main()
	/home/ana/maps-nil/main.go:9 +0xc5
exit status 2
```

Ler `prices["pear"]` deu 0 e `len` deu 0, sem reclamação. A atribuição da linha 9 parou o programa
com um **pânico**, a palavra de Go para uma falha em tempo de execução que o programa não tratou. A
lição 36 trata de pânicos, e a lição 37 lê o trace impresso abaixo da mensagem. O compilador deixou
isso passar porque saber se uma variável de map guarda um map só é possível quando o programa
roda.

É o contrário do que a lição 12 mostrou para slices, em que `append` numa slice nil simplesmente
alocava um array. Não existe `append` para maps. **Um map em que você pretende escrever precisa vir
antes de um `make` ou de um literal**, e quando o map é campo de algo maior, esquecer de criá-lo é
o jeito mais comum de esse pânico aparecer.

## O que pode ser chave

Um map precisa comparar a chave que recebe com as chaves que guarda, então **o tipo da chave
precisa ser comparável com `==`**. Números, strings, booleanos, ponteiros e arrays deles são.
Slices, maps e funções não são, e a lição 13 prometeu a resposta do compilador:

```go
package main

import "fmt"

func main() {
	seen := map[[]byte]bool{}
	a := map[string]int{"x": 1}
	b := map[string]int{"x": 1}
	fmt.Println(seen, a == b)
}
```

```
ana@vm:~/maps-key$ go run .
# example.com/key
./main.go:6:14: invalid map key type []byte
./main.go:9:20: invalid operation: a == b (map can only be compared to nil)
```

O primeiro erro é o tipo da chave. O segundo é a mesma regra vista do outro lado: **um map também
não pode ser comparado com `==`**, só conferido contra `nil`, e é por isso que um map nunca pode
ser chave de outro map. A lição 13 usou um checksum `[32]byte` como chave, que é o caminho normal
para contornar o primeiro erro: um array de tamanho fixo é comparável onde a slice com os mesmos
bytes não é. Structs com campos comparáveis também podem ser chave, e a lição 15 é sobre structs.

Duas coisas para as quais maps não servem neste curso. Um map lido e escrito por duas goroutines ao
mesmo tempo é assunto do curso `go-concurrency`, porque um map comum não é seguro para isso. E
`m["ana"]` não é uma variável cujo endereço você possa pegar, o que a lição 23 explica.
