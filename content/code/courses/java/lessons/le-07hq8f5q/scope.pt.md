---
title: Escopo, ou onde um nome pode ser usado
version: 1
---

O **escopo** de uma variável é a parte do programa em que o nome dela significa alguma coisa. Para
uma variável local a regra é curta: **ela está no escopo da declaração até a chave que fecha o bloco
que a contém.** Não o método, o bloco, e as chaves de um `if` ou de um laço formam um bloco. A regra é
o que deixa dois métodos usarem o mesmo nome para duas coisas diferentes sem problema nenhum.

## Um nome declarado dentro de um bloco termina com ele

```java
// Blocks.java
public class Blocks {
    public static void main(String[] args) {
        int copies = 4;
        if (copies > 3) {
            int extra = copies - 3;
            System.out.println("extra copies: " + extra);
        }
        System.out.println(extra);
    }
}
```

```
ana@vm:~/scope$ javac Blocks.java
Blocks.java:9: error: cannot find symbol
        System.out.println(extra);
                           ^
  symbol:   variable extra
  location: class Blocks
1 error
```

`extra` foi declarada dentro das chaves do `if`, então o escopo dela terminou no `}` da linha 8. Na
linha 9 o nome não significa nada, e o `javac` diz `cannot find symbol`: procurou qualquer coisa
chamada `extra` visível daquela linha e não achou. A correção é declarar `extra` antes do `if`, se ela
for necessária depois dele, e deixá-la dentro, se não for, que é o caso aqui. **Uma variável declarada
no menor bloco que precisa dela não pode ser mal usada fora desse bloco.**

## Duas locais com um nome, num método

Algumas linguagens deixam um bloco interno declarar uma variável com o mesmo nome de uma de fora,
escondendo a de fora até o bloco terminar. **O Java recusa**, para variáveis locais:

```java
// Twice.java
public class Twice {
    public static void main(String[] args) {
        int total = 10;
        for (int i = 0; i < 2; i++) {
            int total = i;
            System.out.println(total);
        }
    }
}
```

```
ana@vm:~/scope$ javac Twice.java
Twice.java:6: error: variable total is already defined in method main(String[])
            int total = i;
                ^
1 error
```

O corpo do laço é um bloco dentro do `main`, e o `main` já tem um `total` no escopo ali. Declarar um
segundo deixaria cada `total` seguinte no laço ambíguo para quem lê, então o compilador impede. O laço
`for` é assunto da lição 11; aqui só as chaves dele importam.

## Uma local pode esconder um campo

A regra acima é sobre duas locais. Uma local **pode** ter o mesmo nome de um campo, e da declaração em
diante o nome sozinho quer dizer a local:

```java
// Shadow.java
public class Shadow {
    static String name = "the library";

    public static void main(String[] args) {
        System.out.println(name);
        String name = "Ana";
        System.out.println(name);
        System.out.println(Shadow.name);
    }
}
```

```
ana@vm:~/scope$ java Shadow.java
the library
Ana
the library
```

O primeiro `println` rodou antes de a local `name` existir, então `name` queria dizer o campo,
`"the library"`. Da linha 7 em diante, `name` quer dizer a local, `"Ana"`. O campo continuava lá, sem
mudança, e `Shadow.name` o alcançou nomeando a classe. Isso se chama **sombreamento** (shadowing). É
permitido e é uma fonte comum de confusão, com um lugar onde é o estilo normal: um construtor cujos
parâmetros têm os mesmos nomes dos campos que preenchem, que a lição 13 escreve com
`this.name = name`.
