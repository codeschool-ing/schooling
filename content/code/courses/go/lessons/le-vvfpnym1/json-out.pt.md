---
title: Uma struct sai como JSON
version: 1
---

O `encoding/json` transforma um valor Go em JSON com `json.Marshal`, e para uma struct o resultado
é um objeto JSON com uma chave por campo. A expectativa errada é que ele escreva *todos* os campos.
**Ele escreve os campos exportados, aqueles cujo nome começa com letra maiúscula, e deixa o resto de
fora sem dizer nada.** Aqui está um `User` sem instrução nenhuma:

```go
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name     string
	Email    string
	Password string
	Tags     []string
	age      int
}

func main() {
	u := User{Name: "Ana", Password: "hunter2", age: 31}
	b, err := json.Marshal(u)
	fmt.Println(string(b), err)
}
```

```
ana@vm:~/structs-json-plain$ go run .
{"Name":"Ana","Email":"","Password":"hunter2","Tags":null} <nil>
```

O `Marshal` devolve o JSON como um `[]byte` e um erro, e `<nil>` quer dizer que não houve erro; a
lição 32 trata de erros. Quatro coisas nessa única linha merecem leitura:

- as chaves são os nomes dos campos em Go, com maiúscula e tudo, porque nada disse o contrário;
- o `Email` vazio foi escrito como `""`, já que uma string vazia continua sendo string;
- **a senha saiu**, e essa é a linha que acaba num log que ninguém pretendia guardar;
- `age` não está lá, e `err` continua nil.

A última surpreende todo mundo uma vez. O `json.Marshal` mora em outro pacote, e um nome que começa
com letra minúscula não é visível de outro pacote. A lição 4 mencionou a letra maiúscula e a lição
39 é sobre ela. Por causa dessa regra, um campo que você queria enviar mas batizou com minúscula
some da saída, e nenhum compilador, nenhuma verificação do vet e nenhum erro avisa. `Tags` saiu como
`null` porque era uma slice nil, a distinção que a lição 12 apontou.

## Tags: instruções escritas no campo

Uma **tag de struct** é uma string escrita depois do tipo de um campo, e o `encoding/json` lê a
parte dela que fica sob a chave `json`. O mesmo `User`, com tags:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"encoding/json\"\n\t\"fmt\"\n)\n\ntype User struct {\n\tName     string   `json:\"name\"`\n",
      "note": "**A primeira palavra de uma tag json é a chave a usar**, então `Name` sai como `name`. Uma tag é um literal de string cru, os acentos graves da lição 9, porque está cheia de aspas duplas."
    },
    {
      "code": "\tEmail    string   `json:\"email,omitempty\"`\n",
      "note": "**`omitempty` deixa o campo de fora quando ele está vazio**: `false`, `0`, um ponteiro ou interface nil, ou um array, slice, map ou string de comprimento zero."
    },
    {
      "code": "\tPassword string   `json:\"-\"`\n",
      "note": "**Uma tag `-` mantém o campo fora do JSON sempre**, vazio ou não. É assim que se marca um campo que nunca pode sair do programa."
    },
    {
      "code": "\tTags     []string `json:\"tags\"`\n\tage      int\n}\n",
      "note": "`tags` tem nome e nenhuma opção, então uma slice nil continua saindo como `null`. `age` não precisa de tag para ficar de fora; fica de fora por causa da primeira letra."
    },
    {
      "code": "\nfunc main() {\n\tu := User{Name: \"Ana\", Password: \"hunter2\", age: 31}\n\tb, err := json.Marshal(u)\n\tfmt.Println(string(b), err)\n\n\tu.Email = \"ana@example.com\"\n\tu.Tags = []string{\"go\", \"sql\"}\n\tb, err = json.MarshalIndent(u, \"\", \"  \")\n\tfmt.Println(string(b), err)\n}\n",
      "note": "O mesmo valor duas vezes: uma com `Email` vazio, outra preenchido. O `json.MarshalIndent` é o `Marshal` com quebras de linha, indentando cada nível com o último argumento, aqui dois espaços."
    }
  ],
  "output": "{\"name\":\"Ana\",\"tags\":null} <nil>\n{\n  \"name\": \"Ana\",\n  \"email\": \"ana@example.com\",\n  \"tags\": [\n    \"go\",\n    \"sql\"\n  ]\n} <nil>"
}
```

A primeira linha não tem `email`, porque ele estava vazio e a tag mandou omitir, nem `Password`,
porque a tag disse nunca. A segunda tem o `email` de volta. A figura é a seção inteira num lugar só:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A struct User tem cinco campos. Name, com a tag json name, é escrito como a chave name. Email, com a tag json email omitempty, é escrito como a chave email só quando não está vazio. Password, com a tag json traço, nunca é escrito. Tags, com a tag json tags, é escrito como a chave tags, e uma slice nil sai como null. O campo age começa com letra minúscula, então o json.Marshal não o enxerga e o deixa de fora sem avisar.\"><defs><marker id=\"js-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"156.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a struct, em Go</text><text x=\"562.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o que o json.Marshal escreve</text><rect x=\"16\" y=\"42\" width=\"280\" height=\"186\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"28\" y=\"67.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Name string `json:&quot;name&quot;`</text><rect x=\"420\" y=\"54.0\" width=\"284\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432\" y=\"67.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;name&quot;: &quot;Ana&quot;</text><path d=\"M302 67.0 L414 67.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#js-phosphor)\"></path><text x=\"28\" y=\"101.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Email string `json:&quot;email,omitempty&quot;`</text><rect x=\"420\" y=\"88.0\" width=\"284\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"432\" y=\"101.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;email&quot;: &quot;...&quot;</text><path d=\"M302 101.0 L414 101.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#js-phosphor)\"></path><text x=\"694\" y=\"101.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só quando não está vazio</text><text x=\"28\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Password string `json:&quot;-&quot;`</text><path d=\"M302 135.0 L340 135.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M340 126.0 L340 144.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"350\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nunca: a tag é &quot;-&quot;</text><text x=\"28\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Tags []string `json:&quot;tags&quot;`</text><rect x=\"420\" y=\"156.0\" width=\"284\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;tags&quot;: null</text><path d=\"M302 169.0 L414 169.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#js-phosphor)\"></path><text x=\"694\" y=\"169.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma slice nil vira null</text><text x=\"28\" y=\"203.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">age int</text><path d=\"M302 203.0 L340 203.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M340 194.0 L340 212.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"350\" y=\"203.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nunca, e nada avisa: minúscula</text></svg>", "caption": "Cinco campos entram e três chaves podem sair. A tag decide o nome e se o campo é escrito; a primeira letra do nome do campo decide se o encoding/json consegue enxergá-lo."}
```

