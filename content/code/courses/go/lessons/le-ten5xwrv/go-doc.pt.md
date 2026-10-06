---
title: A documentação já está na sua máquina
version: 1
---

O hábito que a maioria traz para uma linguagem nova é procurar o nome de uma função na web. Em Go
esse é o caminho lento. **Todo pacote se documenta em comentários, e o toolchain que você instalou
traz o código-fonte da biblioteca padrão inteira**, então a resposta está a um comando de
distância e funciona sem rede nenhuma:

```
ana@vm:~/hello$ go doc fmt.Println
package fmt // import "fmt"

func Println(a ...any) (n int, err error)
    Println formats using the default formats for its operands and writes to
    standard output. Spaces are always added between operands and a newline
    is appended. It returns the number of bytes written and any write error
    encountered.

```

Leia na ordem em que aparece, porque cada parte responde a uma pergunta diferente:

- **`package fmt // import "fmt"`** diz onde a função mora e o caminho que você importa para
  usá-la. Para `fmt` os dois são iguais; para `json` o caminho de importação é `encoding/json`.
- **A assinatura** é a frase mais precisa da resposta. `a ...any` quer dizer qualquer número de
  argumentos de qualquer tipo, o que a lição 21 explica, e `(n int, err error)` quer dizer que
  `Println` devolve dois valores: quantos bytes escreveu e se a escrita falhou. O programa da seção
  02 ignorou os dois, o que é normal para imprimir num terminal e errado para escrever num arquivo.
- **O comentário** é o que o autor escreveu acima da função, sem edição. Repare que ele diz o que
  `Println` faz com os espaços entre os operandos. É o tipo de detalhe que o resumo da web deixa de
  fora.

## Um pacote, e uma função que você não sabia que existia

Dado o nome de um pacote, o `go doc` imprime a documentação dele e um resumo de uma linha de tudo o
que ele exporta. Passando por `head`, o começo de `strings`:

```
ana@vm:~/hello$ go doc strings | head -12
package strings // import "strings"

Package strings implements simple functions to manipulate UTF-8 encoded strings.

For information about UTF-8 strings in Go, see https://blog.golang.org/strings.

func Clone(s string) string
func Compare(a, b string) int
func Contains(s, substr string) bool
func ContainsAny(s, chars string) bool
func ContainsFunc(s string, f func(rune) bool) bool
func ContainsRune(s string, r rune) bool
```

É assim que você encontra uma função em vez de consultar uma. Quem quer quebrar uma frase em
palavras e percorre o resto dessa lista encontra `Fields`:

```
ana@vm:~/hello$ go doc strings.Fields
package strings // import "strings"

func Fields(s string) []string
    Fields splits the string s around each instance of one or more consecutive
    white space characters, as defined by unicode.IsSpace, returning a slice
    of substrings of s or an empty slice if s contains only white space.
    Every element of the returned slice is non-empty. Unlike Split, leading and
    trailing runs of white space characters are discarded.

```

A última frase é o motivo para ler a documentação em vez de adivinhar. `Fields` e `Split` quebram
uma string em pedaços, e só uma delas descarta os pedaços vazios das pontas. Um programa que usasse
a errada compilaria, rodaria e só estaria errado com uma entrada que começasse com espaço.

**Letras minúsculas no argumento casam com qualquer caixa**, então `go doc json.decoder.decode`
encontra `json.Decoder.Decode`. E os argumentos valem para o seu próprio código também. Em
`~/hello`, sem argumento, o `go doc` imprime o comentário que fica acima de `package main`:

```
ana@vm:~/hello$ go doc
Command hello prints a greeting.
```

É por isso que a primeira linha de `hello.go` era uma frase começando pelo nome do programa. Um
comentário logo acima de uma declaração é a documentação dela, e as ferramentas o leem.

## O mesmo texto num navegador

A documentação de todo módulo público também é publicada em **pkg.go.dev**, gerada a partir dos
mesmos comentários, com o código-fonte a um clique. É o lugar para olhar antes de adicionar um
pacote de terceiros, na lição 40, porque mostra também a licença do módulo, as versões dele e quais
outros módulos o importam. O `go doc -http` serve as mesmas páginas a partir da sua máquina; ele
não foi executado no laboratório, porque o primeiro uso baixa e compila um servidor de
documentação, `golang.org/x/pkgsite`, antes de mostrar qualquer coisa.

O terminal continua sendo o hábito mais rápido para a biblioteca padrão, e tem uma vantagem que o
site não pode ter: mostra a documentação **do Go que você está usando**, e não da versão mais
recente.
