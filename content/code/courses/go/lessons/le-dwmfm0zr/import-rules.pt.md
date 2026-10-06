---
title: O que um import pode e não pode fazer
version: 1
---

Uma linha de import parece um pedido que sempre dá certo se o caminho existe. Duas regras podem
recusá-lo mesmo assim, e as duas tratam da forma do grafo que a seção 02 desenhou. Depois há quatro
jeitos de escrever a linha em si, e o último deles vale conhecer mais para reconhecer.

## Nada de ciclos

Suponha que `fold` quisesse saber se uma palavra está numa lista de palavras comuns, e a lista que
ele foi buscar fosse um `text.Counts`. Numa cópia do módulo, `fold.go` importa `text`:

```go
// Package fold puts a word into the form package text compares.
package fold

import (
	"strings"
	"unicode"

	"example.com/wordy/text"
)

// Common reports whether w is one of the words in common.
func Common(w string, common text.Counts) bool {
	return common[Word(w)] > 0
}

// Word lower-cases w and trims anything but letters and digits from its ends.
func Word(w string) string {
	return strings.TrimFunc(strings.ToLower(w), func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsDigit(r)
	})
}
```

```
ana@vm:~/pkgs-cycle$ go build ./...; echo $?
package example.com/wordy/cmd/wordcount
	imports example.com/wordy/text from main.go
	imports example.com/wordy/internal/fold from count.go
	imports example.com/wordy/text from fold.go: import cycle not allowed
1
```

A mensagem percorre a cadeia de um programa até a seta que aponta de volta para cima, nomeando o
arquivo que escreveu cada import. **Go recusa um ciclo de imports sem exceção**, entre dois pacotes
ou passando por vinte. Um pacote é compilado depois de tudo o que ele importa, e num ciclo não há um
primeiro para compilar; a mesma ordem decide de qual pacote a inicialização roda primeiro, mais
abaixo nesta página.

A saída nunca é um truque na linha de import. É mudar algo de lugar. Aqui `Common` só precisa de um
`map[string]int`, então pode receber um e largar o import; ou a função pertence a `text`, ao lado do
tipo que ela lê. Um ciclo é o compilador dizendo que dois pacotes na verdade são um só, ou que um
pedaço de um pertence ao outro.

## internal: um diretório que ninguém mais pode importar

`fold` fica num diretório chamado `internal`, e o comando go trata esse nome de um jeito especial. A
regra é um comentário em `cmd/go/internal/load/pkg.go`: "An import of a path containing the element
“internal” is disallowed if the importing code is outside the tree rooted at the parent of the
“internal” directory." Ou seja, importar um caminho que contém o elemento `internal` é proibido se o
código que importa está fora da árvore que começa no pai do diretório `internal`. O pai de
`internal` aqui é a raiz de `example.com/wordy`, então todo pacote do módulo pode importar `fold`, e
nenhum outro módulo pode.

Conferir isso exige um segundo módulo que enxergue este. O workspace da lição 3 faz exatamente isso:
em `~/pkgs-work`, uma cópia do módulo fica em `wordy`, e ao lado dela um módulo `example.com/other`
cujo programa importa um pacote de cada lado da linha:

```go
package main

import (
	"fmt"

	"example.com/wordy/internal/fold"
	"example.com/wordy/text"
)

func main() {
	fmt.Println(len(text.Count("one two two")), fold.Word("Hello!"))
}
```

```
ana@vm:~/pkgs-work$ go work init ./wordy ./other
ana@vm:~/pkgs-work$ go run ./other; echo $?
package example.com/other
	other/main.go:6:2: use of internal package example.com/wordy/internal/fold not allowed
1
```

`text` passou e `fold` não. **`internal` é como um módulo guarda um pacote para si.** Funciona numa
escala diferente da de um nome com letra minúscula: um nome com letra minúscula fica escondido de
todo outro pacote, enquanto um pacote em `internal/` mantém os nomes exportados dele usáveis em
todos os seus pacotes e os esconde dos pacotes dos outros. Esses nomes são uma API só do seu módulo,
livres para mudar em qualquer release, porque ninguém de fora pode tê-los usado.

## Quatro jeitos de escrever um import

O import comum associa o nome do pacote. Quando dois pacotes têm o mesmo nome, o segundo precisa
receber outro, um **alias**. `crypto/rand` e `math/rand/v2` são ambos `package rand`:

```go
package main

import (
	"crypto/rand"
	"fmt"
	"math/rand/v2"
)

func main() {
	fmt.Println(rand.N(10), len(rand.Text()))
}
```

```
ana@vm:~/pkgs-rand$ go build
# example.com/dice
./main.go:6:2: rand redeclared in this block
	./main.go:4:2: other declaration of rand
./main.go:6:2: "math/rand/v2" imported as rand and not used
./main.go:10:19: undefined: rand.N
```

Um alias escrito antes do caminho resolve, e o arquivo passa a usar o alias:

