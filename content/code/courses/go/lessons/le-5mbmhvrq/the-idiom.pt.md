---
title: if err != nil, e o que vai dentro
version: 1
---

**Uma chamada que pode falhar é seguida, na linha de baixo, por `if err != nil`**, e o bloco
embaixo dele sai: devolve, ou em `main` encerra o programa. A lição 19 escreveu esse formato uma
vez em `double` e o chamou da coisa mais comum de se ver em código Go. O código-fonte da própria
biblioteca padrão confirma, contado sem os testes:

```
ana@vm:~/errors-idiom$ grep -rE --include=*.go 'if err != nil' /usr/local/go/src | grep -vc -e _test.go -e testdata
8879
```

Quase nove mil linhas do código que vem com o Go são esse único teste.

## O preço do ingresso, com um erro no lugar do -1

A lição 19 calculava o preço de um ingresso e respondia a uma idade negativa com `-1`, um
substituto que só funciona enquanto todo mundo que chama lembra que `-1` não é preço. Aqui está a
mesma regra com um `error`, e um `main` que lê a idade da linha de comando, em `~/errors-idiom`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command price prints the price of a ticket for the age it is given.\npackage main\n\nimport (\n\t\"errors\"\n\t\"fmt\"\n\t\"os\"\n\t\"strconv\"\n)\n\nfunc price(age int, member bool) (int, error) {\n\tif age < 0 {\n\t\treturn 0, errors.New(\"age cannot be negative\")\n\t}\n",
      "note": "**A idade inválida agora devolve um erro, e o preço ao lado dele é 0.** O `errors.New` cria um `error` a partir de uma frase; a lição 33 trata dele e do `fmt.Errorf`. O 0 não é um preço: quem chama e vê um erro diferente de nil não o lê."
    },
    {
      "code": "\tif age < 12 {\n\t\treturn 0, nil\n\t}\n\tif member {\n\t\treturn 15, nil\n\t}\n\treturn 20, nil\n}\n",
      "note": "**Todo caminho que dá certo devolve `nil` como erro.** Aqui o 0 é um preço de verdade, o de uma criança, e nada o confunde com uma falha, porque a falha vem no outro resultado."
    },
    {
      "code": "\nfunc main() {\n\tage, err := strconv.Atoi(os.Args[1])\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, err)\n\t\tos.Exit(1)\n\t}\n",
      "note": "**O idioma: chamar, testar `err` na linha seguinte, sair dentro do bloco.** `os.Args[1]` é a primeira palavra depois do nome do programa. Em `main` não há quem chamou para quem devolver, então sair é escrever a mensagem na saída de erro e terminar com status 1."
    },
    {
      "code": "\tp, err := price(age, false)\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, err)\n\t\tos.Exit(1)\n\t}\n\tfmt.Println(p)\n}\n",
      "note": "A segunda chamada reaproveita `err`: `p` é novo, então o `:=` é permitido e `err` só recebe um valor, a regra que a lição 5 disse que valeria a pena aqui. **O caminho de sucesso desce pela margem esquerda, com cada falha tratada e deixada para trás acima dele**, como a lição 19 recomendou."
    }
  ]
}
```

Compilado uma vez e executado com quatro idades:

```
ana@vm:~/errors-idiom$ go build -o price .
ana@vm:~/errors-idiom$ ./price 30; echo $?
20
0
ana@vm:~/errors-idiom$ ./price 8; echo $?
0
0
ana@vm:~/errors-idiom$ ./price -4; echo $?
age cannot be negative
1
ana@vm:~/errors-idiom$ ./price thirty; echo $?
strconv.Atoi: parsing "thirty": invalid syntax
1
ana@vm:~/errors-idiom$ ./price -4 2>/dev/null; echo $?
1
```

Cada execução parou num lugar diferente. `thirty` nunca chegou a `price`: o `Atoi` falhou e o
primeiro bloco encerrou o programa. `-4` passou pelo `Atoi` e foi recusado por `price`. A última
linha joga fora a saída de erro, e a mensagem vai junto. O status de saída continua 1: **a
mensagem era para uma pessoa e o status é para um script**, então um shell ou um job de CI que
roda `price` sabe que ele falhou sem ler inglês.

O ingresso de criança imprimiu 0 com status 0. É esse o caso que um número substituto não resolve.
Uma função em que todo valor é uma resposta válida não tem número sobrando para dizer "falhou", e
uma função de preço vira uma dessas no momento em que um ingresso pode ser de graça.

## O que vai dentro do bloco

Há três coisas a fazer com um erro, e o bloco guarda uma delas.

1. **Devolvê-lo** para quem chamou você, como `double` fez na lição 19. É a resposta de costume
   dentro de uma função que não é `main`, porque a função que chamou você sabe mais do que você
   sobre o que a falha significa para o programa. A lição 33 acrescenta contexto a ele no caminho.
2. **Tratá-lo** ali mesmo, quando existe uma resposta de verdade para a falha: um valor padrão, uma
   segunda tentativa, um arquivo alternativo. Aí o programa segue, e isso é uma decisão que você
   tomou.
3. **Relatar e parar**, que é o que o `main` acima faz. Não sobrou ninguém para quem devolver.

O que o bloco não pode fazer é nada. O próximo programa é o mesmo, com os dois erros jogados fora
com `_`, o identificador vazio da lição 20, em `~/errors-ignore`:

```go
func main() {
	age, _ := strconv.Atoi(os.Args[1])
	p, _ := price(age, false)
	fmt.Println(p)
}
```

```
ana@vm:~/errors-ignore$ go run . thirty
0
ana@vm:~/errors-ignore$ go run . -4
0
```

Alguém com `thirty` anos ganhou um ingresso de graça. O `Atoi` falhou e devolveu 0, o `_`
descartou o motivo, e o 0 entrou em `price` como a idade de uma criança pequena. A segunda
execução terminou igual por outro caminho: `price` recusou `-4`, devolveu 0 ao lado do erro, e o
programa imprimiu o 0. **Um erro descartado não para o programa; ele transforma uma falha numa
resposta errada**, impressa com status de saída 0, o que é pior do que parar.

## Sem exceções, e o que isso compra

O preço desse estilo está à vista: três linhas para cada chamada que pode falhar, escritas à mão,
quase nove mil vezes na biblioteca padrão. O que ele compra é que **todo lugar em que uma função
pode parar está escrito na função**. Lendo o `main` acima, você aponta as duas linhas em que ele
pode terminar e diz por quê. Numa linguagem com exceções qualquer chamada do bloco pode sair dele,
e o lugar onde ela cai fica em outra função, às vezes em outro arquivo.

Go tem `panic`, que desenrola as chamadas, e a lição 36 trata dele. Ele é para bugs, um map nil
recebendo escrita ou um índice depois do fim, e não para um arquivo que não existe ou um número que
alguém digitou errado. Esses são resultados comuns de um programa comum, e em Go eles voltam como
valores.
