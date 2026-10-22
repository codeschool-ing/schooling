---
title: Importado, ou chamado
version: 1
---

A afirmação da seção 02 fica mais fácil de acreditar quando dois programas que diferem numa chamada
recebem duas respostas diferentes. **Os dois programas aqui importam o mesmo pacote do mesmo módulo
na mesma versão antiga, e só um deles chama a função que a entrada cita.** Eles moram num módulo só,
`example.com/langs`, em `~/langs`, e dependem de `golang.org/x/text` na v0.3.7, uma versão de agosto
de 2021 que foi a mais recente por mais de um ano.

O primeiro, `accept`, lê o valor de um cabeçalho `Accept-Language`, a linha que um navegador manda para
dizer que idiomas o usuário lê e quanto prefere cada um. Ele imprime um idioma por linha com o peso, do
mais desejado para o menos. Um servidor web faz exatamente isso para escolher qual tradução de uma
página enviar, e é por isso que o bug da GO-2022-1059 importava: o cabeçalho vem de quem estiver do
outro lado. Salve como `accept/main.go`:

```go
// Command accept prints the languages an Accept-Language header asks for,
// most wanted first.
package main

import (
	"fmt"
	"os"

	"golang.org/x/text/language"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: accept 'header value'")
		os.Exit(2)
	}
	langs, err := preferred(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, "accept:", err)
		os.Exit(1)
	}
	for _, l := range langs {
		fmt.Println(l)
	}
}

// preferred reads a header and returns one line per language: the tag and
// its weight.
func preferred(header string) ([]string, error) {
	tags, weights, err := language.ParseAcceptLanguage(header)
	if err != nil {
		return nil, err
	}
	out := make([]string, len(tags))
	for i, t := range tags {
		out[i] = fmt.Sprintf("%s\t%.1f", t, weights[i])
	}
	return out, nil
}
```

O segundo, `tag`, confere uma tag de idioma, como `EN-us`, e a imprime na forma canônica ao lado do
idioma base. Ele usa `language.Parse`, do mesmo pacote, uma função que a entrada não cita. Salve como
`tag/main.go`:

```go
// Command tag checks one language tag and prints its canonical form.
package main

import (
	"fmt"
	"os"

	"golang.org/x/text/language"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: tag LANGUAGE-TAG")
		os.Exit(2)
	}
	t, err := language.Parse(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, "tag:", err)
		os.Exit(1)
	}
	base, _ := t.Base()
	fmt.Println(t, base)
}
```

Crie o módulo, peça a versão antiga de propósito e deixe o `go mod tidy` acertar o `go.mod`. Depois
rode os dois, para ver que funcionam:

```
ana@vm:~/langs$ go mod init example.com/langs
go: creating new go.mod: module example.com/langs
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/langs$ go get golang.org/x/text@v0.3.7
go: added golang.org/x/text v0.3.7
ana@vm:~/langs$ go mod tidy && cat go.mod
module example.com/langs

go 1.27.1

require golang.org/x/text v0.3.7
ana@vm:~/langs$ go run ./accept "pt-BR,pt;q=0.9,en;q=0.5"
pt-BR	1.0
pt	0.9
en	0.5
ana@vm:~/langs$ go run ./tag EN-us
en-US en
```

**O `go.mod` mostra um requisito, e nada nele diz quais funções o código usa.** Um scanner que só lê
esse arquivo tem de dar a mesma resposta para os dois programas.

## O programa que chama

O `govulncheck` aceita padrões de pacote do mesmo jeito que `go build` e `go test`. Um padrão por vez,
começando pelo `accept`:

```
ana@vm:~/langs$ time govulncheck -db file:///home/ana/vulndb ./accept; echo $?
=== Symbol Results ===

Vulnerability #1: GO-2022-1059
    Denial of service via crafted Accept-Language header in
    golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2022-1059
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.7
    Fixed in: golang.org/x/text@v0.3.8
    Example traces found:
      #1: accept/main.go:30:52: accept.preferred calls language.ParseAcceptLanguage

Your code is affected by 1 vulnerability from 1 module.
This scan also found 1 vulnerability in packages you import and 14
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.

real	0m2.448s
user	0m2.723s
sys	0m1.875s
3
```

Tudo de que quem defende precisa está no bloco sob `Vulnerability #1`. **`Found in` é a versão que
você tem, `Fixed in` é a primeira versão sem o bug**, e o trace aponta a linha do seu próprio código
em que o caminho sai dele: linha 30, coluna 52 de `accept/main.go`, que é a chamada a
`language.ParseAcceptLanguage` dentro de `preferred`. O resumo embaixo conta os outros dois níveis,
que uma execução padrão não lista. O status de saída é **3**, e é isso que torna o `govulncheck` útil
como barreira: qualquer shell, `make` ou passo de CI trata tudo que não seja 0 como falha. A
varredura levou pouco mais de dois segundos.

