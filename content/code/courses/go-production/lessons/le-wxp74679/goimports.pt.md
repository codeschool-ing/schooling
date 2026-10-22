---
title: O bloco de imports, escrito pelo goimports
version: 1
---

O `gofmt` ordena as linhas de um bloco de imports, e é tudo o que faz com ele. Ele não sabe que você
usou `os` sem importar, nem que importou `strings` e nunca usou. **O compilador recusa as duas coisas,
e a segunda recusa surpreende quem vem de outras linguagens**, onde um import sem uso é no máximo um
aviso. O `goimports` é o `gofmt` mais esse conhecimento. Ele formata o arquivo como o `gofmt` faz e
depois reescreve o bloco de imports para que tenha exatamente o que o arquivo usa, agrupado do jeito
convencional do Go.

Ele não faz parte do toolchain. Mora no módulo `golang.org/x/tools`, e o `go install` o compila em
`~/go/bin`, que a lição 1 seção 02 pôs no seu `PATH`. Este curso fixa a versão, como faz com toda
ferramenta que instala:

```sh
go install golang.org/x/tools/cmd/goimports@v0.52.0
```

O comando go imprime uma linha para cada módulo que baixa, e quantas depende do que o seu cache de
módulos já tem. O binário registra a partir de que foi compilado, e essa é a conferência confiável:

```
ana@vm:~/fmt$ go version -m $(command -v goimports) | head -3
/home/ana/go/bin/goimports: go1.27.1
	path	golang.org/x/tools/cmd/goimports
	mod	golang.org/x/tools	v0.52.0	h1:ryxg4U63oaUYk7uOLTF37n43f4qgtGvqV4Ioit1BaEs=
```

## Um arquivo com os imports errados

Um segundo programa pequeno para o `hits`, em `tools/` ao lado do `genlog`: ele lê um log da entrada
padrão e imprime as famílias de `Classes` da seção 02, com separador de milhar para que uma contagem
de cinco dígitos se leia num relance. Ele está escrito do jeito que o código costuma ficar logo depois
de uma edição, usando cinco pacotes e importando um de que não precisa mais. `tools/classes/main.go`:

```go
// Command classes reads an access log on standard input and prints how many
// requests fell in each family of status codes.
package main

import (
	"strings"
)

func main() {
	s, err := tally.Count(os.Stdin)
	if err != nil {
		fmt.Fprintln(os.Stderr, "classes:", err)
		os.Exit(1)
	}
	p := message.NewPrinter(language.English)
	for _, c := range tally.Classes(s) {
		p.Printf("%s  %7d  %5.1f%%\n", c.Name, c.Requests, 100*c.Share)
	}
}
```

O compilador lista cada problema, um por uso:

```
ana@vm:~/fmt$ go build ./tools/classes
# example.com/hits/tools/classes
tools/classes/main.go:6:2: "strings" imported and not used
tools/classes/main.go:10:12: undefined: tally
tools/classes/main.go:10:24: undefined: os
tools/classes/main.go:12:3: undefined: fmt
tools/classes/main.go:12:16: undefined: os
tools/classes/main.go:13:3: undefined: os
tools/classes/main.go:15:7: undefined: message
tools/classes/main.go:15:26: undefined: language
tools/classes/main.go:16:20: undefined: tally
```

`message` e `language` vêm do `golang.org/x/text`, um módulo fora da biblioteca padrão, então o
módulo precisa exigi-lo antes que alguém consiga achar os pacotes dele. O `go get` acrescenta a
dependência:

```sh
go get golang.org/x/text@v0.43.0
```

```
ana@vm:~/fmt$ cat go.mod
module example.com/hits

go 1.27.1

require golang.org/x/text v0.43.0 // indirect
```

**`// indirect` quer dizer que nenhum arquivo do módulo o importa ainda**, o que vale por mais um comando.

## O que o goimports faz com ele

O `goimports` aceita os mesmos `-l`, `-d` e `-w` do `gofmt`, e eles significam o mesmo:

