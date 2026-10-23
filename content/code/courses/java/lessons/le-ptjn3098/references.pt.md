---
title: A variável guarda uma referência, não o objeto
version: 1
---

A leitura natural de `Book a = new Book();` é que `a` é um livro. **Não é.** `a` guarda uma
**referência**: um valor que leva a um objeto, como um endereço leva a uma casa. O objeto está em
outro lugar. Quase toda surpresa do modelo de objetos do Java vem de esquecer isso, e este programa
produz três delas:

```java
// Refs.java
public class Refs {
    public static void main(String[] args) {
        Book a = new Book();
        a.title = "Dom Casmurro";
        Book b = a;
        b.title = "Memorial de Aires";
        System.out.println(a.title);
        System.out.println(a == b);

        Book c = new Book();
        c.title = "Memorial de Aires";
        System.out.println(a == c);
        System.out.println(a.title.equals(c.title));

        Book none = null;
        System.out.println(none.title);
    }
}
```

Ele usa a classe `Book` da seção 02, que o `javac` encontra no mesmo diretório:

```
ana@vm:~/objects$ javac Refs.java && java Refs
Memorial de Aires
true
false
true
Exception in thread "main" java.lang.NullPointerException: Cannot read field "title" because "<local4>" is null
	at Refs.main(Refs.java:17)
```

## A atribuição copia a referência

`Book b = a;` não copiou o livro. Copiou a referência, então `a` e `b` levam **ao mesmo objeto**, e
definir `b.title` mudou o que `a.title` lê. A primeira linha impressa é o título definido por meio de
`b`. Só houve um `new` antes daquela linha, então só houve um livro.

## `==` pergunta se duas referências levam a um objeto só

`a == b` é `true` porque as duas levam ao mesmo objeto. `a == c` é `false` mesmo com `c` guardando o
mesmo título: `c` veio de um segundo `new`, então é um segundo objeto. **Para referências, `==`
compara identidade, nunca conteúdo.** Para comparar conteúdo você pergunta aos objetos, com um
método; `a.title.equals(c.title)` comparou as duas strings caractere por caractere e disse `true`. A
lição 7 encontrou a mesma regra para strings, e a lição 24 escreve um `equals` para o próprio `Book`.

## `null` é uma referência a nada

`none` guarda `null`, a referência que não leva a lugar nenhum, e `none.title` pede um atributo de um
objeto que não existe. A JVM para com uma `NullPointerException`. **Leia a mensagem até o fim**: ela
nomeia o atributo que tentou ler, `title`, e a variável que era `null`.

Aqui a variável se chama `<local4>`, que não é um nome que alguém escreveu. Por padrão o `javac` não
guarda nomes de variáveis locais no arquivo de classe, então a JVM só consegue numerá-las: `args` é 0,
`a` é 1, `b` é 2, `c` é 3 e `none` é 4. Compile com `-g` e os nomes são mantidos:

```
ana@vm:~/objects$ javac -g Refs.java && java Refs
Memorial de Aires
true
false
true
Exception in thread "main" java.lang.NullPointerException: Cannot read field "title" because "none" is null
	at Refs.main(Refs.java:17)
```

O Maven compila com essa informação por padrão, a partir da lição 18, então as mensagens que você
encontra no trabalho nomeiam a variável. A última linha, `Refs.java:17`, é a linha do código-fonte
que falhou nas duas execuções. A lição 36 lê stack traces com calma.
