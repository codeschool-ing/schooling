---
title: "Quebrar uma promessa de propósito: retract e /v2"
version: 1
---

A seção 04 terminou com uma release ruim no mundo. O conserto tentador é corrigir o código e mover a
tag, e a seção 04 mostrou o que todo mundo que importa recebe então: um checksum que não confere e as
palavras `SECURITY ERROR`. Uma versão, uma vez publicada, fica. **O que um autor pode fazer é publicar
mais versões: uma correção, um aviso de que uma antiga não deve ser usada e, quando a própria API
precisa mudar, uma versão major nova.** Esta seção faz as três coisas.

## A correção, e uma retirada

A correção é uma string, `" and "` onde estava `""`, então é um patch: v1.1.1. A release também
leva uma linha no seu `go.mod`, que o `go mod edit` escreve, como a lição 38 disse que todo tipo de
linha tem um comando que a escreve:

```
ana@vm:~/thirdparty-greet$ go mod edit -retract=v1.1.0 && cat go.mod
module example.com/ana/greet

go 1.27

retract v1.1.0
```

O motivo vai num comentário no fim da linha. O `go mod edit` não tem flag para isso, então a autora o
digita, e depois põe a tag:

```
ana@vm:~/thirdparty-greet$ cat go.mod
module example.com/ana/greet

go 1.27

retract v1.1.0 // HelloAll runs the names together.
ana@vm:~/thirdparty-greet$ git tag v1.1.1
```

**Uma diretiva `retract` é uma declaração, publicada numa versão mais nova, sobre uma mais antiga.**
Ela não apaga nada: a v1.1.0 continua no proxy, e quem a tem no `go.sum` ainda consegue baixá-la. O
comando go lê a diretiva no `go.mod` da versão mais recente do módulo e, daí em diante, trata a
v1.1.0 de outro jeito. Quem importa e ainda está na v1.1.0 fica sabendo na hora:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -u all
example.com/app
example.com/ana/greet v1.1.0 (retracted) [v1.1.1]
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -versions example.com/ana/greet
example.com/ana/greet v0.1.0 v1.0.0 v1.1.1
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -retracted -versions example.com/ana/greet
example.com/ana/greet v0.1.0 v1.0.0 v1.1.0 v1.1.1
```

A versão retirada aparece marcada no `-u`, fica fora da lista simples de versões e fica fora do
`@latest`. Ela volta a ser listada quando você pede com `-retracted`.
Atualizar escolhe a correção, e o programa imprime o que deve:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go get example.com/ana/greet@latest
go: downloading example.com/ana/greet v1.1.1
go: upgraded example.com/ana/greet v1.1.0 => v1.1.1
ana@vm:~/thirdparty-app$ go run .
Hello, Ana
Hello, Ana and Bia
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go get example.com/ana/greet@v1.1.0
go: warning: example.com/ana/greet@v1.1.0: retracted by module author: HelloAll runs the names together.
go: to switch to the latest unretracted version, run:
	go get example.com/ana/greet@latest
go: downgraded example.com/ana/greet v1.1.1 => v1.1.0
```

Pedir a v1.1.0 pelo nome ainda funciona, e o aviso cita o comentário que a autora pôs na diretiva.
Esse comentário é a única explicação que quem importa vai ver, então ele deve dizer o que está
errado, não só que algo está. A seção 03 encontrou dois de verdade no `go.mod` do `uax29/v2`, e as
duas listagens os mostram:

```
ana@vm:~/thirdparty-width$ go list -m -versions github.com/clipperhouse/uax29/v2
github.com/clipperhouse/uax29/v2 v2.0.0 v2.0.1 v2.2.0 v2.3.0 v2.3.1 v2.4.0 v2.5.0 v2.6.0 v2.7.0
ana@vm:~/thirdparty-width$ go list -m -retracted -versions github.com/clipperhouse/uax29/v2
github.com/clipperhouse/uax29/v2 v2.0.0 v2.0.1 v2.1.0 v2.1.1 v2.2.0 v2.3.0 v2.3.1 v2.4.0 v2.5.0 v2.6.0 v2.7.0
```

## Uma mudança que quebra é um módulo novo

