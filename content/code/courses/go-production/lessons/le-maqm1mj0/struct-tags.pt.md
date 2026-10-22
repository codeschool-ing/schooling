---
title: Tags de struct, lidas do jeito que o encoding/json as lê
version: 1
---

Uma tag de struct é a string entre crases depois de um campo, e **o compilador a guarda e nunca olha
dentro dela**. Ela não tem efeito nenhum sobre o programa até que algo a leia na execução, e o único
jeito de lê-la é a reflexão. A lição 15 do curso `go` escreveu tags `json:"name"` e a lição 19 do
`go-concurrency` usou `omitempty`; esta seção lê as mesmas tags pelo outro lado, como o codificador
lê, e depois constrói algo próprio em cima delas para o `hits`.

## Get, Lookup e a descrição do campo

O `reflect.Type` descreve cada campo com um `StructField`: o nome, o tipo, se é exportado e a `Tag`,
do tipo `StructTag`. `Tag.Get("json")` devolve o valor guardado sob uma chave, e `Tag.Lookup` devolve
o mesmo valor com um segundo resultado dizendo se a chave estava lá. Uma struct com um campo para
cada situação em que uma tag `json` pode estar, e depois o `encoding/json` consultado sobre a mesma
struct, em `tags/main.go`:

```go
// Command tags reads a struct's tags the way encoding/json does, and then
// asks encoding/json for its own answer.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"reflect"
	"time"
)

// Row has one field for each case a json tag can be in.
type Row struct {
	Path    string        `json:"path"`
	Hits    int           `json:"hits,omitempty"`
	Total   time.Duration `json:"-"`
	Method  string        `json:",omitempty"`
	Status  int
	comment string `json:"comment"`
}

func main() {
	t := reflect.TypeFor[Row]()
	for f := range t.Fields() {
		tag, ok := f.Tag.Lookup("json")
		fmt.Printf("%-8s exported=%-5t json=%-18q present=%t\n", f.Name, f.IsExported(), tag, ok)
	}

	r := Row{Path: "/login", Total: time.Second, Method: "GET", Status: 200, comment: "busy"}
	out, err := json.Marshal(r)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Println(string(out))

	c := reflect.ValueOf(r).FieldByName("comment")
	fmt.Printf("comment: %q, CanInterface=%t\n", c.String(), c.CanInterface())
	fmt.Println(c.Interface())
}
```

`reflect.TypeFor[Row]()` é o `TypeOf` para quando você tem o tipo e nenhum valor. Rodado, com a
última linha cometendo um erro de propósito:

```
ana@vm:~/reflect$ go run ./tags
Path     exported=true  json="path"             present=true
Hits     exported=true  json="hits,omitempty"   present=true
Total    exported=true  json="-"                present=true
Method   exported=true  json=",omitempty"       present=true
Status   exported=true  json=""                 present=false
comment  exported=false json="comment"          present=true
{"path":"/login","Method":"GET","Status":200}
comment: "busy", CanInterface=false
panic: reflect.Value.Interface: cannot return value obtained from unexported field or method

goroutine 1 [running]:
reflect.valueInterface({0x64ac58?, 0x533ae0?, 0x527549?}, 0x1d?)
	/usr/local/go/src/reflect/value.go:1501 +0xde
reflect.Value.Interface(...)
	/usr/local/go/src/reflect/value.go:1490
main.main()
	/home/ana/reflect/tags/main.go:40 +0x2f0
exit status 2
```

**Cada decisão da linha de JSON pode ser lida na tabela acima dela.** `Path` saiu como `path`, o
nome da tag. `Hits` tem `omitempty` e guarda 0, então ficou de fora. `Total` tem a tag `-`, que quer
dizer nunca. A tag de `Method` está presente, mas com o nome vazio, então o campo ficou com o próprio
nome, e `Status` não tem tag nenhuma, o que o `Lookup` informa como `present=false` e o `Get` não
consegue distinguir de uma tag vazia. `comment` não é exportado, e nada dele chegou à saída.

Este é o código do próprio codificador, algumas linhas dentro da função que monta a lista de campos:

```
ana@vm:~/reflect$ sed -n 1133,1141p /usr/local/go/src/encoding/json/encode.go
				} else if !sf.IsExported() {
					// Ignore unexported non-embedded fields.
					continue
				}
				tag := sf.Tag.Get("json")
				if tag == "-" {
					continue
				}
				name, opts := parseTag(tag)
```

`!sf.IsExported()`, `sf.Tag.Get("json")`, `tag == "-"`: as mesmas chamadas que o `tags/main.go` fez.
**Não há mágica no `encoding/json` além da reflexão**, e depois que ele monta a lista de um tipo,
guarda essa lista, então as tags são lidas uma vez por tipo, e não uma vez por valor.

