---
title: Quando a instalação falha
version: 1
---

Uma instalação que falha quase nunca diz "a sua instalação falhou". Ela diz alguma coisa sobre um
arquivo, uma versão ou um servidor, e a tentação é reinstalar tudo e torcer. **Cada falha abaixo
tem uma causa, e a mensagem a nomeia**, se você ler a mensagem até o fim. As três foram provocadas
de propósito no laboratório.

## `go: command not found`

O shell olhou em cada diretório do `PATH`, não achou programa chamado `go` e desistiu antes de o
Go entrar na história:

```
ana@vm:~/setup$ PATH=/usr/bin:/bin; go version; echo $?
bash: line 1: go: command not found
127
ana@vm:~/setup$ PATH=/usr/bin:/bin; . ~/.profile; go version
go version go1.27.1 linux/amd64
```

**O código de saída 127 é o número do próprio shell para "comando inexistente"**, então a mensagem
é do `bash`, não do Go. A instalação está boa; só o `PATH` está errado. Duas causas cobrem quase
todos os casos: as linhas da seção 03 nunca foram acrescentadas ao `~/.profile`, ou foram e este
terminal foi aberto antes de elas existirem. O segundo comando acima é o conserto do segundo caso:
leia o arquivo de novo com `.`, ou saia e entre outra vez.

O caso espelhado tem a mesma causa. Se o `go version` imprime uma versão mais velha do que a que
você acabou de descompactar, outro `go` está antes no `PATH`, talvez um que um gerenciador de
pacotes instalou anos atrás. O `command -v go` diz qual arquivo de fato roda.

## `go.mod requires go >= …`

Um módulo diz no seu `go.mod` para qual Go foi escrito, e um toolchain mais velho que isso se
recusa a compilá-lo. O Go 1.28 ainda não saiu enquanto isto é escrito, então um `go.mod` pedindo
por ele é um jeito seguro de ver a recusa:

```
ana@vm:~/setup-new$ go run .; echo $?
go: go.mod requires go >= 1.28 (running go 1.27.1; GOTOOLCHAIN=local)
1
```

Tudo o que é preciso está entre os parênteses. O módulo quer a 1.28, o toolchain que roda é a
1.27.1, e `GOTOOLCHAIN=local` diz que o comando go foi instruído a não buscar outro. Essa última
parte é escolha deste laboratório, feita no ambiente dele, como a seção 03 mostrou. Com o padrão
`auto`, o comando go baixaria a versão que o módulo pede e seguiria em frente, como mostra a
lição 2.

Então há duas saídas. **Instalar a versão mais nova** do jeito que a seção 02 fez, ou deixar o
comando go buscá-la, sem forçar `local`. Baixar a linha `go` do `go.mod` para a sua versão esconde a
mensagem sem tornar o código mais velho. Ele pode usar algo que a sua versão não tem, e aí a falha
volta como um erro de compilação mais difícil de ler.

## Um proxy de módulos que não responde

Na primeira vez que um módulo precisa de algo que ainda não tem, o comando go pede ao proxy de
módulos. Se o proxy não pode ser alcançado, a mensagem é longa e se lê da esquerda para a direita,
do que se queria até o motivo de não ter conseguido:

```
ana@vm:~/setup-proxy$ GOPROXY=https://proxy.invalid go get golang.org/x/text@latest; echo $?
go: golang.org/x/text@latest: module golang.org/x/text: Get "https://proxy.invalid/golang.org/x/text/@v/list": dial tcp: lookup proxy.invalid on 8.8.8.8:53: no such host
1
ana@vm:~/setup-proxy$ go env GOPROXY
https://proxy.golang.org,direct
```

Os dois primeiros campos são o que foi pedido, `golang.org/x/text` na versão mais recente. O
`Get` é o endereço que o comando go tentou. Tudo depois dos últimos dois-pontos é o motivo: o
servidor de nomes da máquina, `8.8.8.8`, não conhece host chamado `proxy.invalid`. `.invalid` é um
nome reservado para nunca resolver, o que fez dele um proxy quebrado seguro para a demonstração.

**Quando um download falha, olhe o `GOPROXY` antes de olhar a rede.** Ele veio de um dos três
lugares da seção 03. O culpado de sempre é um valor que alguém definiu meses atrás, num shell, num
`go env -w` ou no script de configuração de uma empresa. O `go env -u GOPROXY` devolve o seu
próprio arquivo ao padrão da versão. Se o problema for a rede, a mesma linha diz isso com outras
palavras: um timeout, uma conexão recusada, um certificado em que ele não confia.

## Uma verificação curta, antes de perguntar a alguém

Quatro comandos respondem à maioria das perguntas sobre uma instalação de Go, e são o que qualquer
pessoa que for ajudar você vai pedir primeiro:

1. `go version`: qual versão roda, e se existe alguma.
2. `command -v go`: qual arquivo é esse.
3. `go env GOROOT GOPATH`: onde ele acha que mora e para onde vão os seus downloads.
4. `go env -changed`: toda configuração que não é a padrão, venha de onde vier.