```
ana@vm:~/fmt$ goimports -l .
tools/classes/main.go
ana@vm:~/fmt$ goimports -w tools/classes/main.go && sed -n "/^import/,/^)/p" tools/classes/main.go
import (
	"fmt"
	"os"

	"example.com/hits/internal/tally"
	"golang.org/x/text/language"
	"golang.org/x/text/message"
)
```

**O `strings` sumiu, e os cinco pacotes que o arquivo usa entraram.** Para cada nome usado e não
importado, o `goimports` procura um pacote com esse nome que exporte o que o arquivo pede dele: `fmt`
e `os` na biblioteca padrão, `tally` dentro deste módulo, `message` e `language` entre os módulos que
o `go.mod` exige. É uma busca, e com dois candidatos de mesmo nome ela pode escolher o errado; leia o
bloco que ele escreveu na primeira vez que ele escreve um num arquivo.

**O bloco saiu em dois grupos, separados por uma linha em branco**: a biblioteca padrão primeiro,
depois todo o resto, cada grupo em ordem. O `goimports` escreve esse agrupamento a cada execução, então
um arquivo pelo qual ele passou sempre o tem.

## `-local`: os seus pacotes num grupo só deles

No segundo grupo, `example.com/hits/internal/tally` fica no meio de pacotes de outro módulo, e numa
lista maior os seus pacotes se perdem ali. O `-local` recebe um prefixo de caminhos de importação e
move os que casam para um terceiro grupo, depois de todo o resto:

```
ana@vm:~/fmt$ goimports -local example.com/hits -w tools/classes/main.go && sed -n "/^import/,/^)/p" tools/classes/main.go
import (
	"fmt"
	"os"

	"golang.org/x/text/language"
	"golang.org/x/text/message"

	"example.com/hits/internal/tally"
)
```

**Biblioteca padrão, depois os módulos dos outros, depois os seus.** O arquivo já tinha passado pelo
`goimports` uma vez e o bloco já estava em dois grupos; o `-local` dividiu o segundo. Passe a ele o
caminho do módulo que está no seu `go.mod`, e passe o mesmo em todo lugar. Um colega que roda o
`goimports` sem `-local` junta o terceiro grupo de volta no segundo, e vocês dois passam a reescrever
o bloco de imports um do outro, alternadamente. A seção 05 põe a flag num script só para ninguém
precisar lembrar.

O programa agora compila, e o `go mod tidy` tira o `// indirect`, porque agora um arquivo importa o
módulo:

```
ana@vm:~/fmt$ go build -o classes ./tools/classes && ./classes < access.log
2xx   10,058   50.3%
3xx    2,421   12.1%
4xx    4,998   25.0%
5xx    2,523   12.6%
ana@vm:~/fmt$ go mod tidy && cat go.mod
module example.com/hits

go 1.27.1

require golang.org/x/text v0.43.0
```

As quatro contagens somam as 20.000 linhas do `access.log`, e `2xx` são os 7.554 `200`, os 1.256
`201` e os 1.248 `204` da lição 1 juntos.

## No editor

**Você raramente vai rodar o `goimports` à mão.** O `gopls` é o servidor de linguagem por trás do
suporte a Go no VS Code, e a documentação dele descreve configurações para Vim, Neovim, Emacs, Helix,
Sublime Text e Zed. **Ele faz o mesmo trabalho que o `goimports`.** Oferece uma ação "Organize
imports" que apaga imports sem uso, acrescenta os que faltam e os ordena, e um ajuste `local` que a
documentação chama de "o equivalente da flag `goimports -local`". Muitos editores rodam a formatação e a
organização a cada gravação. Este laboratório não tem editor, então **nada disso foi rodado aqui**. O
que a lição mostra é a ferramenta de linha de comando, que é também o que um hook e um job de CI usam,
e o jeito de conferir que um editor fez o trabalho dele.

O `gopls` documenta uma queixa que vale conhecer antes de topar com ela: remover um import sem uso ao
salvar atrapalha quando você comentou por um minuto a única linha que o usava, para depurar, e o
import some. Descomente a linha, salve de novo, e ele volta.