O trace padrão tem um passo só. `-show traces` imprime o caminho inteiro, do ponto de entrada até
dentro do módulo:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -show traces ./accept
=== Symbol Results ===

Vulnerability #1: GO-2022-1059
    Denial of service via crafted Accept-Language header in
    golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2022-1059
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.7
    Fixed in: golang.org/x/text@v0.3.8
    Example traces found:
      #1: for function golang.org/x/text/language.ParseAcceptLanguage
        main @ example.com/langs/accept/main.go:17:25
        preferred @ example.com/langs/accept/main.go:30:52
        ParseAcceptLanguage @ golang.org/x/text/language/parse.go:158:6
```

Leia de cima para baixo: `main` chama `preferred` na linha 17, `preferred` chama a função ruim na
linha 30, e a própria função começa na linha 158 de `parse.go`, no módulo. **Num programa real o
caminho pode ter muitas chamadas e passar por outros módulos.** O trace completo é como você descobre
qual dos seus pacotes mudar, ou se a chamada fica num canto do programa a que entrada não confiável
nunca chega. O relatório diz "example traces" porque mostra um caminho por vulnerabilidade, não
todos.

## O programa que não chama

A mesma varredura no `tag`:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb ./tag; echo $?
=== Symbol Results ===

No vulnerabilities found.

Your code is affected by 0 vulnerabilities.
This scan also found 2 vulnerabilities in packages you import and 14
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
```

**Mesmo módulo, mesma versão, mesmo pacote, e o status de saída é 0.** O achado não sumiu; ele desceu
de nível. `-show verbose` lista o que o resumo só conta. A saída é longa, então aqui vão as primeiras
42 linhas e depois uma contagem das entradas:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -show verbose ./tag | head -n 42
Fetching vulnerabilities from the database...

Checking the code against the vulnerabilities...

The package pattern matched the following root package:
  example.com/langs/tag
Govulncheck scanned the following 2 modules and the go1.27.1 standard library:
  example.com/langs
  golang.org/x/text@v0.3.7

=== Symbol Results ===

No vulnerabilities found.

=== Package Results ===

Vulnerability #1: GO-2026-6604
    Root.Mkdir(All) can follow junctions out of the root on Windows in os
  More info: https://pkg.go.dev/vuln/GO-2026-6604
  Standard library
    Found in: os@go1.27.1
    Fixed in: os@go1.27.2
    Platforms: windows

Vulnerability #2: GO-2022-1059
    Denial of service via crafted Accept-Language header in
    golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2022-1059
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.7
    Fixed in: golang.org/x/text@v0.3.8

=== Module Results ===

Vulnerability #1: GO-2026-6629
    Panic parsing crafted input in x/text/secure/precis in golang.org/x/text
  More info: https://pkg.go.dev/vuln/GO-2026-6629
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.7
    Fixed in: golang.org/x/text@v0.41.0

Vulnerability #2: GO-2026-6617
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -show verbose ./tag | grep -c '^Vulnerability #'
16
```

Dezesseis entradas em três grupos, e cada grupo responde a uma pergunta diferente:

| grupo | aqui | o que significa para o `tag` |
|---|---|---|
| Symbol Results | nenhuma | nenhum caminho a partir do `main` chega a uma função citada por alguma entrada |
| Package Results | 2 | o `tag` importa `language` e `os`, os pacotes que essas entradas citam, e não chama nenhuma das funções citadas |
| Module Results | 14 | o `tag` exige o módulo, ou usa aquela versão do Go, e nunca importa o pacote |

A GO-2022-1059 fica em Package Results porque `language` é importado e `Parse` não é um dos dois
nomes. **A entrada do `os` mostra como uma varredura de código trata plataformas**: é um bug do
Windows, marcado `Platforms: windows`, e uma varredura de código a lista em qualquer máquina, porque
código pode ser compilado para qualquer sistema. Das 14 entradas de módulo, 12 são da biblioteca
padrão do Go 1.27.1, `net/http`, `crypto/tls`, `html/template` e outros que o `tag` nunca importa, e
duas são de outros pacotes de `golang.org/x/text`; a seção 05 trata dos dois tipos.

O que fazer com um achado de nível de pacote é uma questão de julgamento, e o relatório dá o que você
precisa para julgar. O `tag` não está afetado hoje. **Ele está a uma edição de ficar afetado**: quem
chamar `ParseAcceptLanguage` neste módulo vai ver a próxima varredura falhar, e a correção mais
barata, subir uma versão, é a mesma agora e depois. A seção 05 faz isso.
