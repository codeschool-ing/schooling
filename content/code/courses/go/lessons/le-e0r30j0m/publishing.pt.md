---
title: "Publicar um módulo: uma tag é uma versão"
version: 1
---

A maioria dos ecossistemas de pacotes publica fazendo upload: uma conta num registro, um comando que
envia um arquivo para ele, e a cópia do registro é a release. **Go não tem registro e não tem nada
para enviar.** O caminho de um módulo diz em que repositório ele mora, uma versão é uma tag nesse
repositório, e publicar é enviar a tag com push. O proxy que atendeu todos os downloads deste curso
lê o repositório quando alguém pede uma versão, e a resposta dele diz de onde a versão veio:

```
ana@vm:~/thirdparty-width$ curl -s https://proxy.golang.org/github.com/mattn/go-runewidth/@v/v0.0.16.info; echo
{"Version":"v0.0.16","Time":"2024-07-22T12:40:34Z","Origin":{"VCS":"git","URL":"https://github.com/mattn/go-runewidth","Hash":"6ceadc68530e7bfea8cba17d6523bed32912d4fa","Ref":"refs/tags/v0.0.16"}}
```

A versão que a seção 02 instalou é a tag git `refs/tags/v0.0.16` de um repositório no GitHub, num
commit cujo hash o proxy anotou. Uma release de Go é só isso.

## O que os números prometem

Uma versão são três números, `vMAJOR.MINOR.PATCH`, e os módulos Go seguem a convenção chamada
Semantic Versioning sobre o que cada um significa:

| você muda | então sobe | por exemplo | o que quem usa pode supor |
|---|---|---|---|
| um bug, sem mexer na API | PATCH | v1.1.0 para v1.1.1 | atualizar sem ler nada |
| algo acrescentado: uma função, um campo | MINOR | v1.0.0 para v1.1.0 | o código dele continua compilando |
| algo removido ou mudado | MAJOR | v1.1.1 para v2.0.0 | nada; é um módulo novo (seção 05) |

**A v0 não promete nada.** Abaixo da v1.0.0 qualquer release pode quebrar qualquer coisa, e esse é o
estado honesto de um módulo cuja API ainda está sendo descoberta: o `go-runewidth` está na v0.0.30
depois de anos de uso. Da v1.0.0 em diante a promessa é a que a lição 35 descreveu para um erro
sentinela, feita para a API inteira: o que quem chama consegue nomear, consegue continuar nomeando
até a v2.

## Um módulo seu, publicado no lab

O lab não tem um serviço de hospedagem de código, então faz o papel de um. `~/thirdparty-greet` é um
repositório git comum com um módulo cujo `go.mod` diz `module example.com/ana/greet`, com este único
arquivo:

```go
// Package greet says hello.
package greet

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}
```

O trabalho foi para um commit, e lançá-lo é um comando:

```
ana@vm:~/thirdparty-greet$ git tag v0.1.0
ana@vm:~/thirdparty-greet$ git log --oneline --decorate
c110eac (HEAD -> main, tag: v0.1.0) greet: Hello
```

Num serviço de verdade, `git push origin v0.1.0` seria a publicação. Aqui, um pequeno programa que o
lab escreveu faz o que o proxy faz na primeira vez que alguém pede uma versão: lê a tag e grava as
respostas num diretório, `~/thirdparty-proxy`, organizado do jeito que o protocolo `GOPROXY` pede. O
`go help goproxy` diz que um diretório assim, dado como URL `file://`, é um proxy como outro
qualquer:

```
ana@vm:~/thirdparty-greet$ find ~/thirdparty-proxy -type f | sort
/home/ana/thirdparty-proxy/example.com/ana/greet/@v/list
/home/ana/thirdparty-proxy/example.com/ana/greet/@v/v0.1.0.info
/home/ana/thirdparty-proxy/example.com/ana/greet/@v/v0.1.0.mod
/home/ana/thirdparty-proxy/example.com/ana/greet/@v/v0.1.0.zip
ana@vm:~/thirdparty-greet$ cat ~/thirdparty-proxy/example.com/ana/greet/@v/v0.1.0.info; echo
{"Time":"2026-10-01T10:00:00-03:00","Version":"v0.1.0"}
```

Sob o caminho do módulo, `@v/list` dá o nome das versões, `.info` diz quando cada uma foi feita,
`.mod` é o `go.mod` dela e `.zip` são os arquivos. Esses quatro, mais `@latest`, são todos os pedidos
que o comando go faz a um proxy; o código-fonte dele, `cmd/go/internal/modfetch/proxy.go`, tem uma
função para cada um.

## Depender dele, e o banco de checksums

