---
title: O JSON volta para dentro
version: 1
---

O `json.Unmarshal` faz o caminho inverso: recebe JSON e preenche um valor Go com ele. A expectativa
errada aqui é o espelho da seção 03. Vindo de uma linguagem tipada, as pessoas esperam que o JSON
seja conferido contra a struct, de modo que uma chave a mais ou a menos seja erro. **Por padrão o
`encoding/json` confere quase nada: chaves desconhecidas são puladas, chaves ausentes deixam os
campos no zero, e os nomes casam com maiúsculas ou minúsculas.** Os três numa execução só:

```go
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name  string   `json:"name"`
	Email string   `json:"email"`
	Tags  []string `json:"tags"`
}

func main() {
	data := []byte(`{"NAME": "Bia", "tags": ["go", "sql"], "nickname": "b"}`)
	var u User
	err := json.Unmarshal(data, &u)
	fmt.Printf("%+v %v\n", u, err)
}
```

```
ana@vm:~/structs-in$ go run .
{Name:Bia Email: Tags:[go sql]} <nil>
```

`"NAME"` preencheu `Name`, embora a tag diga `name`: quando nenhuma chave casa exatamente, o
`encoding/json` aceita uma que difere só em maiúsculas e minúsculas. `"nickname"` não casou com
campo nenhum e foi jogada fora. Não havia `"email"`, então `Email` ficou com o valor zero que tinha
desde o `var`. E `err` é nil: do ponto de vista do programa, nada aconteceu que ele precise saber.

O `&` em `&u` entrega ao `Unmarshal` a própria variável, e não uma cópia dela, para que ele possa
escrever nos campos; a lição 23 trata do `&` e de ponteiros. Esquecê-lo compila, e falha na
execução.

## O que conta como erro

O JSON precisa ser JSON, um valor precisa caber no tipo do campo, e o destino precisa ser algo em
que o `Unmarshal` consiga escrever:

```go
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name string `json:"name"`
}

func main() {
	var u User
	fmt.Println(json.Unmarshal([]byte(`{"name": 42}`), &u))
	fmt.Println(json.Unmarshal([]byte(`{"name": "Bia",}`), &u))
	fmt.Println(json.Unmarshal([]byte(`{"name": "Bia"}`), u))
	fmt.Printf("%+v\n", u)
}
```

```
ana@vm:~/structs-in-bad$ go run .
json: cannot unmarshal number into Go struct field User.name of type string
invalid character '}' looking for beginning of object key string
json: Unmarshal(non-pointer main.User)
{Name:}
ana@vm:~/structs-in-bad$ go vet; echo $?
main.go:16:28: call of Unmarshal passes non-pointer as second argument
1
```

Um número onde cabe uma string é recusado, e a mensagem nomeia o campo pelo tipo Go e pela chave
JSON. Uma vírgula antes do `}` não é JSON, por mais que o JavaScript aceite. A
terceira chamada passou `u` sem `&`, e o `Unmarshal` só pôde recusar; o `go vet` viu essa antes de
qualquer coisa rodar, o que é mais um motivo para rodá-lo. Depois de três falhas `u` continua
vazio: **confira o erro antes de confiar no valor**, que é o assunto inteiro da lição 32.

## Recusando chaves desconhecidas

Pular chaves desconhecidas é o que deixa um programa antigo ler o JSON de um mais novo que
acrescentou um campo. É também o que deixa passar um erro de digitação. Um cliente que manda
`"emial"` não recebe reclamação nenhuma e não tem email guardado. Quando a entrada precisa casar
exatamente com a struct, um `json.Decoder` pode ser instruído a recusar:

```go
package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

type User struct {
	Name  string   `json:"name"`
	Email string   `json:"email"`
	Tags  []string `json:"tags"`
}

func main() {
	data := `{"name": "Bia", "emial": "bia@example.com"}`

	var loose User
	fmt.Println(json.Unmarshal([]byte(data), &loose))
	fmt.Printf("%+v\n", loose)

	var strict User
	dec := json.NewDecoder(strings.NewReader(data))
	dec.DisallowUnknownFields()
	fmt.Println(dec.Decode(&strict))
}
```

