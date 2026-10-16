---
title: Uma string nunca muda
version: 1
---

Quase todo mundo conhece a `String` com a imagem de uma caixa de caracteres que os métodos editam no
lugar: chame `toUpperCase` e a caixa passa a guardar maiúsculas. **Nenhum método de `String` muda a
string em que é chamado.** Todos os que parecem mudar devolvem uma `String` nova, e a antiga fica
exatamente como estava. Um programa que esquece de guardar o resultado joga a mudança fora. Crie um
diretório para esta lição, `~/strings`, e salve isto como `Immutable.java`:

```java
// Immutable.java
public class Immutable {
    public static void main(String[] args) {
        String name = "ana";
        name.toUpperCase();
        System.out.println(name);

        String upper = name.toUpperCase();
        System.out.println(upper);
        System.out.println(name);
    }
}
```

```
ana@vm:~/strings$ java Immutable.java
ana
ANA
ana
```

O primeiro `toUpperCase()` construiu `"ANA"`, devolveu, e ninguém pegou, então a primeira linha
imprimiu `ana`. A segunda chamada guardou o resultado em `upper`. **A última linha imprimiu `ana` de
novo**: `name` continua apontando para a string que recebeu, porque essa string não pode mudar. A
lição 2 mostrou o `java Immutable.java`, o lançador de código-fonte, e esta lição o usa em todos os
programas, já que cada um é um arquivo só, executado uma vez.

A imutabilidade é o que deixa o Java compartilhar strings à vontade. Uma `String` entregue a um
método, guardada em duas listas ou usada como chave num mapa não pode ser alterada pelas costas de
ninguém. A lição 26 volta ao custo de esquecer um resultado, `s.toUpperCase();` sozinho numa linha,
que compila e não faz nada.

## `==` é a pergunta errada

Como strings são objetos, uma variável guarda uma **referência** para uma, e `==` compara
referências. A lição 12 explica referências direito; aqui basta ver o que os dois operadores
respondem:

```schooling-example
{
  "language": "java",
  "file": "Equality.java",
  "parts": [
    {
      "code": "public class Equality {\n    public static void main(String[] args) {\n        String a = \"java\";\n        String b = \"java\";",
      "note": "**Dois literais com o mesmo texto são um objeto só.** O compilador escreve `\"java\"` uma vez no arquivo de classe, e a JVM mantém uma `String` só para ele, então `a` e `b` guardam a mesma referência."
    },
    {
      "code": "        String c = new StringBuilder(\"jav\").append('a').toString();",
      "note": "**Construída enquanto o programa roda, então é um objeto novo.** Os mesmos quatro caracteres, em outro lugar da memória. Toda string lida de um arquivo, de um teclado ou da rede chega assim."
    },
    {
      "code": "\n        System.out.println(a == b);\n        System.out.println(a == c);",
      "note": "`==` entre objetos pergunta **é o mesmo objeto?** Para `a` e `b`, é. Para `a` e `c`, não é, digam o que disserem os caracteres."
    },
    {
      "code": "        System.out.println(a.equals(c));",
      "note": "`equals` pergunta **guardam os mesmos caracteres?**, que é quase sempre a pergunta que você quis fazer."
    },
    {
      "code": "        System.out.println(a == c.intern());\n    }\n}",
      "note": "`intern()` devolve a cópia única que a JVM compartilha daquele texto. Explica a primeira linha, e raramente você vai chamá-lo."
    }
  ],
  "output": "true\nfalse\ntrue\ntrue\n"
}
```

A segunda linha é o bug clássico. Ela compara uma string que o programa construiu com um literal e
responde `false`, e num teste rápido com dois literais teria respondido `true`. **Compare strings com
`equals`, sempre**, e deixe o `==` para a pergunta de identidade, que strings quase nunca precisam
responder.

## Blocos de texto

Uma string com várias linhas, ou com aspas dentro, é desajeitada de escrever como literal. Desde o
Java 15 um **bloco de texto** (text block) abre com três aspas duplas e uma quebra de linha, e fecha
com mais três:

```java
// Receipt.java
public class Receipt {
    public static void main(String[] args) {
        String receipt = """
            Loan receipt
              Book:   "Dom Casmurro"
              Due:    2026-11-06
            """;
        System.out.print(receipt);
        System.out.println(receipt.lines().count() + " lines");
    }
}
```

```
ana@vm:~/strings$ java Receipt.java
Loan receipt
  Book:   "Dom Casmurro"
  Due:    2026-11-06
3 lines
```

As aspas em volta do título não precisaram de barra invertida. A indentação dentro do programa
sumiu, e a regra é mecânica: **o compilador remove tantos espaços iniciais quantos tem a linha menos
indentada**, contando o `"""` de fechamento. Aqui essa linha e `Loan receipt` estavam na mesma
profundidade, então o recibo ficou só com os dois espaços a mais das linhas indentadas. O bloco
também termina com uma quebra de linha, porque as aspas de fechamento estão numa linha só delas, e
por isso ele é impresso com `print` e não com `println`.
