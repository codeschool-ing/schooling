---
title: O que o gofmt muda
version: 1
---

O `gofmt` costuma ser tomado por um verificador de estilo, uma ferramenta que lê o seu código e
reclama. **Ele é uma impressora.** Ele lê o arquivo para a árvore sintática do Go e imprime a árvore
de volta, e o layout do que sai é decidido pela impressora, não por quem digitou o arquivo. Duas
pessoas que escrevem o mesmo programa com hábitos diferentes recebem os mesmos bytes de volta. Ele
veio com a sua instalação do Go, em `/usr/local/go/bin` ao lado do `go`, e a lição 1 seção 02 já o
encontrou lá.

Para ver o que ele faz, é preciso algo em que trabalhar. Esta lição trabalha em `~/fmt`, uma cópia
do `hits` com o pacote `tally`, o `main.go`, o `main_test.go` e o `genlog` colocados exatamente como
a lição 1 os imprimiu, num módulo criado com `go mod init example.com/hits`. A isso, acrescente uma
função pequena que agrupa os códigos de status por família, escrita do jeito que alguém com pressa
escreve: dois espaços aqui, quatro ali e nenhum em outros lugares. `internal/tally/classes.go`:

```go
package tally
import "fmt"
// Class is one family of status codes: 2xx, 3xx, 4xx or 5xx.
type Class struct {
    Name string // "2xx"
    Requests int // lines whose status is in the family
    Share float64 // Requests as a fraction of all lines
}



// Classes folds s.ByStatus into one row per family, 2xx first.
func Classes(s Summary) []Class{
  rows:=[]Class{}
  for _,c := range []int{2,3,4,5} {
      n:=0
      for status,count:=range s.ByStatus{
        if status/100==c {n+=count}
      }
      rows=append(rows,Class{Name:fmt.Sprintf("%dxx",c),Requests:n,Share:float64(n)/float64(s.Lines)})
  }
  return rows
}
```

Ele compila do jeito que está. O compilador se importa com os tokens, não com os espaços entre
eles. Com um nome de arquivo e nenhuma flag, o `gofmt` imprime a versão formatada na saída padrão e
não toca no arquivo:

```
ana@vm:~/fmt$ gofmt internal/tally/classes.go
package tally

import "fmt"

// Class is one family of status codes: 2xx, 3xx, 4xx or 5xx.
type Class struct {
	Name     string  // "2xx"
	Requests int     // lines whose status is in the family
	Share    float64 // Requests as a fraction of all lines
}

// Classes folds s.ByStatus into one row per family, 2xx first.
func Classes(s Summary) []Class {
	rows := []Class{}
	for _, c := range []int{2, 3, 4, 5} {
		n := 0
		for status, count := range s.ByStatus {
			if status/100 == c {
				n += count
			}
		}
		rows = append(rows, Class{Name: fmt.Sprintf("%dxx", c), Requests: n, Share: float64(n) / float64(s.Lines)})
	}
	return rows
}
```

## O que mudou

Toda diferença entre as duas versões cai num destes tipos:

| o quê | antes | depois |
|---|---|---|
| recuo | dois ou quatro espaços, como foi digitado | **um tab por nível** |
| os campos de uma struct | `Name string`, `Requests int` | nomes, tipos e comentários cada um numa coluna, completados com espaços |
| espaço em volta dos tokens | `rows:=[]Class{}`, `_,c` | `rows := []Class{}`, `_, c` |
| blocos | `{n+=count}` na linha do `if` | o corpo numa linha própria |
| linhas em branco | nenhuma depois de `package`, três depois da struct | uma entre declarações, nunca mais de uma seguida |

**Tabs recuam e espaços alinham.** É a regra que o `go doc cmd/gofmt` dá nas primeiras linhas, e a
struct mostra as duas coisas: cada linha de campo começa com um tab, e os espaços depois de `Name` e
depois de `string` estão lá para alinhar as colunas. A largura de um tab é a que o seu editor
mandar, então o recuo segue a preferência de quem lê, enquanto o alinhamento é contado em espaços e
sobrevive a qualquer largura de tab.

