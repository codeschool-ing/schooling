---
title: O que uma letra maiúscula significa
version: 1
---

A lição 4 disse que o P maiúsculo de `fmt.Println` é o que deixa outro pacote chamá-la, e toda lição
desde então escreveu maiúsculas sem dizer por quê. Quem vem de Java ou C# procura a palavra-chave
que torna um nome público, e Go não tem nenhuma; quem vem de Python toma a caixa por estilo. **Em Go
a primeira letra de um nome é a regra de acesso.** Um nome que começa com letra maiúscula é
**exportado**, visível para todo pacote que importa este. Qualquer outro nome é visível dentro do
próprio pacote e em nenhum outro lugar. `go doc go/token.IsExported` diz isso numa linha:
"IsExported reports whether name starts with an upper-case letter", informa se o nome começa com
letra maiúscula.

A regra vale para todo nome declarado no topo de um pacote, funções, tipos, variáveis e constantes,
e para dois tipos de nome que não pertencem ao escopo do pacote: os campos de uma struct e os
métodos de um tipo. O `text` da seção 02 usa todos eles. `Count`, `Counts`, `Entry` e `Top` são
exportados; `entries` e `byCount` não. Um programa do mesmo módulo que estica a mão para os de letra
minúscula, `cmd/peek` numa cópia do módulo, recebe três recusas:

```go
package main

import (
	"fmt"

	"example.com/wordy/text"
)

func main() {
	c := text.Count("one two two")
	fmt.Println(c.entries())
	fmt.Println(text.byCount(text.Entry{"a", 1}, text.Entry{"b", 2}))
	var e text.Entry
	fmt.Println(e.word)
}
```

```
ana@vm:~/pkgs-peek$ go build ./cmd/peek
# example.com/wordy/cmd/peek
cmd/peek/main.go:11:16: c.entries undefined (cannot refer to unexported method entries)
cmd/peek/main.go:12:19: undefined: text.byCount
cmd/peek/main.go:14:16: e.word undefined (type text.Entry has no field or method word, but does have field Word)
```

Vale ler as três mensagens separadamente. O método existe, e o compilador diz isso: ele é
**unexported**, não exportado, a palavra para um nome de letra minúscula visto de fora. A função
recebe um `undefined` seco, como se `text` nunca a tivesse declarado, e de fora do pacote essa é a
verdade. O campo `word` nunca existiu, e o compilador notou o `Word` exportado a uma letra de
distância. Estar no mesmo módulo não mudou nada; **a fronteira é o pacote**, e `cmd/peek` é outro
pacote.

Dentro de `text`, por outro lado, nada se esconde de nada. `top.go` chamou `c.entries()` e passou
`byCount` para `slices.SortFunc` sem pensar duas vezes, e `count.go` poderia fazer o mesmo.

## Nomes exportados são uma promessa

O `go doc` mostra um pacote do jeito que quem importa o vê, ou seja, só os nomes exportados. O `-u`
acrescenta os não exportados:

```
ana@vm:~/pkgs$ go doc ./text Counts
package text // import "example.com/wordy/text"

type Counts map[string]int
    Counts maps each word to the number of times it appears.

func Count(s string) Counts
func (c Counts) Top(n int) []Entry
ana@vm:~/pkgs$ go doc -u ./text Counts
package text // import "example.com/wordy/text"

type Counts map[string]int
    Counts maps each word to the number of times it appears.

func Count(s string) Counts
func (c Counts) Top(n int) []Entry
func (c Counts) entries() []Entry
```

A primeira listagem é a **API** do pacote, tudo de que outro pacote pode passar a depender. Renomeie
`Top` e os dois programas de `cmd` param de compilar, junto com os de qualquer outra pessoa.
Renomeie `entries`, ou troque-o e `byCount` por outro jeito de ordenar, e nada fora de `text`
consegue perceber. Então o hábito que compensa é **começar todo nome com letra minúscula**, e
passá-lo para maiúscula no dia em que outro pacote precisar dele. Os campos de `Entry` são
maiúsculos exatamente por isso: `cmd/wordtop` imprime `e.Word` e `e.Count`.

Um nome que o compilador não precisou mostrar também é um nome que você não teve de documentar.
Todo nome exportado acima tem um comentário que começa pelo nome, que é o que o `go doc` imprimiu;
`entries` e `byCount` não têm nenhum, e nada pede um.

## JSON, e todo pacote que lê os seus campos

A lição 15 serializou uma struct cujo campo `age` sumiu da saída, e apontou para cá para dar o
motivo. `json.Marshal` é uma função do pacote `encoding/json`, que trabalha na sua struct de fora do
seu pacote e segue a mesma regra: a documentação dele diz que "each exported struct field becomes a
member of the object", cada campo exportado vira um membro do objeto. Uma tag não muda isso:

```go
package main

import (
	"encoding/json"
	"fmt"
)

type Entry struct {
	Word  string `json:"word"`
	count int    `json:"count"`
}

func main() {
	b, err := json.Marshal(Entry{Word: "go", count: 3})
	fmt.Println(string(b), err)

	var e Entry
	err = json.Unmarshal([]byte(`{"word":"go","count":3}`), &e)
	fmt.Printf("%+v %v\n", e, err)
}
```

```
ana@vm:~/pkgs-json$ go run .
{"word":"go"} <nil>
{Word:go count:0} <nil>
ana@vm:~/pkgs-json$ go vet; echo $?
main.go:10:2: struct field count has json tag but is not exported
1
```

As duas direções falharam em silêncio. O `Marshal` deixou `count` de fora, o `Unmarshal` viu
`"count":3` na entrada e deixou o campo em 0, e os dois devolveram erro nil. O `fmt` imprimiu
`count:0` mesmo assim: ele olha dentro dos valores pelo pacote `reflect`, que deixa outro pacote ler
um campo de letra minúscula mas, nas palavras de `go doc reflect.Value.CanSet`, nunca mudar um valor
"obtained by the use of unexported struct fields", obtido por meio de campos não exportados. O
`go vet` notou a contradição: uma tag endereçada a outro pacote, num campo que esse pacote nunca vai
ver. É um segundo motivo para seguir o conselho da lição 4 e rodar o `go vet` antes que qualquer
outra pessoa leia o código.

A mesma regra vale para outros pacotes que trabalham nos seus tipos de fora;
`go doc encoding/xml.Marshal` descreve a saída dele como "the exported fields of the struct", os
campos exportados da struct. **Se outro pacote precisa ler ou preencher um campo, o campo começa com
letra maiúscula.**