```go
package main

import (
	crand "crypto/rand"
	"fmt"
	"math/rand/v2"
)

func main() {
	fmt.Println(rand.N(1), len(crand.Text()))
}
```

```
ana@vm:~/pkgs-alias$ go run .
0 26
```

`rand.N(1)` pede um número abaixo de 1, então esta execução imprime a mesma coisa toda vez;
`crand.Text()` devolve uma string aleatória feita para segredos e tokens, e o comprimento dela é
tudo o que o programa mostra. Guarde os aliases para colisões como esta. Um alias escolhido para
encurtar faz todo leitor aprender um segundo nome para um pacote que ele já conhece.

### O import em branco, e init

Um import cujo nome é `_` não associa nome nenhum. Ele existe pelos efeitos colaterais de um pacote:
importar um pacote roda as funções `init` dele, e alguns pacotes fazem o trabalho deles ali.
`image.DecodeConfig` lê o tamanho de uma imagem em qualquer formato que tenha sido registrado no
pacote `image`, e nada vem registrado de fábrica:

```go
package main

import (
	"fmt"
	"image"
	"os"
)

func main() {
	f, err := os.Open("/usr/local/go/src/image/png/testdata/gray-gradient.png")
	if err != nil {
		fmt.Println(err)
		return
	}
	cfg, format, err := image.DecodeConfig(f)
	f.Close()
	fmt.Printf("%q %dx%d %v\n", format, cfg.Width, cfg.Height, err)
}
```

```
ana@vm:~/pkgs-png$ go run .
"" 0x0 image: unknown format
ana@vm:~/pkgs-png$ sed -i "s|\"image\"$|&\n\t_ \"image/png\"|" main.go && sed -n 3,8p main.go
import (
	"fmt"
	"image"
	_ "image/png"
	"os"
)
ana@vm:~/pkgs-png$ go run .
"png" 1x16 <nil>
ana@vm:~/pkgs-png$ grep -n "func init" -A2 /usr/local/go/src/image/png/reader.go
1052:func init() {
1053-	image.RegisterFormat("png", pngHeader, Decode, DecodeConfig)
1054-}
```

O programa nunca nomeia `png`, e sem o `_` o compilador recusaria o import não usado, como a lição 4
mostrou. O último comando mostra para que o import servia: `image/png` registra o decodificador dele
numa função `init`. **`init` não recebe argumentos, não devolve nada, não pode ser chamada e roda
sozinha** depois que as variáveis do pacote estão prontas. A ordem é fixa, e um módulo pequeno a
mostra:

```go
// Package reg keeps a list that other packages add to.
package reg

import "fmt"

var Names []string

func init() {
	fmt.Println("reg: init")
}
```

```go
package main

import (
	"fmt"

	"example.com/order/reg"
)

var greeting = say("main: package variable")

func say(s string) string {
	fmt.Println(s)
	return s
}

func init() {
	reg.Names = append(reg.Names, "main")
	fmt.Println("main: init")
}

func main() {
	fmt.Println("main: main", reg.Names)
}
```

```
ana@vm:~/pkgs-init$ go run .
reg: init
main: package variable
main: init
main: main [main]
```

Um pacote importado é inicializado por completo antes do pacote que o importa: `reg` primeiro.
Depois as variáveis de pacote do próprio `main`, depois o `init` dele, e só então `main`. É por isso
que `main` pôde acrescentar a `reg.Names` no `init` e achar a lista pronta. É também por isso que o
ciclo do começo desta seção não tem solução: com `text` e `fold` importando um ao outro, nenhum dos
dois pode ir primeiro. Use `init` com parcimônia. O trabalho feito ali roda para todo programa que
importa o pacote, precisando dele ou não, e `init` não tem como devolver um erro.

### O import com ponto

A última forma, `.`, põe os nomes exportados do pacote dentro do arquivo como se tivessem sido
declarados ali:

```go
package main

import (
	"fmt"
	. "strings"
)

func Title(s string) string {
	return ToUpper(s[:1]) + s[1:]
}

func main() {
	fmt.Println(Title("go"), Repeat("!", 3))
}
```

```
ana@vm:~/pkgs-dot$ go run .
# example.com/dot
./main.go:8:6: Title already declared through dot-import of package strings ("strings")
	$GOROOT/src/strings/strings.go:849:6: other declaration of Title
```

`ToUpper` e `Repeat` funcionaram sem `strings.` na frente, e o custo chegou na hora: `strings` já
tem um `Title`, na linha 849 do código dele, e agora todo nome exportado de `strings` é um nome que
este arquivo não pode declarar. Pior é o custo para quem lê, que vê `Repeat("!", 3)` e não sabe dizer
se ele é declarado neste pacote nem qual import o trouxe. **Escreva o nome do pacote.** É ele que faz
`text.Count` e `fold.Word` dizerem de onde vêm, e é por isso que os nomes em Go são curtos:
`strings.Repeat` não precisa se chamar `RepeatString`.
