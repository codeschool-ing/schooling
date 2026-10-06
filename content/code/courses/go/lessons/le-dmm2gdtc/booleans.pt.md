---
title: Booleanos, e nada mais é verdadeiro
version: 1
---

Em Python e JavaScript quase tudo pode ficar onde vai uma condição: um número é falso quando é
zero, uma string quando está vazia, e todo o resto conta como verdadeiro. C faz o mesmo com
números e ponteiros. Go não tem essa regra. **Uma condição em Go é um `bool`, e nenhum outro tipo
vira um** — nem sozinho, nem quando você pede. Aqui está o hábito das outras linguagens, digitado
em `~/runes-truthy`:

```go
package main

import "fmt"

func main() {
	count := 3
	name := "Ana"
	if count {
		fmt.Println("there is work to do")
	}
	if name {
		fmt.Println("hello,", name)
	}
	ready := bool(count)
	fmt.Println(!count, ready)
}
```

```
ana@vm:~/runes-truthy$ go run .; echo $?
# example.com/truthy
./main.go:8:5: non-boolean condition in if statement
./main.go:11:5: non-boolean condition in if statement
./main.go:14:16: cannot convert count (variable of type int) to type bool
./main.go:15:15: invalid operation: operator ! not defined on count (variable of type int)
1
```

Quatro linhas, quatro recusas, e nada executou. As linhas 8 e 11 põem um `int` e uma `string` onde
o `if` quer um `bool`. A linha 14 pede a conversão com todas as letras, `bool(count)`, e Go não tem
conversão nenhuma de número para valor-verdade. A linha 15 é a mesma regra pelo outro lado: `!`
quer dizer "não", e só está definido para `bool`.

A regra custa alguns caracteres e elimina uma pergunta. Numa linguagem com valores "verdadeiros",
`if count` pode ser um teste de zero, ou de "foi definido", ou um bug; quem lê precisa adivinhar
qual. Em Go a condição diz o que testa, porque é obrigada a dizer.

## Diga o que você quer, e os operadores

O conserto é escrever a comparação que você queria. Uma comparação produz um `bool`, então
`count > 0` e `name != ""` são condições. O programa em `~/runes-bool` fica com as duas e
acrescenta os três operadores lógicos:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tcount := 3\n\tname := \"Ana\"\n",
      "note": "As mesmas duas variáveis de `~/runes-truthy`, um `int` e uma `string`."
    },
    {
      "code": "\tif count > 0 {\n\t\tfmt.Println(\"there is work to do\")\n\t}\n\tif name != \"\" {\n\t\tfmt.Println(\"hello,\", name)\n\t}\n",
      "note": "**Uma comparação produz um `bool`**, então essas duas condições compilam. `count > 0` e `name != \"\"` dizem o que a versão anterior deixava o leitor adivinhar: um teste de contagem positiva e um teste de nome não vazio."
    },
    {
      "code": "\n\ttests, lint := true, false\n\tfmt.Println(tests && lint, tests || lint, !lint)\n",
      "note": "`&&` é verdadeiro quando os dois lados são, `||` quando pelo menos um é, e `!` inverte um valor. Com `tests` verdadeiro e `lint` falso, eles imprimem `false true true`."
    },
    {
      "code": "\tfmt.Println(tests != lint, tests == lint)\n",
      "note": "`==` e `!=` funcionam em booleanos como em qualquer outro tipo. `tests != lint` é verdadeiro exatamente quando os dois diferem, e por isso é o ou exclusivo de Go."
    },
    {
      "code": "\tfmt.Printf(\"%t %v %T\\n\", tests, tests, tests)\n}\n",
      "note": "`%t` é o verbo de formatação de um booleano. `%v` imprime a mesma palavra, e `%T` dá o nome do tipo."
    }
  ],
  "output": "there is work to do\nhello, Ana\nfalse true true\ntrue false\ntrue true bool"
}
```

**`&&`, `||` e `!` recebem `bool` e devolvem `bool`**, e não existe um quarto. O ou exclusivo,
verdadeiro quando exatamente um lado é verdadeiro, é o `!=` entre dois booleanos, que foi o que a
quarta linha da saída imprimiu. O operador que significa ou exclusivo em inteiros é recusado:

```
ana@vm:~/runes-xor$ go run .
# example.com/xor
./main.go:7:14: invalid operation: operator ^ not defined on tests (variable of type bool)
```

O tipo `bool` tem exatamente dois valores, e o `go doc builtin.bool` diz isso numa frase: "bool is
the set of boolean values, true and false." A lição 6 mostrou que um `bool` declarado sem valor
começa como `false`.

## O lado direito pode nem executar

`&&` e `||` param assim que a resposta é conhecida. Em `a && b`, se `a` é falso o todo é falso e
`b` não é avaliado; em `a || b`, se `a` é verdadeiro, `b` é pulado. Isso se chama **avaliação em
curto-circuito**, e é o que torna possível uma guarda. A lição 7 mostrou que dividir um inteiro por
uma variável igual a zero entra em pânico em tempo de execução; aqui a mesma divisão fica atrás de
uma guarda, e depois na frente dela:

```go
package main

import "fmt"

func main() {
	total, people := 120, 0

	if people > 0 && total/people > 50 {
		fmt.Println("more than 50 each")
	}
	fmt.Println("the guard held")

	if total/people > 50 && people > 0 {
		fmt.Println("more than 50 each")
	}
	fmt.Println("never printed")
}
```

```
ana@vm:~/runes-short$ go run .; echo $?
the guard held
panic: runtime error: integer divide by zero

goroutine 1 [running]:
main.main()
	/home/ana/runes-short/main.go:13 +0x4a
exit status 2
1
```

O primeiro `if` achou `people > 0` falso e nunca dividiu. O segundo dividiu primeiro, na linha 13,
e o programa morreu antes de olhar `people > 0`. As duas condições contêm os mesmos dois testes;
**só a ordem muda, e em Go a ordem faz parte do significado.** Ponha à esquerda o teste barato, ou
o que protege o outro. A lição 36 trata de panics e a lição 37 lê um rastro como este quadro a
quadro; por ora, `exit status 2` é o código de saída do próprio programa, que o `go run` informou
antes de sair com 1.
