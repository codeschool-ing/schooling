---
title: Unmarshal, de um documento para um valor Go
version: 1
---

Ler JSON é onde estão as surpresas, porque o documento vem de outra pessoa e não foi escrito contra
os seus tipos. **O `encoding/json` é tolerante por padrão, e cada tipo de tolerância é uma decisão
que vale saber que ele tomou por você.** O programa lê um corpo de quatro jeitos, salvo como
`decode.go`:

```go
// Command decode reads JSON into a struct: what it forgives, and what it refuses.
package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

type Order struct {
	ID       int    `json:"id"`
	Customer string `json:"customer"`
	Items    []struct {
		SKU string `json:"sku"`
		Qty int    `json:"qty"`
	} `json:"items"`
}

func main() {
	body := `{"id": 1042, "Customer": "ana@example.com",
		"items": [{"sku": "KB-01", "qty": 1}], "coupon": "WELCOME"}`

	var o Order
	err := json.Unmarshal([]byte(body), &o)
	fmt.Printf("%+v %v\n", o, err)

	dec := json.NewDecoder(strings.NewReader(body))
	dec.DisallowUnknownFields()
	var strict Order
	fmt.Println("strict:", dec.Decode(&strict))

	var wrongType Order
	fmt.Println("type:", json.Unmarshal([]byte(`{"id": "1042"}`), &wrongType))

	var broken Order
	fmt.Println("syntax:", json.Unmarshal([]byte(`{"id": 1042,}`), &broken))
}
```

```
ana@vm:~/jsondemo$ go run decode.go
{ID:1042 Customer:ana@example.com Items:[{SKU:KB-01 Qty:1}]} <nil>
strict: json: unknown field "coupon"
type: json: cannot unmarshal string into Go struct field Order.id of type int
syntax: invalid character '}' looking for beginning of object key string
```

## O que ele perdoou

**A chave `Customer` preencheu o campo com a tag `customer`.** O `encoding/json` casa chaves com
campos sem ligar para maiúsculas e minúsculas, então quem envia com outra capitalização ainda passa.
**A chave `coupon` não casou com nada e foi descartada sem uma palavra.** O `Order` saiu completo, e o
`err` foi `nil`. As duas coisas são convenientes quando o outro lado acrescenta um campo que ainda
não interessa a você, que é como APIs crescem sem quebrar os clientes.

Elas são perigosas quando um campo que falta significa um engano. Um cliente que manda `"cupon"` em
vez de `"coupon"` fica sem desconto e sem erro. **O `Decoder.DisallowUnknownFields` transforma o
silêncio num erro**, `json: unknown field "coupon"`, e um servidor que prefere recusar uma requisição
a entendê-la pela metade o liga. A escolha é de quem é dono da API, e deve ser feita de propósito.

## O que ele recusou

**Uma string onde o tipo diz `int` é um erro**, e a mensagem cita o campo pelo caminho Go e pela
chave JSON, `Order.id`, e os dois tipos. Nada é convertido por você, que é a mesma regra que a lição
10 de `go` deu para a própria linguagem. **Um documento que nem é JSON**, aqui com uma vírgula
sobrando no fim, falha antes de qualquer campo ser olhado, com o caractere e o que se esperava no
lugar.

Então confira o erro de todo `Unmarshal` e de todo `Decode`. A struct depois de uma chamada que
falhou pode estar preenchida em parte, sem sinal de onde parou.

## Unmarshal ou Decoder

O `json.Unmarshal` recebe um `[]byte` já na memória. O `json.NewDecoder` recebe um `io.Reader` e lê o
quanto precisar, o que serve para um arquivo, uma conexão de rede ou o corpo de uma requisição
HTTP, o caso que a lição 28 testa. Um Decoder também lê um valor depois do outro do mesmo fluxo,
que é como se lê JSON Lines de volta. E ele é o único dos dois que tem a chave
`DisallowUnknownFields`.