Outro módulo, `~/thirdparty-app`, importa `example.com/ana/greet` e chama `Hello("Ana")`. Todo
comando que lê o módulo publicado aponta para o proxy do lab com `GOPROXY`. A primeira tentativa não
diz mais nada:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy go get example.com/ana/greet@v0.1.0
go: downloading example.com/ana/greet v0.1.0
go: example.com/ana/greet@v0.1.0: verifying module: example.com/ana/greet@v0.1.0: reading https://sum.golang.org/lookup/example.com/ana/greet@v0.1.0: 404 Not Found
	server response: not found: example.com/ana/greet@v0.1.0: unrecognized import path "example.com/ana/greet": reading https://example.com/ana/greet?go-get=1: 404 Not Found
```

O download funcionou e a verificação não. A lição 38 mostrou que o comando go confere todo módulo no
banco público de checksums, sum.golang.org, antes de usá-lo. **O banco não acredita na sua palavra
sobre o conteúdo de um módulo: ele mesmo busca o módulo**, pelo caminho, e aqui o caminho leva a
`example.com`, onde ninguém responde. Um módulo público de verdade passa por esse passo na primeira
vez que alguém o baixa, e daí em diante o hash dele fica fixo para todo mundo.

Um módulo que não é público, como um de dentro de uma empresa, entra em `GONOSUMDB`, ou em
`GOPRIVATE`, que o `go help private` descreve e que também o mantém longe do proxy público. O lab põe
`GONOSUMDB=example.com` ao lado do `GOPROXY` em todo comando daqui em diante:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go get example.com/ana/greet@v0.1.0
go: downloading example.com/ana/greet v0.1.0
go: added example.com/ana/greet v0.1.0
ana@vm:~/thirdparty-app$ go mod tidy && go run .
Hello, Ana
ana@vm:~/thirdparty-app$ cat go.sum
example.com/ana/greet v0.1.0 h1:FmIo6uqFcLn7girE5x/uPjTRwuOZFptQYGM6k1U18QI=
example.com/ana/greet v0.1.0/go.mod h1:QFMWQnEnM/cie1zlph17cNjMg9a7FN9R8vsm06XS5Fw=
```

O `go.sum` registrou o hash do zip e do `go.mod`, como faz para qualquer módulo. Suponha que o autor
agora mude o código e mova a tag, em vez de fazer uma versão nova. O lab deixou isso acontecer: pôs a
tag `v0.1.0` em outro commit, publicou de novo por cima dos arquivos antigos e apagou a cópia do
cache de módulos, para que o comando go tivesse de baixá-la outra vez:

```
ana@vm:~/thirdparty-greet$ git tag -f v0.1.0
Updated tag 'v0.1.0' (was c110eac)
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go mod download example.com/ana/greet@v0.1.0
verifying example.com/ana/greet@v0.1.0: checksum mismatch
	downloaded: h1:AG4vmWZeBI+aVcIbTfsxRx1h8ETLnamdXmXn+hZZ1zI=
	go.sum:     h1:FmIo6uqFcLn7girE5x/uPjTRwuOZFptQYGM6k1U18QI=

SECURITY ERROR
This download does NOT match an earlier download recorded in go.sum.
The bits may have been replaced on the origin server, or an attacker may
have intercepted the download attempt.

For more information, see 'go help module-auth'.
```

O comando go não distingue um autor descuidado de um atacante, e trata os dois do mesmo jeito. Para
um módulo público, o banco de checksums o recusaria para todo mundo, não só para quem já o tinha
baixado. **Uma versão publicada não pode ser mudada, só seguida por outra.** O lab devolveu a tag ao
lugar antes de continuar.

## Versões novas

A autora então pôs a tag v1.0.0 num commit que só mudou o comentário do pacote, prometendo a API, e
escreveu uma segunda função para a v1.1.0. É uma função nova e nada antigo mudou, então sobe o número
minor:

```go
// Package greet says hello. From v1.0.0 on, its API only grows.
package greet

import "strings"

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}

// HelloAll greets several people at once.
func HelloAll(names ...string) string {
	return "Hello, " + strings.Join(names, "")
}
```

```
ana@vm:~/thirdparty-greet$ git tag v1.1.0
ana@vm:~/thirdparty-greet$ git tag
v0.1.0
v1.0.0
v1.1.0
```

Cada tag foi para o proxy como a v0.1.0 foi. Quem importa as vê com os comandos da seção 02:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -versions example.com/ana/greet
example.com/ana/greet v0.1.0 v1.0.0 v1.1.0
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -u all
example.com/app
example.com/ana/greet v0.1.0 [v1.1.0]
```

Quem importa estava na v0.1.0, que não prometia nada, e decide passar para a linha estável:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go get example.com/ana/greet@latest
go: downloading example.com/ana/greet v1.1.0
go: upgraded example.com/ana/greet v0.1.0 => v1.1.0
```

O `main.go` de quem importa agora também chama `HelloAll("Ana", "Bia")`, e a função nova tem um bug
que passou pelos olhos da autora:

```
ana@vm:~/thirdparty-app$ go run .
Hello, Ana
Hello, AnaBia
```

Os nomes saem grudados, sem nada entre eles. A v1.1.0 está publicada, alguém já atualizou para ela,
e o hash dela está no `go.sum` dessa pessoa. A seção 05 é o que a autora faz em seguida.