**O espaço em volta de um operador depende da expressão em que ele está.** `status/100 == c` tem
espaços em volta de `==` e nenhum em volta de `/`: o operador que liga mais forte fica colado, e o
espaçamento mostra como a expressão se agrupa. Em `float64(n) / float64(s.Lines)` a `/` é o único
operador do elemento, e ganha espaços. Ninguém escreveu essa regra no `classes.go`; ela vem da
árvore sintática, e é por isso que o `gofmt` consegue aplicá-la a um código que nunca viu.

## Três flags que decidem para onde vai o resultado

Imprimir na saída padrão é o modo que você menos usa. Os outros três respondem às perguntas que as
pessoas de fato fazem: quais arquivos estão errados, como, e conserte:

```
ana@vm:~/fmt$ gofmt -l .
internal/tally/classes.go
ana@vm:~/fmt$ gofmt -d internal/tally/classes.go | head -20
diff internal/tally/classes.go.orig internal/tally/classes.go
--- internal/tally/classes.go.orig
+++ internal/tally/classes.go
@@ -1,23 +1,25 @@
 package tally
+
 import "fmt"
+
 // Class is one family of status codes: 2xx, 3xx, 4xx or 5xx.
 type Class struct {
-    Name string // "2xx"
-    Requests int // lines whose status is in the family
-    Share float64 // Requests as a fraction of all lines
-}
-
-
+	Name     string  // "2xx"
+	Requests int     // lines whose status is in the family
+	Share    float64 // Requests as a fraction of all lines
+}
```

**O `-l` lista os arquivos cuja formatação difere**, um por linha, e não imprime nada sobre o resto.
Com um diretório, o `gofmt` percorre esse diretório e todos os que estão dentro dele, lendo cada
arquivo `.go`, então `.` quer dizer o módulo inteiro: quatro arquivos da lição 1 foram lidos e
estavam certos, e só o `classes.go` foi citado. **O `-d` imprime um diff unificado** em vez do
arquivo inteiro, que é o que você quer numa revisão ou num log de CI. A terceira flag, **`-w`, grava
o resultado de volta no arquivo**, e não imprime nada.

## `go fmt` é `gofmt -l -w` sobre pacotes

O `go help fmt` diz isso numa linha: o `go fmt` "roda o comando 'gofmt -l -w' nos pacotes citados
pelos caminhos de importação". A flag `-n` imprime o comando em vez de rodá-lo, como faz no
`go build` e em vários outros subcomandos, e assim dá para ver exatamente o que isso significa:

```
ana@vm:~/fmt$ go fmt -n ./...
/usr/local/go/bin/gofmt -l -w main.go main_test.go internal/tally/classes.go internal/tally/tally.go tools/genlog/main.go
ana@vm:~/fmt$ go fmt ./...
internal/tally/classes.go
ana@vm:~/fmt$ go fmt ./...
ana@vm:~/fmt$ gofmt -l .
```

O comando go achou os três pacotes do módulo, juntou os cinco arquivos deles e os entregou ao
`gofmt` que veio com o toolchain. **A primeira execução reescreveu o `classes.go` e o citou; a
segunda não achou nada para fazer e não imprimiu nada.** Depois disso, o `gofmt -l .` não tem o que
listar.

A diferença entre os dois comandos é o que cada um recebe. **O `go fmt` recebe pacotes**, `./...` ou
um caminho de importação, e formata os arquivos de que esses pacotes são feitos. **O `gofmt` recebe
arquivos e diretórios**, e lê todo arquivo `.go` que encontra dentro deles, quer um pacote o inclua,
quer não. A seção 05 mostra onde essa diferença pesa. No dia a dia, um `go fmt ./...` antes do commit
é o hábito inteiro, e um editor que formata ao salvar dispensa até isso.