## O que um campo não exportado permite

A ideia errada aqui é que a reflexão não enxerga um campo não exportado. Enxerga: `comment` está na
tabela, e `c.String()` leu `"busy"` dele. **O que a reflexão recusa é deixar o valor sair como `any`,
ou alterá-lo.** O `CanInterface` diz false, e o `Interface` entrou em pânico com a frase acima. O
motivo é a fronteira de pacote da lição 39 do curso `go`. Se qualquer pacote pudesse tirar um campo
não exportado como `any`, ou alterá-lo, um nome em minúscula não protegeria nada, então a regra vale
também para a reflexão. A seção 04 mostra a recusa a alterar.

**Uma tag num campo não exportado é, portanto, um erro, e o `go vet` sabe disso:**

```
ana@vm:~/reflect$ go vet ./tags
tags/main.go:20:2: struct field comment has json tag but is not exported
```

## Um seletor de colunas para o `hits`

O `hits top -json` da lição 1 imprime `path` e `hits`, os nomes das tags de `tally.PathCount`. Um
comando pequeno que imprime colunas escolhidas dessa tabela pelos mesmos nomes é um trabalho
realista para a reflexão: os nomes que um usuário digita são os nomes das tags, e o código que os
procura não sabe nada sobre `PathCount`. Ele fica num módulo novo, `~/reflect-hits`, criado com
`go mod init example.com/hits`, com o pacote `tally` da lição 1 (`internal/tally/tally.go`), o
`tools/genlog` dela e um `access.log` escrito pelo comando da lição 1,
`go run ./tools/genlog -n 20000 > access.log`. O pacote novo é `internal/columns/columns.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/columns/columns.go",
  "parts": [
    {
      "code": "// Package columns prints chosen fields of a slice of structs as a table,\n// naming each field the way encoding/json would.\npackage columns\n\nimport (\n\t\"errors\"\n\t\"fmt\"\n\t\"io\"\n\t\"reflect\"\n\t\"strconv\"\n\t\"strings\"\n\t\"text/tabwriter\"\n)\n\n// ErrUnknown is returned for a column name no field answers to.\nvar ErrUnknown = errors.New(\"unknown column\")\n",
      "note": "Um erro sentinela, para o comando distinguir uma coluna que ninguém tem de uma escrita que falhou (o 2 contra o 1 da lição 1)."
    },
    {
      "code": "// Reflect prints the named columns of rows, which must be a slice of\n// structs. It finds each column by reading the struct's json tags.\nfunc Reflect(w io.Writer, rows any, names []string) error {\n\tv := reflect.ValueOf(rows)\n\tif v.Kind() != reflect.Slice || v.Type().Elem().Kind() != reflect.Struct {\n\t\treturn fmt.Errorf(\"columns: want a slice of structs, got %T\", rows)\n\t}",
      "note": "**`rows any` aceita qualquer coisa, então a conferência que o compilador faria é feita aqui, na execução**: uma slice, de structs. O `%T` dá o nome do que veio no lugar."
    },
    {
      "code": "\tt := v.Type().Elem()\n\tindex := make([]int, len(names))\n\tfor i, name := range names {\n\t\tj, ok := fieldNamed(t, name)\n\t\tif !ok {\n\t\t\treturn fmt.Errorf(\"%w %q: %v has no such field\", ErrUnknown, name, t)\n\t\t}\n\t\tindex[i] = j\n\t}\n",
      "note": "Cada nome é procurado uma vez, antes de qualquer linha ser impressa, e vira um índice de campo. Um nome que ninguém atende falha aqui, com o tipo na mensagem."
    },
    {
      "code": "\ttw := tabwriter.NewWriter(w, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, strings.Join(names, \"\\t\"))\n\tcells := make([]string, len(index))\n\tfor r := range v.Len() {\n\t\trow := v.Index(r)\n\t\tfor i, j := range index {\n\t\t\tcells[i] = text(row.Field(j))\n\t\t}\n\t\tfmt.Fprintln(tw, strings.Join(cells, \"\\t\"))\n\t}\n\treturn tw.Flush()\n}\n",
      "note": "O laço lê cada linha pelo `Index` e cada célula pelo `Field(j)`, por posição. Nada nele sabe que as linhas são `tally.PathCount`."
    },
    {
      "code": "// fieldNamed finds the field encoding/json would call name: the name in its\n// json tag, or its own name when the tag gives none. A field that is not\n// exported, or is tagged \"-\", has no name at all.\nfunc fieldNamed(t reflect.Type, name string) (int, bool) {\n\tfor f := range t.Fields() {\n\t\ttag := f.Tag.Get(\"json\")\n\t\tif !f.IsExported() || tag == \"-\" {\n\t\t\tcontinue\n\t\t}\n\t\tn, _, _ := strings.Cut(tag, \",\")\n\t\tif n == \"\" {\n\t\t\tn = f.Name\n\t\t}\n\t\tif n == name {\n\t\t\treturn f.Index[0], true\n\t\t}\n\t}\n\treturn 0, false\n}\n",
      "note": "**A regra que o `encoding/json` aplica, por extenso**: pular o que não é exportado ou tem tag `-`, pegar o nome da tag até a primeira vírgula, e voltar ao nome do próprio campo quando a tag não dá nenhum."
    },
    {
      "code": "// text formats one cell. The kinds a log's rows hold get their own\n// conversion; anything else goes through fmt.\nfunc text(v reflect.Value) string {\n\tswitch v.Kind() {\n\tcase reflect.String:\n\t\treturn v.String()\n\tcase reflect.Int, reflect.Int64:\n\t\treturn strconv.FormatInt(v.Int(), 10)\n\t}\n\treturn fmt.Sprint(v.Interface())\n}",
      "note": "Um switch no `Kind`, do jeito que o `encoding/json` escolhe um codificador: uma string e um inteiro são convertidos direto, e o resto passa pelo `fmt`, que reflete sobre o valor de novo."
    }
  ]
}
```

