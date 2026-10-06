---
title: O que Go deixa de fora
version: 1
---

Uma linguagem costuma ser julgada pelo que tem, e quem chega a Go vai procurar os recursos que já
conhece: classes, herança, exceções, um laço `while`. **Go se define tanto pelo que deixa de fora
quanto pelo que tem, e deixou essas coisas de fora de propósito.** Cada recurso ausente é algo que
os projetistas tinham visto custar tempo em programas grandes, e o tempo de que falavam era o de
quem lê: a próxima pessoa a abrir o arquivo.

## Vinte e cinco palavras

O jeito mais rápido de ver o tamanho de uma linguagem é contar as palavras-chave, as palavras que
você não pode usar como nome porque a gramática é dona delas. A biblioteca padrão inclui o próprio
parser de Go, em `go/token`, então um programa pode perguntar a ele:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command keywords lists the keywords of Go, as the standard library's parser knows them.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"go/token\"\n\t\"strings\"\n)\n",
      "note": "**`go/token` é o pacote que nomeia cada token que o parser de Go conhece**: operadores, pontuação, literais e palavras-chave. O comando go, o `gofmt` e o `go vet` leem Go com esses mesmos pacotes."
    },
    {
      "code": "\nfunc main() {\n\tvar words []string\n\tfor tok := token.ILLEGAL; tok <= token.TILDE; tok++ {\n",
      "note": "Cada token é um número, de `ILLEGAL` até `TILDE`, o último que o pacote exporta. O laço percorre todos; `var words []string` é uma lista vazia para ir juntando, e a lição 11 é onde listas assim são explicadas."
    },
    {
      "code": "\t\tif tok.IsKeyword() {\n\t\t\twords = append(words, tok.String())\n\t\t}\n\t}\n",
      "note": "**Quem decide o que é palavra-chave é o parser, não este programa.** `IsKeyword` responde para cada token, e `String` dá a grafia dele."
    },
    {
      "code": "\tfmt.Println(strings.Join(words, \" \"))\n\tfmt.Println(len(words), \"keywords\")\n}\n",
      "note": "Uma linha com as palavras, uma com a contagem."
    }
  ],
  "output": "break case chan const continue default defer else fallthrough for func go goto if import interface map package range return select struct switch type var\n25 keywords\n"
}
```

Vinte e cinco. A palestra de 2012 da seção 02 deu a comparação: C99 tinha 37 e C++11 tinha 84. Leia
a lista procurando o que falta, porque **nenhum `class`, `extends`, `try`, `catch`, `throw` ou
`while` aparece nela.** Essas palavras não são reservadas em Go; você poderia chamar uma variável de
`class`. E sem `while`, o único laço é o `for`, nas três formas que a lição 17 mostra.

## Sem classes e sem herança

Go tem tipos e métodos sobre eles, mas nenhuma classe que junte as duas coisas e nenhuma hierarquia
em que um tipo herda de outro. Um tipo é montado pondo outros tipos dentro dele, o que se chama
composição. Structs são a lição 15, pôr uma dentro da outra é a lição 16, e métodos são a lição 25.
O que fica agora é o lado negativo: **não existe `extends` nem árvore de tipos para guardar na
cabeça**, então um método que você lê está definido no tipo à sua frente ou num tipo visivelmente
embutido nele.

## Sem exceções

Uma função Go que pode falhar devolve um erro como valor comum, ao lado do resultado, e quem chamou
olha para ele na linha seguinte. Não há `try` em volta de um bloco nem caminho escondido pelo qual
uma falha salta do meio de uma função. O `net.LookupHost` da seção 03 devolveu `[127.0.0.1]` e
`<nil>`, e esse `<nil>` era o erro, impresso como valor porque nada deu errado. As lições 32 a 35
tratam de erros; a lição 36 trata de `panic`, que é para bugs e não para falhas.

## Nenhuma conversão que você não escreveu

A maioria das linguagens transforma um inteiro em número de ponto flutuante quando os dois se
encontram numa expressão. Go recusa:

```go
package main

import "fmt"

func main() {
	items := 3
	price := 2.5
	fmt.Println(items * price)
}
```

```
ana@vm:~/why-mix$ go build; echo $?
# example.com/mix
./main.go:8:14: invalid operation: items * price (mismatched types int and float64)
1
```

`items` é um `int` e `price` um `float64`, e **o compilador não escolhe um tipo por você**. Você
escreve a conversão, `float64(items) * price`, e aí o arredondamento e o estouro viram uma decisão
que alguém tomou onde quem lê consegue ver. A lição 10 trata de conversões.

O import sem uso da lição 4 também entra nesta lista. Um erro de compilação onde outras linguagens
dão um aviso é a mesma ideia: uma escolha que custa caro para o próximo leitor fica impossível, em
vez de só desencorajada.

## O que se escreve com ela

Uma linguagem pequena pode ser pequena porque ninguém a usa. Go não é esse caso. Alguns dos
programas mais conhecidos que rodam servidores e clusters são escritos nela, e o proxy de módulos que
serviu o Go do laboratório os conhece pelos caminhos de módulo:

```
ana@vm:~/why$ go list -m k8s.io/kubernetes@latest github.com/hashicorp/terraform@latest
k8s.io/kubernetes v1.37.1
github.com/hashicorp/terraform v1.16.5
ana@vm:~/why$ go list -m github.com/prometheus/prometheus@latest github.com/docker/docker@latest
github.com/prometheus/prometheus v0.315.0
github.com/docker/docker v28.5.2+incompatible
```

Kubernetes, Terraform, Prometheus e Docker são publicados cada um como um módulo Go, e o
`go list -m` imprimiu a versão mais recente de cada um no dia em que o laboratório rodou. A lição 38
explica o que são um caminho de módulo e uma versão como essas; por ora elas são a evidência de que
quatro programas que você talvez já use são Go.

::: track devops devsecops
Nesta trilha você vai operar esses programas antes de escrever algo parecido com eles. Quando um deles
se comportar mal, o código-fonte que você acabará lendo está escrito na linguagem que este curso
ensina, e o binário que você acabará copiando entre máquinas é o arquivo único da seção 03.
:::

::: track backend
Nesta trilha Go é a linguagem dos serviços que você vai escrever: programas que passam o dia
respondendo a requisições pela rede, que é o terceiro problema da seção 02. O arquivo único da seção
02 é o que você vai entregar a quem faz o deploy deles.
:::

::: track *
Seja o que for que você construa com ela, a troca é a mesma: uma linguagem pequena que se lê
depressa, um compilador que roda depressa e um arquivo só no fim.
:::
