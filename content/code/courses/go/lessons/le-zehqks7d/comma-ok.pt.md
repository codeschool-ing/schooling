---
title: Uma chave ausente e o idioma comma-ok
version: 1
---

Em Python, pedir a um dicionário uma chave que ele não tem levanta um erro. **Em Go, pedir a um map
uma chave ausente não é erro nenhum: você recebe o valor zero do tipo do valor**, e nada avisa que
ela faltava. Isso é cômodo quase sempre e errado justamente quando o zero é um valor que alguém
poderia ter guardado.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tstock := map[string]int{\"apple\": 0, \"pear\": 3}\n\tfmt.Println(stock[\"pear\"], stock[\"apple\"], stock[\"kiwi\"])\n",
      "note": "Maçãs estão na lista sem nada em estoque, e kiwis não estão na lista. **As duas buscas imprimem `0`**, então só por esta linha não dá para distinguir uma da outra."
    },
    {
      "code": "\n\tn, ok := stock[\"apple\"]\n\tfmt.Println(n, ok)\n\tn, ok = stock[\"kiwi\"]\n\tfmt.Println(n, ok)\n",
      "note": "**Quando se pedem dois resultados, a busca devolve também um `bool` que é `true` só se a chave está presente.** Por convenção ele se chama `ok`, e é esse nome que batiza o idioma: comma-ok."
    },
    {
      "code": "\n\tif _, ok := stock[\"kiwi\"]; !ok {\n\t\tfmt.Println(\"kiwi is not on the list at all\")\n\t}\n}\n",
      "note": "A forma que você mais vai encontrar: a busca dentro do `if`, com `_` descartando o valor quando só a presença importa. A instrução antes do ponto e vírgula pertence ao `if`, o que a lição 19 explica."
    }
  ],
  "output": "3 0 0\n0 true\n0 false\nkiwi is not on the list at all"
}
```

Então há dois jeitos de ler um map, e escolher entre eles é uma pergunta sobre os seus dados.
**Quando o valor zero não pode ser uma entrada de verdade, a busca de um valor só basta. Quando
pode, peça o `ok`.** Um map de nomes para idades, em que ninguém tem 0 anos, pode usar
`ages[name] == 0` para dizer "desconhecido". Uma lista de estoque, em que 0 é uma quantidade
perfeitamente válida, não pode, e um programa que testasse `stock["apple"] == 0` diria que maçã é
um item de que ele nunca ouviu falar.

A mesma forma com dois resultados, com o mesmo nome para o segundo valor, aparece em outros dois
lugares da linguagem: ao perguntar a um valor de interface o que ele guarda, na lição 29, e ao
receber de um canal, no curso `go-concurrency`.

## O valor zero fazendo o trabalho

O silêncio sobre chaves ausentes é também o que deixa curto o código de map mais comum. Contar
palavras é uma linha dentro do laço:

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	words := strings.Fields("the cat saw the dog and the dog saw the cat run")
	counts := map[string]int{}
	for i := 0; i < len(words); i++ {
		counts[words[i]]++
	}
	fmt.Println(counts)

	names := []string{"ana", "bruno", "alice", "caio", "bia"}
	byInitial := map[string][]string{}
	for i := 0; i < len(names); i++ {
		first := names[i][:1]
		byInitial[first] = append(byInitial[first], names[i])
	}
	fmt.Println(byInitial)
}
```

```
ana@vm:~/maps-count$ go run .
map[and:1 cat:2 dog:2 run:1 saw:2 the:4]
map[a:[ana alice] b:[bruno bia] c:[caio]]
```

`counts[words[i]]++` lê a contagem, soma um e guarda de volta. Na primeira vez que uma palavra
aparece não há nada para ler, então a leitura dá 0 e a palavra é guardada com 1. **Nenhuma
verificação de "essa palavra é nova?" é necessária, porque o valor zero de `int` é a contagem
inicial certa.**

O segundo laço agrupa nomes pela primeira letra, e funciona pelo mesmo motivo um nível abaixo.
`byInitial["a"]` começa como o valor zero de `[]string`, que é uma slice nil, e a lição 12 mostrou
que `append` numa slice nil aloca o array sozinho. Cada nome é acrescentado ao seu grupo, e o
primeiro nome de um grupo cria o grupo. `names[i][:1]` é o primeiro byte do nome, que só é a
primeira letra porque estes nomes são ASCII puro; a lição 9 mostrou por que fatiar uma string é
fatiar bytes.

Os dois laços dependem de o map ter sido criado. `counts := map[string]int{}` é um map;
`var counts map[string]int` seria o map nil da seção 02, e o primeiro `++` entraria em pânico.