E um comando na frente dele, que conta o log com o `tally` e entrega as linhas ao `columns.Reflect`,
em `cmd/cols/main.go`:

```go
// Command cols prints chosen columns of the busiest paths in an access log.
package main

import (
	"errors"
	"flag"
	"fmt"
	"os"
	"strings"

	"example.com/hits/internal/columns"
	"example.com/hits/internal/tally"
)

func main() {
	fields := flag.String("fields", "path,hits", "columns to print, by their json names")
	n := flag.Int("n", 3, "how many paths to show")
	flag.Parse()
	if flag.NArg() != 1 {
		fmt.Fprintln(os.Stderr, "usage: cols [-fields a,b] [-n N] file")
		os.Exit(2)
	}
	f, err := os.Open(flag.Arg(0))
	if err != nil {
		fmt.Fprintf(os.Stderr, "cols: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()
	s, err := tally.Count(f)
	if err != nil {
		fmt.Fprintf(os.Stderr, "cols: %v\n", err)
		os.Exit(1)
	}
	err = columns.Reflect(os.Stdout, tally.Top(s, *n), strings.Split(*fields, ","))
	if errors.Is(err, columns.ErrUnknown) {
		fmt.Fprintf(os.Stderr, "cols: %v\n", err)
		os.Exit(2)
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "cols: %v\n", err)
		os.Exit(1)
	}
}
```

Compilado, consultado sobre as colunas padrão, depois sobre as duas na outra ordem e com cinco
linhas, e depois duas vezes sobre uma coluna que não existe:

```
ana@vm:~/reflect-hits$ go build -o cols ./cmd/cols && ./cols access.log
path            hits
/login          2576
/api/orders     2542
/static/app.js  2526
ana@vm:~/reflect-hits$ ./cols -fields hits,path -n 5 access.log
hits  path
2576  /login
2542  /api/orders
2526  /static/app.js
2512  /api/users
2503  /api/orders/42
ana@vm:~/reflect-hits$ ./cols -fields path,hist access.log; echo $?
cols: unknown column "hist": tally.PathCount has no such field
2
ana@vm:~/reflect-hits$ ./cols -fields Hits access.log; echo $?
cols: unknown column "Hits": tally.PathCount has no such field
2
```

As contagens são as da lição 1, com `/login` e 2576 em primeiro. **`Hits` é recusado embora o campo
em Go se chame `Hits`**, porque a regra que o `fieldNamed` copia diz que o nome da tag substitui o do
campo, e a tag diz `hits`. As duas recusas saem com 2, o código que a lição 1 dá a um erro de quem
chama, porque o comando conseguiu distinguir o `ErrUnknown` de uma escrita que falhou.

**Nada no `Reflect` cita `PathCount`, e foi isso que a reflexão comprou**: entregue a ele uma slice de
qualquer struct com tags e ele imprime aquelas colunas também. Ela também custou algo que a
transcrição ainda não mostra. O `Reflect` recebe `rows any`, então o compilador aceita qualquer
valor ali, e a conferência que ele faria passa a acontecer a cada chamada, na execução. A seção 05
mede esse custo e, ao lado dele, o de velocidade.
