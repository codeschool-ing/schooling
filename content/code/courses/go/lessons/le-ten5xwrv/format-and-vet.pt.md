---
title: gofmt, go vet e as opiniões do compilador
version: 1
---

Três programas leem o seu código antes de ele rodar, e cada um pega um tipo diferente de coisa. O
compilador recusa o que não é Go. O `gofmt` reescreve o que é Go mas está diagramado diferente do
código de todo mundo. O `go vet` aponta o que é Go válido e quase certamente um engano.

## gofmt: um layout, escolhido uma vez

Aqui está um programa que compila e roda, digitado por alguém com pressa:

```go
package main
import "fmt"
func main(){
    name:="Ana"
  fmt.Println( "Hello,",name )
}
```

O `gofmt -l` lista os arquivos cujo layout difere do padrão, e o `-d` mostra a diferença como um
diff:

```
ana@vm:~/tidy$ gofmt -l .
main.go
ana@vm:~/tidy$ gofmt -d main.go
diff main.go.orig main.go
--- main.go.orig
+++ main.go
@@ -1,6 +1,8 @@
 package main
+
 import "fmt"
-func main(){
-    name:="Ana"
-  fmt.Println( "Hello,",name )
+
+func main() {
+	name := "Ana"
+	fmt.Println("Hello,", name)
 }
```

O `go fmt` aplica isso aos arquivos do pacote e nomeia os que mudou:

```
ana@vm:~/tidy$ go fmt
main.go
ana@vm:~/tidy$ cat main.go
package main

import "fmt"

func main() {
	name := "Ana"
	fmt.Println("Hello,", name)
}
```

**Não há opções para o layout em si.** Nem largura de indentação, nem estilo de chaves, nem
comprimento de linha. Esse é o projeto: numa linguagem em que um único programa formata todo
arquivo, o diff entre duas versões mostra o que alguém mudou e nunca como o editor dessa pessoa
estava configurado, e uma revisão de código nunca gasta um comentário com o lugar de uma chave. A
maioria dos editores roda o `gofmt` ao salvar, e um arquivo Go sem formatação parece tão errado
para quem programa em Go quanto uma palavra com erro de grafia.

## O compilador recusa mais do que você espera

Algumas linguagens avisam sobre um import sem uso. Go se recusa a compilar:

```go
package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println("Hello, Go")
}
```

```
ana@vm:~/unused$ go run .; echo $?
# example.com/unused
./main.go:5:2: "os" imported and not used
1
```

`./main.go:5:2` é arquivo, linha e coluna: linha 5, segundo caractere, onde `"os"` começa depois da
tabulação. Uma variável local declarada e nunca usada é recusada do mesmo jeito, como a lição 5
mostra. As duas regras existem pelo mesmo motivo: um import custa tempo de compilação e tamanho de
binário, e uma variável sem uso muitas vezes é o erro de digitação de uma que é usada. Um aviso é
ignorado; um erro é corrigido.

## go vet: válido, e errado

Este compila, roda e imprime algo que ninguém queria:

```go
package main

import "fmt"

func main() {
	name := "Ana"
	fmt.Printf("Hello, %d\n", name)
}
```

```
ana@vm:~/vet$ go run .
Hello, %!d(string=Ana)
ana@vm:~/vet$ go vet; echo $?
main.go:7:21: fmt.Printf format %d has arg name of wrong type string
1
```

`%d` pede ao `Printf` um número inteiro e recebeu uma string, então ele imprimiu a reclamação na
saída em vez de quebrar: `%!d(string=Ana)` é o `fmt` dizendo qual verbo deu errado e o que recebeu.
O compilador não tem como pegar isso, porque para ele o formato é só uma string. **O `go vet` lê a
string de formato e confere os argumentos contra ela**, junto com algumas dezenas de outros padrões
que são Go válido e quase sempre bug.

O `go test` roda uma seleção dessas mesmas verificações automaticamente antes de rodar qualquer
teste, e é por isso que esse engano raramente chega a alguém num projeto com testes. Num projeto
sem eles, o `go vet` é o comando para rodar antes que outra pessoa leia o código.

A ordem, então, antes de mostrar um arquivo Go a alguém, é curta:

1. `go fmt` para diagramar.
2. `go vet` para achar os enganos que compilam.
3. `go build`, que os outros dois não substituem.
