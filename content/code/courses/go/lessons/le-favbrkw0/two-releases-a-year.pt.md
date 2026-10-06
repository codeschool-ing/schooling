---
title: Duas versões por ano
version: 1
---

Software costuma sair "quando estiver pronto", e uma linguagem que funcionasse assim deixaria você
adivinhando quando vem a próxima e por quanto tempo a sua recebe cuidado. **Go sai num calendário:
uma versão nova todo fevereiro e todo agosto.** Não é afirmação para aceitar de confiança, porque o
proxy de módulos, o servidor de onde o comando go baixa as coisas, publica um registro de cada
versão. Cada toolchain é um módulo ali, e o arquivo `.info` dele traz o momento em que foi
registrado:

```
ana@vm:~/history$ for v in 21 22 23 24 25 26 27; do curl -s https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.$v.0.linux-amd64.info; echo; done
{"Version":"v0.0.1-go1.21.0.linux-amd64","Time":"2023-08-04T20:14:06Z"}
{"Version":"v0.0.1-go1.22.0.linux-amd64","Time":"2024-02-02T18:09:55Z"}
{"Version":"v0.0.1-go1.23.0.linux-amd64","Time":"2024-08-07T19:21:44Z"}
{"Version":"v0.0.1-go1.24.0.linux-amd64","Time":"2025-02-10T23:33:55Z"}
{"Version":"v0.0.1-go1.25.0.linux-amd64","Time":"2025-08-08T19:33:32Z"}
{"Version":"v0.0.1-go1.26.0.linux-amd64","Time":"2026-02-10T01:22:00Z"}
{"Version":"v0.0.1-go1.27.0.linux-amd64","Time":"2026-08-18T21:24:23Z"}
```

Agosto, fevereiro, agosto, fevereiro, agosto, fevereiro, agosto. O laço pede sete versões pelo
número, e o nome tem `linux-amd64` porque um toolchain é publicado uma vez por sistema. Os horários
estão em UTC e caem alguns dias antes do anúncio de cada versão: o go1.21.0 foi registrado em 4 de
agosto de 2023 e anunciado no dia 8, a data que a seção 02 deu.

## Duas com suporte de cada vez

Uma versão não recebe cuidado para sempre. A instalação de Go diz por quanto tempo, no próprio
`SECURITY.md`:

```
ana@vm:~/history$ sed -n 3,5p /usr/local/go/SECURITY.md
## Supported Versions

We support the past two Go releases (for example, Go 1.17.x and Go 1.18.x when Go 1.18.x is the latest stable release).
```

O histórico de versões diz a mesma regra de outro jeito: **cada versão principal tem suporte até
existirem duas versões principais mais novas**, e problemas críticos, os de segurança inclusive, são
corrigidos numa versão com suporte por meio de uma revisão menor. Numa versão como `go1.27.1`, 27 é
a versão principal e 1 a revisão menor: a primeira versão de correção do 1.27. Com uma versão a cada
seis meses, ter suporte quer dizer cerca de um ano.

O proxy mostra a regra sendo aplicada. Eis o que saiu em volta do go1.27.0:

```
ana@vm:~/history$ for v in 1.25.14 1.26.7 1.27.0 1.26.8 1.27.1; do curl -s https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go$v.linux-amd64.info; echo; done
{"Version":"v0.0.1-go1.25.14.linux-amd64","Time":"2026-08-18T21:44:21Z"}
{"Version":"v0.0.1-go1.26.7.linux-amd64","Time":"2026-08-18T21:44:21Z"}
{"Version":"v0.0.1-go1.27.0.linux-amd64","Time":"2026-08-18T21:24:23Z"}
{"Version":"v0.0.1-go1.26.8.linux-amd64","Time":"2026-08-28T16:20:06Z"}
{"Version":"v0.0.1-go1.27.1.linux-amd64","Time":"2026-08-28T16:20:06Z"}
ana@vm:~/history$ curl -s https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.25.15.linux-amd64.info; echo
not found: golang.org/toolchain@v0.0.1-go1.25.15.linux-amd64: reading https://go.dev/dl/mod/golang.org/toolchain/@v/v0.0.1-go1.25.15.linux-amd64.info: 404 Not Found
```

