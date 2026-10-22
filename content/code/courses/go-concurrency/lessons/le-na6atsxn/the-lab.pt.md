---
title: A máquina do curso de Go, e mais um compilador
version: 1
---

Toda lição deste curso pede que você digite alguma coisa e leia o que volta. **A máquina em que
você digita é a que o curso `go` montou**, e esta seção confere que ela ainda responde. Ela
acrescenta uma coisa de que o curso `go` nunca precisou: um compilador de C, porque o detector de
corridas em que este curso se apoia, desta lição até a lição 16, não funciona sem um.

## Os três caminhos, em resumo

A lição 3 de `go` traz os três por inteiro, com o que cada um custa ao seu computador. Aqui estão
de novo, e o curso recomenda o mesmo:

| caminho | o que você ganha | o que isso significa para este curso |
|---|---|---|
| **instalado** (recomendado) | o Go 1.27.1 descompactado em `/usr/local/go`, mais o `gcc` do seu sistema | toda transcrição roda como impressa no Ubuntu 24.04, e quase assim no macOS |
| **uma máquina virtual** | uma máquina Ubuntu 24.04 com as mesmas duas coisas dentro | o mesmo, byte a byte, ao preço do disco e da memória de um segundo sistema operacional |
| **online** | o Go Playground em go.dev/play | as lições 1 a 15 em pedaços; sem terminal, não há onde digitar `go run -race` nem `go test` |

O Playground é um bom lugar para testar um trecho no ônibus. É o lugar errado para este curso,
porque metade do que o curso ensina é ler o que o comando go imprime, e os tempos desta lição
seriam medidos na máquina de outra pessoa.

## O Go, como o curso `go` deixou

Se você fez `go`, não tem nada para instalar. O arquivo foi para `/usr/local/go` e duas linhas
foram para o `~/.profile`. Se não fez, a lição 3 de `go` é a versão longa, e a curta é o arquivo de
**go.dev/dl**, descompactado depois de apagar o diretório antigo:

```sh
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.27.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.profile
```

Esse bloco **não foi executado neste laboratório**, que não alcança go.dev; o laboratório pegou a
mesma versão do proxy de módulos, como a lição 3 de `go` explica. **Use a mesma versão com que o
curso foi gravado**, a 1.27.1, e não mantenha um segundo Go ao lado dela. Dois toolchains no mesmo
`PATH` significam que roda o que vier primeiro, e uma transcrição diferente da lição vira um
enigma sobre a sua máquina, e não sobre Go.

## O compilador de C

**`go run -race` e `go test -race` compilam o seu programa com o detector de corridas dentro**, e
o detector de corridas é o ThreadSanitizer, um runtime escrito em C++. O comando go o liga ao
programa por meio do cgo, a ponte de Go para C, e o cgo precisa de um compilador de C na máquina.
No Ubuntu 24.04 isso é um pacote do próprio repositório do sistema:

```sh
sudo apt install gcc
```

Essa linha também **não foi executada neste laboratório**, porque a máquina do laboratório já
tinha o `gcc`. O `apt` lista os pacotes que vai acrescentar e o disco que vão ocupar, e pergunta
antes de fazer qualquer coisa; o compilador traz junto o montador, o ligador e os cabeçalhos da
biblioteca C. No macOS o equivalente é `xcode-select --install`, que instala as ferramentas de
linha de comando da Apple.

## Conferindo que cada ferramenta responde

Quatro comandos, e vale comparar cada linha que eles imprimem com as suas:

```
ana@vm:~/promise$ go version
go version go1.27.1 linux/amd64
ana@vm:~/promise$ command -v go gofmt gcc
/usr/local/go/bin/go
/usr/local/go/bin/gofmt
/usr/bin/gcc
ana@vm:~/promise$ gcc --version | head -1
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
ana@vm:~/promise$ go env CGO_ENABLED CC
1
gcc
```

As duas primeiras linhas são a máquina do curso `go`, sem mudança. O último comando é o que este
curso acrescenta. **`CGO_ENABLED` vale `1` porque o comando go procurou o `gcc` e o encontrou**;
não é uma configuração que alguém escreveu, e a seção 05 mostra esse valor virando `0` numa
máquina em que a busca falha.

Mais uma conferência prova a corrente inteira, do comando go até o runtime em C. **Todo programa
deste curso mora num diretório próprio na sua pasta pessoal**, `~/promise` nesta lição, com um
`go.mod` criado por `go mod init example.com/promise`, como a lição 38 de `go` mostrou. Cada lição
dá o nome do seu diretório na primeira vez que o usa. Esta começa com um programa de três
goroutines, o assunto da lição 2, cada uma imprimindo uma linha, salvo como `order.go`:

```go
// Command order starts three goroutines that each print a line.
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	for _, name := range []string{"ana", "bia", "caio"} {
		wg.Go(func() { fmt.Println("hello from", name) })
	}
	wg.Wait()
}
```

`wg.Go` inicia uma função como goroutine e `wg.Wait` espera até que todas tenham retornado; a
lição 9 desmonta o `WaitGroup`. Compilado com o detector de corridas dentro, um programa sem
corrida imprime exatamente o que imprimiria sem ele:

```
ana@vm:~/promise$ go run -race order.go
hello from ana
hello from bia
hello from caio
```

**Se o seu imprimiu três saudações, o laboratório está pronto**, na ordem que for. A seção 04
explica por que a ordem não é você quem escolhe.