Agora a autora quer que `Hello` avise de um nome vazio em vez de cumprimentar ninguém. Isso muda a
assinatura, e todo código que escreveu `s := greet.Hello(name)` deixa de compilar. A tabela da seção
04 diz o que isso custa: a versão major.

```go
// Package greet says hello.
package greet

import (
	"errors"
	"strings"
)

// Hello returns a greeting for name, and an error if name is empty.
func Hello(name string) (string, error) {
	if name == "" {
		return "", errors.New("greet: empty name")
	}
	return "Hello, " + name, nil
}

// HelloAll greets several people at once.
func HelloAll(names ...string) string {
	return "Hello, " + strings.Join(names, " and ")
}
```

Em Go, uma versão major acima de 1 não é só um número. **Da v2 em diante, a versão major faz parte do
caminho do módulo**, então a autora muda o caminho no `go.mod` antes de pôr a tag:

```
ana@vm:~/thirdparty-greet$ go mod edit -module example.com/ana/greet/v2 -dropretract=v1.1.0 && cat go.mod
module example.com/ana/greet/v2

go 1.27
ana@vm:~/thirdparty-greet$ git tag v2.0.0
ana@vm:~/thirdparty-greet$ find ~/thirdparty-proxy -name list | sort
/home/ana/thirdparty-proxy/example.com/ana/greet/@v/list
/home/ana/thirdparty-proxy/example.com/ana/greet/v2/@v/list
```

A retirada saiu porque fala da v1.1.0, que é versão do outro caminho; a linha v1 guarda a sua na
v1.1.1. O proxy agora tem dois módulos, cada um com a sua lista de versões, feitos do mesmo
repositório.

A regra tem um motivo, e é uma promessa a quem importa você: **um caminho de importação continua
significando a mesma API.** O código que importa `example.com/ana/greet` foi escrito para um `Hello`
que devolve um valor, e nada publicado depois pode mudar o que esse caminho significa. Uma API que
quebra ganha um caminho só dela. O `uax29` da seção 03 é um módulo real que passou por isso, e os
seus dois caminhos têm históricos separados:

```
ana@vm:~/thirdparty-width$ go list -m -versions github.com/clipperhouse/uax29
github.com/clipperhouse/uax29 v0.9.0 v0.9.1 v0.9.2 v0.9.3 v0.9.4 v0.9.6 v0.9.7 v0.9.8 v0.9.9 v0.9.10 v0.9.11 v1.0.0 v1.0.1 v1.0.2 v1.0.3 v1.0.4 v1.0.5 v1.0.6 v1.1.0 v1.2.0 v1.2.1 v1.5.0 v1.6.0 v1.6.1 v1.6.2 v1.6.3 v1.6.4 v1.6.5 v1.6.6 v1.6.7 v1.6.8 v1.6.9 v1.7.0 v1.7.1 v1.8.0 v1.9.0 v1.9.1 v1.10.0 v1.11.0 v1.12.0 v1.12.1 v1.12.2 v1.12.3 v1.12.4 v1.12.5 v1.13.0 v1.14.0 v1.14.2 v1.14.3 v1.15.0 v1.16.0
ana@vm:~/thirdparty-width$ go get github.com/clipperhouse/uax29@v2.7.0
go: github.com/clipperhouse/uax29@v2.7.0: invalid version: go.mod has post-v2 module path "github.com/clipperhouse/uax29/v2" at revision v2.7.0
```

A tag `v2.7.0` está no mesmo repositório que a `v1.16.0` e, pedida pelo caminho sem `/v2`, é
recusada, porque o próprio `go.mod` dela diz que ela pertence ao outro caminho. Um repositório cuja
tag `v2.0.0` mantivesse o caminho antigo no `go.mod` seria recusado do mesmo jeito; as versões
`+incompatible` da lição 38 são o que o comando go faz de repositórios que não tinham `go.mod`
nenhum.

## As duas ao mesmo tempo

Como as duas versões major são dois módulos, um programa pode usar as duas. O `main.go` de quem
importa mantém o pacote v1 e importa o v2 com um nome próprio, já que os dois pacotes se chamam
`greet`:

```go
package main

import (
	"fmt"

	"example.com/ana/greet"
	greetv2 "example.com/ana/greet/v2"
)

func main() {
	fmt.Println(greet.HelloAll("Ana", "Bia"))
	if _, err := greetv2.Hello(""); err != nil {
		fmt.Println(err)
	}
}
```

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go get example.com/ana/greet/v2@v2.0.0
go: downloading example.com/ana/greet/v2 v2.0.0
go: added example.com/ana/greet/v2 v2.0.0
ana@vm:~/thirdparty-app$ go mod tidy && go run .
Hello, Ana and Bia
greet: empty name
ana@vm:~/thirdparty-app$ go list -m all
example.com/app
example.com/ana/greet v1.1.1
example.com/ana/greet/v2 v2.0.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um repositório git, ~/thirdparty-greet, com cinco tags num mesmo branch: v0.1.0, v1.0.0, v1.1.0, v1.1.1 e v2.0.0. As quatro primeiras são versões do módulo example.com/ana/greet, e a v1.1.0 entre elas foi retirada. A tag v2.0.0 é versão de outro módulo, example.com/ana/greet/v2, porque o seu go.mod diz esse caminho. example.com/app requer a v1.1.1 do primeiro módulo e a v2.0.0 do segundo, e compila com as duas.\"><defs><marker id=\"mv-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um repositório, um branch, cinco tags</text><text x=\"20\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/thirdparty-greet</text><path d=\"M200 62 L680 62\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"224\" y=\"56\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v0.1.0</text><rect x=\"314\" y=\"56\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.0.0</text><rect x=\"404\" y=\"56\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.1.0</text><rect x=\"494\" y=\"56\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.1.1</text><rect x=\"624\" y=\"56\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v2.0.0</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">caminho do módulo</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">example.com/ana/greet</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">example.com/ana/greet/v2</text><path d=\"M230 94 L230 134\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#mv-wire)\"></path><rect x=\"196\" y=\"138\" width=\"68\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v0.1.0</text><path d=\"M320 94 L320 134\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#mv-wire)\"></path><rect x=\"286\" y=\"138\" width=\"68\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.0.0</text><path d=\"M410 94 L410 134\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#mv-wire)\"></path><rect x=\"376\" y=\"138\" width=\"68\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"410\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">v1.1.0</text><text x=\"410\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">retirada</text><path d=\"M500 94 L500 134\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#mv-wire)\"></path><rect x=\"466\" y=\"138\" width=\"68\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"500\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.1.1</text><path d=\"M630 94 L630 194\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#mv-wire)\"></path><text x=\"630\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o go.mod diz o caminho /v2</text><rect x=\"596\" y=\"198\" width=\"68\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"630\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v2.0.0</text><path d=\"M200 186 L680 186\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">example.com/app compila com as duas versões marcadas: dois módulos, um build</text></svg>", "caption": "Uma versão major nova é um caminho de módulo novo. O repositório é o mesmo; o que mudou foi o caminho no go.mod, e com ele o caminho de importação, então quem importa pode ter os dois."}
```

É isso que faz de uma atualização major algo que se faz um pacote de cada vez num programa grande, em
vez de tudo de uma vez. E é por isso que o comando go nunca a faz por você:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -u all
example.com/app
example.com/ana/greet v1.1.1
example.com/ana/greet/v2 v2.0.0
```

`example.com/ana/greet v1.1.1` não tem colchetes, embora a v2.0.0 exista. `-u`, `@latest` e
`go get -u` ficam dentro de um caminho de módulo, então nunca atravessam uma versão major. **Passar
para a v2 é uma mudança no seu código**, nos caminhos de importação e no que a API nova pedir das
chamadas, e você a faz depois de ler por que a autora quebrou a promessa.

Dois detalhes completam a regra. A v0 e a v1 dividem um caminho, porque a v0 nunca prometeu nada,
então a primeira release estável não precisa de caminho novo. E não existe sufixo `/v1` a
acrescentar:

```
ana@vm:~/thirdparty-v1$ go mod init example.com/ana/greet/v1
go: invalid module path "example.com/ana/greet/v1": major version suffixes must be in the form of /vN and are only allowed for v2 or later:
	go mod init example.com/ana/greet/v2
```
