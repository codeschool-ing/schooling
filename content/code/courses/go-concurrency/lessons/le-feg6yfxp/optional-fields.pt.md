---
title: Campos opcionais, campos ausentes e zero
version: 1
---

JSON tem três jeitos de não dizer nada sobre um campo: deixar a chave de fora, dar `null`, ou dar um
zero, `0`, `""` ou `false`. Um campo Go sempre guarda um valor, e o zero value dele é um valor
perfeitamente bom. **O trabalho desta seção é manter "quem enviou disse zero" separado de "quem
enviou não disse nada", nos dois sentidos**, porque um estoque zero e um estoque que ninguém citou
levam a decisões diferentes. Salvo como `optional.go`:

```go
// Command optional tells "absent" from "zero" in both directions.
package main

import (
	"encoding/json"
	"fmt"
	"time"
)

type Patch struct {
	Stock *int `json:"stock"`
}

type Product struct {
	SKU       string    `json:"sku"`
	Stock     int       `json:"stock,omitempty"`
	Restocked time.Time `json:"restocked,omitempty"`
	Retired   time.Time `json:"retired,omitzero"`
}

func main() {
	for _, body := range []string{`{"stock": 0}`, `{}`, `{"stock": null}`} {
		var p Patch
		json.Unmarshal([]byte(body), &p)
		if p.Stock == nil {
			fmt.Printf("%-16s stock not given\n", body)
		} else {
			fmt.Printf("%-16s stock set to %d\n", body, *p.Stock)
		}
	}

	b, _ := json.Marshal(Product{SKU: "KB-01"})
	fmt.Println(string(b))

	var loose map[string]any
	json.Unmarshal([]byte(`{"qty": 2, "sku": "KB-01"}`), &loose)
	fmt.Printf("qty is %v of type %T\n", loose["qty"], loose["qty"])
}
```

```
ana@vm:~/jsondemo$ go run optional.go
{"stock": 0}     stock set to 0
{}               stock not given
{"stock": null}  stock not given
{"sku":"KB-01","restocked":"0001-01-01T00:00:00Z"}
qty is 2 of type float64
```

## Lendo: um ponteiro separa ausente de zero

`Patch.Stock` é um `*int`. **Uma chave ausente deixa o ponteiro `nil`; uma chave com valor, mesmo
`0`, o faz apontar para esse valor.** Então `{"stock": 0}` pôs o estoque em 0 e `{}` o deixou em
paz, que é a diferença de que uma requisição de atualização precisa: "ponha em zero" contra "não
mexa". O `null` também deixou o ponteiro `nil`, então um ponteiro não distingue uma chave ausente de
um `null` explícito. Quando esse terceiro caso importa, o campo precisa ser lido como
`json.RawMessage` e examinado, o que poucas APIs exigem.

## Escrevendo: `omitempty` contra `omitzero`

O `Product` foi escrito só com o `SKU` preenchido. O `stock` sumiu, porque o `omitempty` descarta um
`int` zero, e essa é uma armadilha própria: **um produto que tem mesmo zero em estoque também seria
escrito sem a chave `stock`**, e quem lê não consegue distingui-lo de um cujo estoque é desconhecido.
Use `omitempty` só onde zero e ausente querem dizer a mesma coisa.

O `restocked` foi escrito como `"0001-01-01T00:00:00Z"` embora nunca tenha sido preenchido. **O
`omitempty` julga o vazio pelo tipo de dado**: números zero, strings, slices e maps vazios, ponteiros
nil. Uma struct como `time.Time` nunca é vazia por essa regra. O `omitzero`, desde o Go 1.24, julga
pelo zero value do tipo que for, ou pelo método `IsZero` do próprio tipo quando ele tem um, então o
`retired` ficou de fora como se queria.

## Lendo sem um tipo

Decodificar para `map[string]any` é a saída de emergência para JSON cujo formato você não conhece.
**Todo número volta como `float64`**, aqui `qty is 2 of type float64`, porque o JSON não diz quais
números são inteiros. Isso não faz mal para uma quantidade de dois e é errado para um identificador
acima de 2^53, que um `float64` não guarda exatamente; o `Decoder.UseNumber` mantém esses números
como texto. Uma struct é a resposta melhor sempre que o formato é conhecido.

## E uma segunda versão ao lado

O Go 1.27 também traz o `encoding/json/v2`, um desenho mais novo do mesmo pacote, e neste toolchain
o `encoding/json` é construído sobre ele mantendo o comportamento antigo. Os dois diferem em pontos
em que esta lição acabou de se apoiar, e um programa mostra dois deles, salvo como `versions.go`:

```go
// Command versions runs the same value through encoding/json and encoding/json/v2.
package main

import (
	jsonv1 "encoding/json"
	jsonv2 "encoding/json/v2"
	"fmt"
)

type order struct {
	ID    int      `json:"id"`
	Items []string `json:"items"`
}

func main() {
	a, _ := jsonv1.Marshal(order{ID: 1})
	b, _ := jsonv2.Marshal(order{ID: 1})
	fmt.Println("v1:", string(a))
	fmt.Println("v2:", string(b))

	var o1, o2 order
	e1 := jsonv1.Unmarshal([]byte(`{"ID": 7}`), &o1)
	e2 := jsonv2.Unmarshal([]byte(`{"ID": 7}`), &o2)
	fmt.Println("v1:", o1.ID, e1)
	fmt.Println("v2:", o2.ID, e2)
}
```

```
ana@vm:~/jsondemo$ go run versions.go
v1: {"id":1,"items":null}
v2: {"id":1,"items":[]}
v1: 7 <nil>
v2: 0 <nil>
```

**Um slice nil é `null` na v1 e `[]` na v2, e a v2 casa as chaves respeitando maiúsculas**, então
`"ID"` não preenche mais um campo com a tag `id`. Nenhuma das duas está errada; são padrões
diferentes. Este curso usa o `encoding/json`, o pacote que todo programa Go que você vai ler usa
hoje, e o `go doc encoding/json/v2` descreve o resto do mais novo para quando você o encontrar.