```
ana@vm:~/structs-strict$ go run .
<nil>
{Name:Bia Email: Tags:[]}
json: unknown field "emial"
```

O `json.NewDecoder` lê JSON de um fluxo, em vez de um `[]byte` na memória: um arquivo, uma conexão
de rede ou, aqui, uma string embrulhada por `strings.NewReader`. A lição 27 explica o que é um
reader. O `DisallowUnknownFields` liga essa única verificação, e o `Decode` então nomeia a chave que
não reconheceu. **Escolha por entrada**: recuse chaves desconhecidas num arquivo de configuração que
uma pessoa digitou, e pule-as numa mensagem de outro serviço que pode ser mais novo que o seu.

## `encoding/json/v2`

Os comportamentos acima são do `encoding/json`, e no go1.27.1 a biblioteca padrão traz um segundo
pacote ao lado dele. As primeiras linhas da documentação dizem por quê:

```
ana@vm:~/structs-v2$ go doc encoding/json | sed -n 13,15p
For historical reasons, the default behavior of v1 encoding/json unfortunately
operates with less secure defaults. New usages of JSON in Go are encouraged to
use encoding/json/v2 instead.
```

A mesma entrada pelos dois, e a mesma struct saindo pelos dois:

```go
package main

import (
	"encoding/json"
	jsonv2 "encoding/json/v2"
	"fmt"
)

type User struct {
	Name string   `json:"name"`
	Tags []string `json:"tags"`
}

func main() {
	data := []byte(`{"NAME": "Bia"}`)
	var a, b User
	fmt.Println(json.Unmarshal(data, &a), jsonv2.Unmarshal(data, &b))
	fmt.Printf("%+v\n%+v\n", a, b)

	out1, _ := json.Marshal(a)
	out2, _ := jsonv2.Marshal(a)
	fmt.Println(string(out1))
	fmt.Println(string(out2))
}
```

```
ana@vm:~/structs-v2$ go run .
<nil> <nil>
{Name:Bia Tags:[]}
{Name: Tags:[]}
{"name":"Bia","tags":null}
{"name":"Bia","tags":[]}
```

Os dois pacotes se chamam `json`, então o import dá ao segundo o nome `jsonv2`. **A versão 2 casa os
nomes das chaves exatamente**, então `"NAME"` não preencheu nada, e ela escreve uma slice nil como
`[]` em vez de `null`. As tags são as mesmas tags. Ela continua tolerante com chaves desconhecidas
por padrão.

O pacote é novo o bastante para que você leia sobretudo código que usa o primeiro. O toolchain do
laboratório da lição 2 mostra o quanto. O programa em `~/structs-v2old` serializa uma `[]string`
nil com `jsonv2`, num módulo cujo `go.mod` diz `go 1.26.0`.
No go1.26.0 o pacote só existe atrás de uma opção experimental:

```
ana@vm:~/structs-v2old$ go run .
[]
ana@vm:~/structs-v2old$ GOTOOLCHAIN=go1.26.0 go run .
package example.com/v2old
	imports encoding/json/v2: build constraints exclude all Go files in /home/ana/go/pkg/mod/golang.org/toolchain@v0.0.1-go1.26.0.linux-amd64/src/encoding/json/v2
ana@vm:~/structs-v2old$ GOTOOLCHAIN=go1.26.0 GOEXPERIMENT=jsonv2 go run .
[]
```

Então um módulo que importa `encoding/json/v2` precisa do go1.27 para compilar sem configurar nada,
e essa é uma decisão sobre quem consegue compilar o seu código. **Seja qual for o pacote, a struct é
o contrato**: os campos exportados e as tags são o que sai, e o que entra só é conferido até onde
você pediu.