## O compilador não lê tags

Para o compilador, uma tag é uma string comum. **Um erro de digitação numa tag compila, roda e é
ignorado**, e o campo volta discretamente ao comportamento padrão:

```go
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name  string `json: "name"`
	Email string `json:"email, omitempty"`
}

func main() {
	b, _ := json.Marshal(User{Name: "Ana"})
	fmt.Println(string(b))
}
```

```
ana@vm:~/structs-tags-bad$ go run .
{"Name":"Ana","email":""}
ana@vm:~/structs-tags-bad$ go vet; echo $?
main.go:9:2: struct field tag `json: "name"` not compatible with reflect.StructTag.Get: bad syntax for struct tag value
main.go:10:2: struct field tag `json:"email, omitempty"` not compatible with reflect.StructTag.Get: suspicious space in struct tag value
1
```

Um espaço em cada tag. Na primeira, depois dos dois-pontos, a tag inteira fica ilegível, e `Name`
saiu com o nome de Go. Na segunda, antes de `omitempty`, a opção virou ` omitempty` com um espaço na
frente, o que não é opção nenhuma, e o email vazio foi escrito. O `go run` aceitou as duas; o
`go vet` achou as duas. É o conselho da lição 4 de novo, com um motivo mais afiado: **rode o
`go vet` em tudo que tem tag de struct**, porque ele é a única ferramenta aqui que as lê antes do
`encoding/json`.

## `omitempty` e `omitzero`

O `omitempty` tem uma brecha, e um tipo da biblioteca padrão cai direto nela. A hora do dia é uma
struct, `time.Time`, e uma struct nunca é "vazia" por aquela definição, por mais zero que esteja:

```go
package main

import (
	"encoding/json"
	"fmt"
	"time"
)

type Event struct {
	Name    string    `json:"name"`
	Retries int       `json:"retries,omitempty"`
	Started time.Time `json:"started,omitempty"`
	Ended   time.Time `json:"ended,omitzero"`
}

func main() {
	b, _ := json.Marshal(Event{Name: "deploy"})
	fmt.Println(string(b))
}
```

```
ana@vm:~/structs-omitzero$ go run .
{"name":"deploy","started":"0001-01-01T00:00:00Z"}
```

`Retries` era 0 e o `omitempty` o tirou. `Started` era o `time.Time` zero e o `omitempty` o escreveu
mesmo assim, como o primeiro instante do ano 1, que um leitor vai tomar por data de verdade. `Ended`
tinha o mesmo valor zero e **o `omitzero` o tirou, porque ele deixa de fora um campo que guarda o
valor zero do seu tipo, seja qual for o tipo.** A documentação do `json.Marshal` no go1.27.1 também
diz que, quando o tipo tem um método `IsZero() bool`, como `time.Time` tem, o `omitzero` pergunta a
ele. Para um campo de tipo struct, o `omitzero` é o que faz o que o nome do outro promete.
