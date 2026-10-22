---
title: Nomes, e as convenções que todo arquivo Java compartilha
version: 1
---

O compilador aceita quase qualquer nome feito de letras, dígitos, `_` e `$`, desde que não comece com
dígito e não seja uma das palavras reservadas da linguagem, como `class` ou `int`. **O que ele não
impõe, a comunidade impõe**: código Java no mundo inteiro dá nome às coisas do mesmo jeito, e um nome
escrito de outro jeito parece um erro para cada colega que abre o arquivo. As convenções são poucas, e
cada uma diz ao leitor que tipo de coisa um nome é antes de ele ler a declaração.

| tipo de nome | convenção | exemplos deste curso |
|---|---|---|
| classe, interface, enum, record | **PascalCase**: toda palavra com inicial maiúscula | `Hello`, `LoanDesk`, `StringBuilder` |
| método, variável, parâmetro | **camelCase**: primeira palavra minúscula | `main`, `printReceipt`, `loansToday` |
| constante (`static final`) | **UPPER_SNAKE_CASE** | `MAX_LOANS`, `Integer.MAX_VALUE` |
| pacote | tudo minúsculo, palavras coladas, domínio invertido | `java.util`, `com.example.library` |

Um programa curto que segue todas elas, em `~/syntax`:

```java
// LoanDesk.java
public class LoanDesk {
    static final int MAX_LOANS = 3;

    public static void main(String[] args) {
        int loansToday = 2;
        String memberName = "Ana";
        printReceipt(memberName, loansToday);
    }

    static void printReceipt(String memberName, int loanCount) {
        System.out.println(memberName + " has " + loanCount + " of " + MAX_LOANS + " loans");
    }
}
```

```
ana@vm:~/syntax$ java LoanDesk.java
Ana has 2 of 3 loans
```

Leia só os nomes e a forma do programa já está ali. `LoanDesk` é uma classe porque começa com
maiúscula. `MAX_LOANS` é uma constante, um valor fixo pela vida inteira do programa, que a lição 16
explica pelo `final`. `printReceipt` é um método, e um verbo, porque faz alguma coisa. `memberName` e
`loanCount` são variáveis, substantivos, guardando um valor cada. **Métodos levam o nome do que fazem,
e variáveis o nome do que guardam**: `printReceipt`, não `receipt`; `loanCount`, não `count2`.

## A única regra de nomes que o compilador impõe

**Uma classe pública precisa estar num arquivo exatamente com o nome dela**, mais `.java`. Isso não é
estilo, e o compilador diz isso. Copie o `Hello.java` com outro nome e compile a cópia:

```
ana@vm:~/syntax$ cp Hello.java Greeting.java && javac Greeting.java
Greeting.java:1: error: class Hello is public, should be declared in a file named Hello.java
public class Hello {
       ^
1 error
ana@vm:~/syntax$ rm Greeting.java
```

A classe lá dentro continua sendo `Hello`, então `Greeting.java` é a casa errada para ela. A regra
existe para que o compilador e a JVM encontrem uma classe pública só pelo nome, sem ler todos os
arquivos de um diretório. A execução com vários arquivos da lição 2 dependia dela: `java Main.java`
encontrou o `Shout.java` porque a classe `Shout` só podia estar naquele arquivo. Um arquivo pode ter
outras classes que não são públicas, e a lição 14 volta ao que isso significa.

## Espaços, chaves e tamanho de linha

As regras de layout também são convenções, e as usadas neste curso são as comuns:

- quatro espaços de indentação por nível, nunca tabulações misturadas com espaços;
- a chave de abertura no fim da linha que começa o bloco, a de fechamento sozinha na própria linha,
  alinhada com o começo daquela linha;
- uma instrução por linha, e linhas curtas o bastante para ler sem rolar para o lado.

As equipes escrevem as suas regras, e a maioria das ferramentas de build sabe conferi-las. O que
importa é que **todo arquivo de um projeto tenha a mesma cara**, para que uma diferença de layout
sempre signifique uma diferença de código.
