---
title: var, em todas as suas formas
version: 1
---

Go tem tipagem estática, e quem vem de Python ou JavaScript costuma entender que isso quer dizer
escrever o tipo de toda variável. Não quer. **Tipagem estática quer dizer que toda variável tem
exatamente um tipo, fixado quando o programa é compilado e nunca mais mudado.** Se você escreve
esse tipo ou deixa o compilador deduzi-lo do valor é escolha sua, e o `var` permite as duas coisas.

Aqui está cada forma que o `var` assume, num programa em `~/vars`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n"
    },
    {
      "code": "\nvar greeting = \"Hello\"\n",
      "note": "**Uma variável declarada fora de qualquer função pertence ao pacote**, e toda função do pacote pode usá-la. `var`, um nome e um valor: o tipo ficou de fora, então o compilador o tira de `\"Hello\"`, que é uma string."
    },
    {
      "code": "\nvar (\n\thost    string = \"localhost\"\n\tport    int    = 8080\n\tverbose bool\n)\n",
      "note": "Várias declarações podem dividir um `var` e um par de parênteses. Isso não muda nada nelas; diz que andam juntas, como as configurações de um programa. As colunas são obra do `gofmt`."
    },
    {
      "code": "\nfunc main() {\n\tvar count int\n",
      "note": "Um tipo e nenhum valor. **A variável tem valor mesmo assim: ela começa no zero do seu tipo**, `0` para um `int`, como mostra a segunda linha da saída. Qual é o zero de cada tipo é assunto da lição 6."
    },
    {
      "code": "\tvar name string = \"Ana\"\n",
      "note": "Tipo e valor juntos. Aqui o tipo não diz nada que o valor já não dissesse, então a maior parte do código Go o deixaria de fora."
    },
    {
      "code": "\tvar ratio = 0.5\n",
      "note": "Valor e nenhum tipo. Um número com ponto decimal dá `float64`, o que o `%T` confirma mais abaixo."
    },
    {
      "code": "\tvar x, y int = 1, 2\n\tvar a, b = 3, \"four\"\n",
      "note": "Vários nomes numa linha, recebendo valores na mesma ordem. Com um tipo, todos o compartilham; sem tipo, cada nome fica com o tipo do seu próprio valor, então `a` e `b` acabam diferentes."
    },
    {
      "code": "\n\tfmt.Println(greeting, host, port, verbose)\n\tfmt.Println(count, name, ratio, x, y, a, b)\n\tfmt.Printf(\"%T %T %T %T\\n\", count, ratio, a, b)\n}\n",
      "note": "`%T` num formato de `Printf` imprime o **tipo** do argumento em vez do valor, que é o jeito mais rápido de perguntar ao compilador o que ele decidiu."
    }
  ],
  "output": "Hello localhost 8080 false\n0 Ana 0.5 1 2 3 four\nint float64 int string\n"
}
```

A execução mostra o que cada forma produziu:

```
ana@vm:~/vars$ go run .
Hello localhost 8080 false
0 Ana 0.5 1 2 3 four
int float64 int string
```

Então uma declaração tem três espaços, o nome, o tipo e o valor, e **só o nome é obrigatório,
desde que um dos outros dois esteja lá**. Deixe o tipo de fora e o valor decide: `0.5` fez de
`ratio` um `float64`, e `3` fez de `a` um `int`. Deixe o valor de fora e a variável começa no zero
do seu tipo: `count` imprimiu `0` e `verbose` imprimiu `false`, embora ninguém tenha dado nada a
elas.

Seja qual for a forma escolhida, o tipo agora é permanente. `ratio` é um `float64` pelo resto do
programa, e colocar nela um valor de outro tipo é um erro de compilação que a lição 10 mostra por
inteiro.

## Onde o var é a forma certa

A seção 02 apresenta uma forma mais curta, e a maioria das variáveis dentro de uma função a usa. O
`var` fica com três tarefas que a forma curta não faz:

1. **No nível do pacote, é a única forma.** `greeting`, `host`, `port` e `verbose` moram fora de
   `main`, e a seção 02 mostra o compilador recusando a forma curta ali.
2. **Quando o valor zero é o valor inicial que você quer**, `var count int` diz isso com todas as
   letras. Um total acumulado que começa do nada se lê melhor assim do que como `count := 0`.
3. **Quando o tipo de que você precisa não é o que o valor daria.** `var ratio float64 = 1` é um
   `float64` guardando 1; sem o tipo, `1` faria dele um `int`, como mostra a execução da seção 02.

O grupo entre parênteses é questão de leitura, não de significado. Um bloco de configurações
relacionadas no nível do pacote, como as três acima, se lê como uma coisa só; três linhas `var`
separadas se leem como três.
