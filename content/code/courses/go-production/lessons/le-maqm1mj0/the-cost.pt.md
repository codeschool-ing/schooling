---
title: O que a reflexão custa, e o que escrever no lugar
version: 1
---

A reflexão tem fama de lenta, e é nessa fama que a maioria das pessoas para de pensar no custo dela.
**A velocidade é o menor dos dois custos, e o tamanho dele depende do que cerca o código reflexivo. O
custo maior são as conferências do compilador, que a reflexão abandona por inteiro.** Esta seção mede
o primeiro e mostra o segundo, no seletor de colunas da seção 03 e numa versão dele escrita sem
`reflect`.

## A mesma tabela sem reflexão

As colunas de um `tally.PathCount` são duas, e dá para escrevê-las à mão: um nome e uma função que
imprime a célula de uma linha. Tornada genérica no tipo da linha, como nas lições 30 e 31 do curso
`go`, a mesma `Table` serve para qualquer tipo de linha a que alguém dê uma lista de colunas. No
mesmo pacote, `internal/columns/table.go`:

```go
package columns

import (
	"fmt"
	"io"
	"slices"
	"strconv"
	"strings"
	"text/tabwriter"

	"example.com/hits/internal/tally"
)

// Column is one column a table can show: its name and how to print a row's
// cell in it.
type Column[T any] struct {
	Name string
	Cell func(T) string
}

// PathColumns are the columns of a tally.PathCount, written out by hand.
var PathColumns = []Column[tally.PathCount]{
	{"path", func(r tally.PathCount) string { return r.Path }},
	{"hits", func(r tally.PathCount) string { return strconv.Itoa(r.Hits) }},
}

// Table prints the named columns of rows, taking each one from cols.
func Table[T any](w io.Writer, rows []T, cols []Column[T], names []string) error {
	pick := make([]Column[T], len(names))
	for i, name := range names {
		j := slices.IndexFunc(cols, func(c Column[T]) bool { return c.Name == name })
		if j < 0 {
			return fmt.Errorf("%w %q", ErrUnknown, name)
		}
		pick[i] = cols[j]
	}

	tw := tabwriter.NewWriter(w, 0, 0, 2, ' ', 0)
	fmt.Fprintln(tw, strings.Join(names, "\t"))
	cells := make([]string, len(pick))
	for _, r := range rows {
		for i, c := range pick {
			cells[i] = c.Cell(r)
		}
		fmt.Fprintln(tw, strings.Join(cells, "\t"))
	}
	return tw.Flush()
}
```

Nada aqui é procurado na execução, a não ser os nomes de coluna que um usuário digitou. **`r.Path` e
`r.Hits` são acessos comuns a campos, então o compilador os confere**, e a `Table` não aceita nada
além de uma slice do tipo para o qual as colunas foram escritas. Um teste de que as duas versões
imprimem os mesmos bytes, benchmarks das duas e mais três jeitos de ler um campo sem nada em volta,
em `internal/columns/columns_test.go`:

```go
package columns

import (
	"bytes"
	"io"
	"reflect"
	"testing"

	"example.com/hits/internal/tally"
)

// rows are the eight paths of the 20,000-line log, as tally.Top returns them.
var rows = tally.Top(tally.Summary{ByPath: map[string]int{
	"/login": 2576, "/api/orders": 2542, "/static/app.js": 2526, "/api/users": 2512,
	"/api/orders/42": 2503, "/static/app.css": 2490, "/": 2487, "/health": 2364,
}}, 8)

var names = []string{"path", "hits"}

func TestSameTable(t *testing.T) {
	var a, b bytes.Buffer
	if err := Reflect(&a, rows, names); err != nil {
		t.Fatal(err)
	}
	if err := Table(&b, rows, PathColumns, names); err != nil {
		t.Fatal(err)
	}
	if a.String() != b.String() {
		t.Errorf("Reflect printed\n%s\nTable printed\n%s", a.String(), b.String())
	}
}

func BenchmarkReflect(b *testing.B) {
	for b.Loop() {
		Reflect(io.Discard, rows, names)
	}
}

func BenchmarkTable(b *testing.B) {
	for b.Loop() {
		Table(io.Discard, rows, PathColumns, names)
	}
}

// The three ways to read one field, without a table around them.
var sum int

func BenchmarkFieldDirect(b *testing.B) {
	for b.Loop() {
		for _, r := range rows {
			sum += r.Hits
		}
	}
}

func BenchmarkFieldIndex(b *testing.B) {
	v := reflect.ValueOf(rows)
	for b.Loop() {
		for i := range v.Len() {
			sum += int(v.Index(i).Field(1).Int())
		}
	}
}

func BenchmarkFieldByName(b *testing.B) {
	v := reflect.ValueOf(rows)
	for b.Loop() {
		for i := range v.Len() {
			sum += int(v.Index(i).FieldByName("Hits").Int())
		}
	}
}
```

