---
title: Adicionar, atualizar e perguntar por quê
version: 1
---

`go get` soa como "baixe e instale este pacote", e era isso que ele fazia no Go de antes dos
módulos. **Hoje ele não compila nem instala nada.** O `go help get` diz isso numa linha: ele resolve
os argumentos em módulos em versões específicas, "atualiza o go.mod para exigir essas versões e
baixa o código-fonte para o cache de módulos". Instalar um programa é `go install`, da lição 4.

A lição 38 já mostrou que o `go mod tidy` busca o que os seus imports precisam. O que o `tidy` não
deixa você fazer é escolher: ele pega a versão mais recente de tudo que falta e não mexe no que já
está lá. **`go get` é o comando para decidir de que versão você depende**, e para mudar de ideia
depois.

## Uma dependência, na versão que você escolheu

O programa desta seção mede strings do jeito que um terminal as desenha. Um terminal dá uma coluna
para a maioria dos caracteres e duas para alguns, e a biblioteca padrão não tem função que saiba
quais: `len` conta bytes e `utf8.RuneCountInString` conta runas, como as lições 8 e 9 mostraram. O
módulo `github.com/mattn/go-runewidth` sabe.

```go
// Command width measures strings the way a terminal draws them.
package main

import (
	"fmt"
	"unicode/utf8"

	"github.com/mattn/go-runewidth"
)

func main() {
	words := []string{
		"Ana",
		"cafe\u0301",           // e and a combining accent
		"\u65e5\u672c",         // Japan, in Japanese
		"\U0001F1E7\U0001F1F7", // the flag of Brazil
		"\U0001FAE9",           // a recent emoji
	}
	for _, w := range words {
		fmt.Printf("%-+24q bytes %d  runes %d  columns %d\n",
			w, len(w), utf8.RuneCountInString(w), runewidth.StringWidth(w))
	}
}
```

As strings estão escritas com escapes, e `%+q` as imprime escapadas, então toda linha abaixo é ASCII
puro, faça o seu terminal o que fizer com emoji. A versão foi escolhida de propósito: v0.0.16, uma
antiga, para haver o que atualizar.

```
ana@vm:~/thirdparty-width$ go get github.com/mattn/go-runewidth@v0.0.16
go: added github.com/mattn/go-runewidth v0.0.16
go: added github.com/rivo/uniseg v0.2.0
ana@vm:~/thirdparty-width$ go mod tidy && cat go.mod
module example.com/width

go 1.27.1

require github.com/mattn/go-runewidth v0.0.16

require github.com/rivo/uniseg v0.2.0 // indirect
ana@vm:~/thirdparty-width$ go run .
"Ana"                    bytes 3  runes 3  columns 3
"cafe\u0301"             bytes 6  runes 5  columns 4
"\u65e5\u672c"           bytes 6  runes 2  columns 4
"\U0001f1e7\U0001f1f7"   bytes 8  runes 2  columns 1
"\U0001fae9"             bytes 4  runes 1  columns 1
```

**Um `go get` adicionou dois módulos.** O `go-runewidth` v0.0.16 exige `github.com/rivo/uniseg` no
seu próprio `go.mod`, então esse módulo veio junto, e o `tidy` o colocou sob `// indirect`: algo de
que o seu módulo precisa só porque uma dependência precisa. O `go get` vem seguido de `go mod tidy`
aqui para que o `go.mod` diga exatamente o que os imports pedem, que é o trabalho do `tidy` desde a
lição 38.

A saída é a razão de ser do módulo. O `cafe` acentuado tem seis bytes, cinco runas e quatro colunas;
os dois caracteres japoneses são duas runas e quatro colunas. As duas últimas linhas dizem uma
coluna cada, e é aí que esta versão antiga está desatualizada.

## O que está desatualizado, e atualizar

`go list -m -u all` lista todo módulo do build e, entre colchetes, a versão mais nova que cada um
publicou:

```
ana@vm:~/thirdparty-width$ go list -m -u all
example.com/width
github.com/mattn/go-runewidth v0.0.16 [v0.0.30]
github.com/rivo/uniseg v0.2.0 [v0.4.7]
```

Um módulo sem colchetes está em dia, e a primeira linha, sem versão nenhuma, é o seu próprio módulo.
Pedir `@latest` leva a dependência à versão mais recente:

