---
title: if e else
version: 1
---

Um `if` em Go é uma condição, depois um bloco entre chaves e, opcionalmente, `else` e outro bloco.
**A condição tem de ser um `bool`**: a lição 8 mostrou o compilador recusando `if n` para um
número, então um teste de "diferente de zero" é escrito por extenso, `n != 0`. Cadeias de escolhas
são `else if`, e o último `else` pega o que sobrar. Este programa, em `~/cond`, separa três
números em três tipos:

```go
// Command sign says whether each number is negative, zero or positive.
package main

import "fmt"

func main() {
	for _, n := range []int{-4, 0, 7} {
		if n < 0 {
			fmt.Println(n, "is negative")
		} else if n == 0 {
			fmt.Println(n, "is zero")
		} else {
			fmt.Println(n, "is positive")
		}
	}
}
```

```
ana@vm:~/cond$ go run .
-4 is negative
0 is zero
7 is positive
```

As condições são testadas de cima para baixo, e a primeira verdadeira escolhe o seu bloco e
encerra a cadeia. Para 0, `n < 0` foi falso e `n == 0` foi verdadeiro, então o `else` final nem
entrou na história.

Até aqui é igual na maioria das linguagens com chaves. O que muda são três hábitos que quem
programa traz de C, Java ou JavaScript, e Go trata cada um de um jeito.

## Parênteses: permitidos, e removidos

Go não precisa de parênteses em volta da condição, porque a chave de abertura já marca onde a
condição termina. Escrevê-los mesmo assim compila, e o `gofmt` os tira:

```
ana@vm:~/cond-parens$ go run .
7 is positive
ana@vm:~/cond-parens$ gofmt -d main.go
diff main.go.orig main.go
--- main.go.orig
+++ main.go
@@ -4,7 +4,7 @@
 
 func main() {
 	n := 7
-	if (n > 0) {
+	if n > 0 {
 		fmt.Println(n, "is positive")
 	}
 }
```

Então `if (n > 0)` não está errado, só é incomum, e dura até a próxima vez que alguém salvar o
arquivo num editor que roda o `gofmt`. Parênteses dentro de uma condição, para agrupar
`a && (b || c)`, são outra coisa e ficam onde você os pôs.

## Chaves: nunca opcionais

Em C, um `if` seguido de um único comando não precisa de chaves. **Em Go as chaves fazem parte do
`if` e não existe forma sem elas**, nem para uma linha só:

```go
package main

import "fmt"

func main() {
	n := 7
	if n > 0 fmt.Println(n, "is positive")
}
```

```
ana@vm:~/cond-braces$ go build
# example.com/braces
./main.go:7:11: syntax error: unexpected name fmt, expected {
./main.go:8:1: syntax error: unexpected }, expected expression
```

A coluna 11 é onde `fmt` começa, e o parser diz o que queria ali no lugar. A segunda linha decorre
da primeira: depois que o `if` deu errado, o parser não esperava mais a chave que fecha `main` onde
ela está. A regra elimina uma família inteira de bugs. Numa linguagem com chaves opcionais, uma
segunda linha indentada sob um `if` parece pertencer a ele, e roda sempre.

## else: na mesma linha da chave

Esta surpreende quem põe cada chave numa linha própria:

```go
package main

import "fmt"

func main() {
	n := 7
	if n > 0 {
		fmt.Println(n, "is positive")
	}
	else {
		fmt.Println(n, "is not positive")
	}
}
```

```
ana@vm:~/cond-else$ go build
# example.com/else
./main.go:10:2: syntax error: unexpected keyword else, expected }
ana@vm:~/cond-else$ go doc go/scanner.Scanner.Scan | sed -n 13,15p
    If the returned token is token.SEMICOLON, the corresponding literal string
    is ";" if the semicolon was present in the source, and "\n" if the semicolon
    was inserted because of a newline or at EOF. If the newline is within a
```

O motivo são os pontos e vírgulas que você nunca digitou. A gramática de Go termina comandos com
`;`, e o scanner **insere um no fim de uma linha** cujo último token poderia terminar um comando,
como uma chave de fechamento. A documentação de `go/scanner`, o pacote da biblioteca padrão que lê
código-fonte Go, descreve isso: um ponto e vírgula inserido volta com o literal `"\n"`. Então a `}`
da linha 9 encerrou o comando `if` inteiro, e a linha 10 começou um comando novo com `else`, e
nenhum comando pode começar com ele.

Ponha o `else` depois da chave, `} else {`, como em `~/cond`, e a linha deixa de terminar numa
chave. A mesma regra explica por que uma chave de abertura fica na mesma linha do `func`, do `for`
ou do `if` a que pertence. Uma chave sozinha na linha seguinte vem depois de um ponto e vírgula
inserido, e o compilador diz isso com essas palavras:

```go
package main

import "fmt"

func main()
{
	fmt.Println("hello")
}
```

```
ana@vm:~/cond-brace$ go build
# example.com/brace
./main.go:6:1: syntax error: unexpected semicolon or newline before {
```

**Em Go, o lugar de uma chave é gramática, não estilo.** Esse é um dos motivos de o `gofmt` poder
não ter opções para isso: só existe um lugar onde uma chave pode ficar.