Em 18 de agosto de 2026 chegou o go1.27.0 e, na mesma hora, versões de correção das duas
anteriores, go1.25.14 e go1.26.7. Dez dias depois vieram go1.27.1 e go1.26.8, registrados no mesmo
segundo. Não existe go1.25.15: assim que o 1.27 existiu, o 1.25 passou a ter duas versões mais novas
e parou de receber correções. **A versão deste laboratório é uma versão de correção da série mais
nova, que é onde convém estar.** Num servidor, a regra prática que decorre disso é rodar a revisão
menor mais recente de uma versão com suporte e subir de versão pelo menos uma vez por ano.

## O comando go pode buscar outro Go

Desde o Go 1.21 o comando go não precisa rodar a versão com que veio. A variável de ambiente
`GOTOOLCHAIN` decide, e o padrão dela vem no `go.env` da instalação:

```
ana@vm:~/history-auto$ go env GOTOOLCHAIN
local
ana@vm:~/history-auto$ grep GOTOOLCHAIN /usr/local/go/go.env
GOTOOLCHAIN=auto
ana@vm:~/history-auto$ GOTOOLCHAIN=go1.26.0 go version
go: downloading go1.26.0 (linux/amd64)
go version go1.26.0 linux/amd64
ana@vm:~/history-auto$ GOTOOLCHAIN=go1.26.0 go version
go version go1.26.0 linux/amd64
```

A versão vem com `auto`; o laboratório define `local`, como a lição 3 mostra, para que toda
transcrição deste curso venha do go1.27.1 e nunca de uma versão buscada sem você saber. Nomear uma
versão a força: **`GOTOOLCHAIN=go1.26.0` fez o comando go baixar o toolchain inteiro do proxy de
módulos e executá-lo**, sozinho, sem nada instalado à mão. Na segunda vez não houve download, porque
ele já estava no cache de módulos, dentro de `~/go`.

`auto` é a configuração do dia a dia, e o que ela faz depende do módulo. Este aqui pede o 1.25.0:

```go
// Command which prints the release of Go that compiled it.
package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Println("compiled by", runtime.Version())
}
```

```
ana@vm:~/history-auto$ cat go.mod
module example.com/which

go 1.25.0
ana@vm:~/history-auto$ go run .
compiled by go1.27.1
ana@vm:~/history-auto$ GOTOOLCHAIN=go1.24.0+auto go run .
go: downloading go1.25.0 (linux/amd64)
compiled by go1.25.0
```

O go1.27.1 é mais novo que o 1.25.0 que o módulo pede, então compilou o programa ele mesmo. Para ver
o que uma instalação mais antiga faz, `go1.24.0+auto` diz ao comando go para começar como se o 1.24.0
fosse a versão instalada e ainda assim trocar quando um módulo pede mais. O módulo pediu o 1.25.0,
então o comando go baixou o go1.25.0 e o executou. **Com `auto`, uma linha `go` mais nova que o seu Go
não é erro: o comando go busca a versão de que o módulo precisa e segue em frente.** Com `local` é a
recusa que a lição 3 mostra.

A linha `toolchain` é o módulo dizendo com que versão prefere ser compilado, que pode ser mais nova
que o mínimo exigido pela linha `go`:

```
ana@vm:~/history-auto$ go mod edit -go=1.22 -toolchain=go1.26.0 && cat go.mod
module example.com/which

go 1.22

toolchain go1.26.0
ana@vm:~/history-auto$ GOTOOLCHAIN=go1.24.0+auto go run .
compiled by go1.26.0
ana@vm:~/history-auto$ go run .
compiled by go1.27.1
```

`go 1.22` sozinho seria atendido pelo 1.24.0. A linha `toolchain` empurrou a escolha para o
go1.26.0, que já estava no cache. Com `local`, o go1.27.1 compilou ele mesmo: é mais novo que as
duas linhas, e `local` proíbe a troca de qualquer jeito.

Então um `go.mod` responde a três perguntas. **A linha `go` é a versão mínima e a versão da
linguagem que o código quer dizer; a linha `toolchain` é a versão que o módulo prefere; `GOTOOLCHAIN`
diz se o seu comando go pode buscar uma ou outra.**
