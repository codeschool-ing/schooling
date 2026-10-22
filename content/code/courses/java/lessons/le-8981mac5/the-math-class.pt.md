---
title: A classe `Math`, e arredondar de propósito
version: 1
---

Tudo o que é matemático e não é operador mora numa classe, `java.lang.Math`: valores absolutos,
potências, raízes, arredondamento, trigonometria. **É uma classe da qual você nunca cria um objeto.**
Os métodos dela são `static`, chamados pelo nome da classe, `Math.sqrt(2)`, e a lição 15 explica o
que essa palavra quer dizer. Por estar em `java.lang`, ela não precisa de `import`.

O programa abaixo chama os que um programa de negócio de fato usa, e a maioria das linhas guarda uma
resposta que uma calculadora não teria dado:

```schooling-example
{
  "language": "java",
  "file": "MathClass.java",
  "parts": [
    {
      "code": "import java.util.Random;\n\npublic class MathClass {\n    public static void main(String[] args) {\n        System.out.println(Math.abs(-42));\n        System.out.println(Math.abs(Integer.MIN_VALUE));",
      "note": "**O `Math.abs` do menor `int` continua negativo.** O gêmeo positivo dele, 2.147.483.648, é um a mais do que um `int` consegue guardar, então a resposta dá a volta até onde começou: `-2147483648`. O `Math.absExact` lança uma exceção em vez disso."
    },
    {
      "code": "        System.out.println(Math.max(3, 9) + \" \" + Math.min(3, 9));\n        System.out.println(Math.pow(2, 10));\n        System.out.println(Math.sqrt(2));",
      "note": "O `max` e o `min` mantêm o tipo que receberam. **O `pow` e o `sqrt` sempre devolvem um `double`**, e é por isso que 2 elevado a 10 saiu como `1024.0`."
    },
    {
      "code": "        System.out.println(Math.round(2.5) + \" \" + Math.round(-2.5) + \" \" + Math.round(2.4));\n        System.out.println(Math.floor(-2.5) + \" \" + Math.ceil(-2.5));\n        System.out.println((int) 2.5 + \" \" + (int) -2.5);",
      "note": "O `round` leva uma metade **para cima, na direção do infinito positivo**: 2.5 virou 3 e -2.5 virou -2. O `floor` vai para baixo e o `ceil` para cima, e os dois devolvem um `double`: `-3.0` e `-2.0`. Um cast para `int` corta em direção ao zero: `2` e `-2`."
    },
    {
      "code": "        System.out.println(-7 / 2 + \" \" + Math.floorDiv(-7, 2));\n        System.out.println(-7 % 2 + \" \" + Math.floorMod(-7, 2));",
      "note": "O `/` cortou o -3,5 em direção ao zero e deu `-3`; **o `floorDiv` arredonda para baixo e dá `-4`**. Os restos acompanham: o `%` deu `-1` e o `floorMod` deu `1`, que nunca é negativo para um divisor positivo."
    },
    {
      "code": "\n        Random dice = new Random(42);\n        for (int roll = 0; roll < 5; roll++) {\n            System.out.print(\" \" + dice.nextInt(1, 7));\n        }\n        System.out.println();\n    }\n}",
      "note": "Cinco dados. O `nextInt(1, 7)` dá um inteiro de 1 até 7, sem incluir o 7. **A semente, 42, fixa a sequência**: este programa imprime as mesmas cinco jogadas em toda execução, que é o que um teste precisa. `new Random()` sem semente começa num ponto diferente a cada vez."
    }
  ],
  "output": "42\n-2147483648\n9 3\n1024.0\n1.4142135623730951\n3 -2 2\n-3.0 -2.0\n2 -2\n-3 -4\n-1 1\n 3 4 1 3 1\n"
}
```

## Três jeitos de arredondar, e eles discordam nos negativos

Arredondar é onde a `Math` mais dá uma resposta que o programador não esperava, porque "arredondar"
são várias operações que concordam nos positivos e se separam abaixo de zero:

| método | 2.5 | -2.5 | devolve |
|---|---|---|---|
| `Math.round` | 3 | -2 | `long` |
| `Math.floor` | 2.0 | -3.0 | `double` |
| `Math.ceil` | 3.0 | -2.0 | `double` |
| um cast, `(int)` | 2 | -2 | `int` |

**`Math.round(-2.5)` dá `-2`, não `-3`**: ele soma meio e depois arredonda para baixo, então uma
metade vai sempre na direção do infinito positivo. O cast da última linha é o estreitamento da lição
6, que corta em direção ao zero. Nenhum deles é o arredondamento que um contador chama de "metade
para cima" em valores negativos, e a seção 05 mostra a classe que deixa você dizer qual regra quer.

## `floorDiv` e `floorMod`

A seção 02 mostrou que o `/` corta em direção ao zero e que o `%` leva o sinal do operando da
esquerda. Esse é o comportamento errado para tudo o que dá a volta: que dia da semana é 10 dias
**antes** de uma quarta-feira, que posição de um anel de 7 é o índice `-3`. **`Math.floorMod(n, 7)`
cai sempre entre 0 e 6** para qualquer `n`, enquanto `n % 7` pode cair entre -6 e 6. O `floorDiv` é o
parceiro dele, e os dois sempre concordam: `floorDiv(-7, 2) * 2 + floorMod(-7, 2)` devolve o `-7`,
assim como `-7 / 2 * 2 + -7 % 2`.

## Números aleatórios

O `Math.random()` existe e devolve um `double` de 0 até 1. **O `java.util.Random` é a ferramenta
melhor**, porque dá números inteiros numa faixa diretamente, `nextInt(1, 7)` para um dado, e porque
aceita uma semente. Um `Random` com semente é uma receita: a mesma semente produz sempre a mesma
sequência, e é por isso que a saída acima vai ler `3 4 1 3 1` na sua máquina também. Um programa que
não pode ser previsível, uma senha ou um token, usa o `java.security.SecureRandom`, e nunca uma
semente.