Os benchmarks usam a forma com `b.Loop` que a lição 29 do `go-concurrency` ensinou, e o `-count=3`
roda cada um três vezes para a variação ficar visível:

```
ana@vm:~/reflect-hits$ go vet ./... && go test -count=1 ./internal/columns
ok  	example.com/hits/internal/columns	0.002s
ana@vm:~/reflect-hits$ go test -run "^$" -bench . -benchmem -count=3 ./internal/columns
goos: linux
goarch: amd64
pkg: example.com/hits/internal/columns
cpu: Intel(R) Xeon(R) Processor
BenchmarkReflect-4       	  293695	      4665 ns/op	    2272 B/op	      58 allocs/op
BenchmarkReflect-4       	  282636	      4909 ns/op	    2272 B/op	      58 allocs/op
BenchmarkReflect-4       	  268616	      4475 ns/op	    2272 B/op	      58 allocs/op
BenchmarkTable-4         	  348522	      3985 ns/op	    2072 B/op	      50 allocs/op
BenchmarkTable-4         	  366930	      4382 ns/op	    2072 B/op	      50 allocs/op
BenchmarkTable-4         	  339334	      3976 ns/op	    2072 B/op	      50 allocs/op
BenchmarkFieldDirect-4   	72886593	        15.37 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldDirect-4   	77271601	        15.47 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldDirect-4   	73453356	        15.37 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldIndex-4    	31072404	        39.80 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldIndex-4    	31684237	        38.74 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldIndex-4    	31851861	        37.52 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldByName-4   	 3184506	       376.3 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldByName-4   	 2936642	       393.2 ns/op	       0 B/op	       0 allocs/op
BenchmarkFieldByName-4   	 3161532	       409.6 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	example.com/hits/internal/columns	19.102s
```

Os tempos mudam de uma rodada para outra numa máquina compartilhada, e o terceiro dígito não quer
dizer nada. **O que se mantém nas três rodadas são as proporções e as contagens de alocação**:

| benchmark | ns/op, três rodadas | contra o direto | alocações |
|---|---|---|---|
| `FieldDirect`, `r.Hits` | 15,37 a 15,47 | 1 | 0 |
| `FieldIndex`, `Index(i).Field(1).Int()` | 37,52 a 39,80 | cerca de 2,5 vezes | 0 |
| `FieldByName`, `FieldByName("Hits")` | 376,3 a 409,6 | cerca de 25 vezes | 0 |
| `Table`, a tabela inteira | 3976 a 4382 | | 50 |
| `Reflect`, a tabela inteira | 4475 a 4909 | | 58 |

Ler um campo pelo índice custa alguns nanossegundos a mais que ler direto, porque cada chamada
confere o kind e calcula o endereço do campo. **Ler pelo nome é dez vezes pior ainda**, já que o
`FieldByName` percorre os campos da struct comparando strings e monta um `StructField` completo para
o que achou, a cada chamada. É por isso que o `columns.Reflect` transforma cada nome num índice uma
vez, antes do laço, e que o `encoding/json` guarda a lista de campos por tipo. Um código que chama
`FieldByName` dentro de um laço paga as 25 vezes em cada linha.

**Em volta de uma tabela inteira, a diferença cai para cerca de um sexto**, 4665 ns contra 3985
tomando a mediana de cada trio, porque a maior parte do tempo vai para o `tabwriter`, o
`strings.Join` e a escrita, que as duas versões têm em comum. O `Reflect` também fez 8 alocações e
200 bytes a mais por tabela, 58 contra 50. No `hits`, onde o `tally.Count` gasta muito mais tempo
lendo 20.000 linhas do que qualquer das versões gasta imprimindo oito, ninguém notaria a diferença
sem um benchmark. As lições 12 e 13 são onde um perfil diz se um custo assim é o que vale remover.

## As conferências que foram abandonadas

O custo que alguém notaria é um erro que compila. Suponha que alguém decida que o `cols` deve
imprimir só o caminho mais acessado e acrescente `[0]` à chamada em `cmd/cols/main.go`:

```
ana@vm:~/reflect-hits$ sed -i "s/tally.Top(s, \*n)/tally.Top(s, *n)[0]/" cmd/cols/main.go
ana@vm:~/reflect-hits$ go vet ./... && go build -o cols ./cmd/cols && ./cols access.log; echo $?
cols: columns: want a slice of structs, got tally.PathCount
1
```

O `go vet` e o compilador não tiveram nada a dizer, porque um `tally.PathCount` é um `any`
perfeitamente válido. **O erro apareceu quando o programa rodou, e só porque o `Reflect` confere se
recebeu uma slice e devolve um erro**; sem essa conferência, teria sido um pânico. Agora um erro de
digitação na versão sem reflexão:

```
ana@vm:~/reflect-hits$ sed -i "s/r.Hits)/r.Hist)/" internal/columns/table.go
ana@vm:~/reflect-hits$ go build ./...
# example.com/hits/internal/columns
internal/columns/table.go:24:66: r.Hist undefined (type tally.PathCount has no field or method Hist)
```

Esse nunca chegou a um binário. As duas edições desfeitas, e o comando de volta aos números da lição
1:

```
ana@vm:~/reflect-hits$ sed -i "s/r.Hist)/r.Hits)/" internal/columns/table.go
ana@vm:~/reflect-hits$ sed -i "s/tally.Top(s, \*n)\[0\]/tally.Top(s, *n)/" cmd/cols/main.go
ana@vm:~/reflect-hits$ go build -o cols ./cmd/cols && ./cols -n 1 access.log
path    hits
/login  2576
```

As tags têm a mesma fraqueza um nível abaixo. O `go vet` confere a sintaxe de uma tag, como mostrou a
lição 15 do curso `go`, e, como a seção 03 mostrou, uma tag num campo não exportado. **Ele não tem
como conferir o significado de uma tag**: troque `json:"hits"` por `json:"hist"` no `tally` e tudo
continua compilando, o `hits top -json` passa a imprimir outra chave, e o primeiro sinal é um painel
que fica em branco em outro lugar. Renomear um campo com a ferramenta de refatoração do editor
corrige todo `r.Hits`; ela não toca numa string.

## Quando a reflexão é a ferramenta certa

Nada disso torna a reflexão errada. **Ela é certa quando os tipos não são conhecidos pelo código de
jeito nenhum até ele rodar**, porque pertencem a outra pessoa, e a biblioteca padrão é o lugar para
ver que código é esse:

```
ana@vm:~/reflect-hits$ go list -f "{{.ImportPath}} {{range .Imports}}{{if eq . \"reflect\"}}imports reflect{{end}}{{end}}" encoding/json fmt flag text/template strconv slices
encoding/json imports reflect
fmt imports reflect
flag imports reflect
text/template imports reflect
strconv 
slices 
```

O `encoding/json` serializa structs que nunca viu, o `fmt` as imprime, o `text/template` chama os
métodos delas pelos nomes escritos num template, e o `flag` usa reflexão para descobrir o valor zero
de uma flag, e foi assim que o `-h` da lição 1 soube imprimir `(default 3)` para `-n` e nada para
`-json`. O `strconv` e o `slices` trabalham com tipos que conhecem ou recebem como parâmetros de tipo,
e não precisam de nada disso. Nos testes, o `reflect.DeepEqual` compara dois valores de qualquer tipo
campo a campo, campos não exportados incluídos, que é exatamente o que um auxiliar de teste quer e o
que o código comum não consegue escrever para um tipo que não conhece.

| situação | use |
|---|---|
| uma biblioteca que precisa lidar com tipos que quem a chama vai escrever depois: um codificador, um impressor, um auxiliar de teste | `reflect`, atrás de uma API pequena que devolve erros em vez de entrar em pânico |
| um algoritmo sobre muitos tipos, todos conhecidos onde é chamado | generics, lições 30 e 31 do curso `go` |
| alguns tipos conhecidos, e o código por tipo é chato e repetitivo | geração de código, lição 10: um gerador rodado pelo `go generate` pode escrever as listas `PathColumns`, e o compilador confere o que ele escreveu |
| um tipo, um lugar | código simples |

**Para o `hits`, a `Table` é a melhor escolha**: um tipo de linha, duas colunas, todo acesso a campo
conferido, e um pouco mais rápida. O `columns.Reflect` mereceria o lugar num pacote que imprimisse as
linhas das structs de outras pessoas, que é a situação do `encoding/json` e não a do `hits`. A lição
22 abre a próxima porta de escape, o `unsafe`.