```
ana@vm:~/thirdparty-width$ go get github.com/mattn/go-runewidth@latest
go: added github.com/clipperhouse/uax29/v2 v2.2.0
go: upgraded github.com/mattn/go-runewidth v0.0.16 => v0.0.30
ana@vm:~/thirdparty-width$ go run .
"Ana"                    bytes 3  runes 3  columns 3
"cafe\u0301"             bytes 6  runes 5  columns 4
"\u65e5\u672c"           bytes 6  runes 2  columns 4
"\U0001f1e7\U0001f1f7"   bytes 8  runes 2  columns 2
"\U0001fae9"             bytes 4  runes 1  columns 2
```

A bandeira e o emoji agora têm duas colunas cada. **Nenhuma linha do `main.go` mudou, e o programa
imprime outra coisa.** Isso é uma atualização: o código de outra pessoa, trocado por baixo do seu.
Aqui é uma melhora, porque a versão nova conhece dados mais novos do Unicode. O hábito a levar daqui
é executar o programa, e os testes dele quando você os tiver, depois de toda atualização, em vez de
confiar num número de versão.

A atualização também trocou uma dependência: a v0.0.30 não usa mais o `uniseg` e exige
`github.com/clipperhouse/uax29/v2` no lugar. O `go get` adicionou o novo e não removeu o antigo,
então o `tidy` termina o serviço:

```
ana@vm:~/thirdparty-width$ go mod tidy && cat go.mod
module example.com/width

go 1.27.1

require github.com/mattn/go-runewidth v0.0.30

require github.com/clipperhouse/uax29/v2 v2.2.0 // indirect
```

## Perguntar por que um módulo está ali

Um `go.mod` comprido levanta a pergunta de para que serve cada linha. `go mod why -m` responde com a
cadeia de imports que leva do seu código ao módulo:

```
ana@vm:~/thirdparty-width$ go mod why -m github.com/clipperhouse/uax29/v2
# github.com/clipperhouse/uax29/v2
example.com/width
github.com/mattn/go-runewidth
github.com/clipperhouse/uax29/v2/graphemes
ana@vm:~/thirdparty-width$ go mod why -m github.com/rivo/uniseg
# github.com/rivo/uniseg
(main module does not need module github.com/rivo/uniseg)
```

Leia a primeira resposta de cima para baixo: o seu pacote importa o `go-runewidth`, que importa o
pacote `graphemes` do `uax29/v2`. A segunda diz que nada mais precisa do `uniseg`, e é por isso que
o `tidy` o tirou. **`go mod why` é como você descobre de quem foi a decisão de trazer uma
dependência**, e portanto a quem perguntar antes de tentar se livrar dela.

Mais uma linha merece atenção depois da atualização:

```
ana@vm:~/thirdparty-width$ go list -m -u all
example.com/width
github.com/clipperhouse/uax29/v2 v2.2.0 [v2.7.0]
github.com/mattn/go-runewidth v0.0.30
```

O `go-runewidth` pede o `uax29/v2` v2.2.0, então é essa que o build usa, mesmo existindo a v2.7.0: a
seleção de versão mínima da lição 38 fica com a versão que alguém pediu, não com a mais nova. O
`go help get` descreve a flag que muda isso: `go get -u` com um pacote também atualiza os módulos de
que esse pacote depende para as suas versões minor ou patch mais novas.

## Voltar atrás, e ir embora

O mesmo comando anda no outro sentido. Dar uma versão mais antiga faz o downgrade, e a versão
especial `none` remove a exigência:

```
ana@vm:~/thirdparty-width$ go get github.com/mattn/go-runewidth@v0.0.16
go: downgraded github.com/mattn/go-runewidth v0.0.30 => v0.0.16
go: added github.com/rivo/uniseg v0.2.0
ana@vm:~/thirdparty-width$ go get github.com/mattn/go-runewidth@none
go: removed github.com/mattn/go-runewidth v0.0.16
```

Remover a exigência não remove o import do `main.go`, então o programa deixaria de compilar; `@none`
é para depois que você apagou o código que usava o módulo. Toda forma depois do `@` é uma **consulta
de versão**, e o código-fonte do comando go lista as que ele aceita:

| depois do `@` | qual versão |
|---|---|
| `v0.0.16` | exatamente essa versão com tag |
| `latest` | a release com tag mais nova, fora as retiradas (seção 05) |
| `v1`, `v1.2` | a `v1.x.x` mais nova, a `v1.2.x` mais nova |
| `patch` | a mais nova com os mesmos números major e minor da que você tem |
| `upgrade` | como `latest`, mas nunca mais antiga do que a que você tem |
| `<v1.3.0`, `>=v1.2.0` | a versão mais próxima que satisfaz a comparação |
| um hash de commit | esse commit, sob uma pseudo-versão feita da data e do hash, como `v0.0.0-20261005191246-02052bb39a2e` |
| `none` | nenhuma versão: remove a exigência |
