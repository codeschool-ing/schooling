---
title: Atributos, e o valor com que começam
version: 1
---

Um **atributo** (field) é uma variável que pertence a um objeto. A lição 12 declarou três em `Book`
e os definiu a partir do `main`, uma atribuição de cada vez. Duas coisas sobre atributos ficaram por
dizer ali, e as duas os separam das variáveis locais da lição 5: **um atributo sempre começa com um
valor**, e **cada objeto tem a sua própria cópia**.

Crie um diretório para as seções 02 e 03, `~/members`, e salve um sócio da biblioteca com atributos
de cinco tipos diferentes:

```java
// Member.java
class Member {
    String name;
    int loans;
    double fines;
    boolean blocked;
    char tier;
    int maxLoans = 3;
}
```

Os cinco primeiros atributos são declarados e nada mais. O sexto, `maxLoans`, traz um
**inicializador**, `= 3`, que roda para cada sócio novo. Um programa que cria dois sócios e imprime o
que encontra:

```java
// Defaults.java
public class Defaults {
    public static void main(String[] args) {
        Member m = new Member();
        System.out.println(m.name);
        System.out.println(m.loans);
        System.out.println(m.fines);
        System.out.println(m.blocked);
        System.out.println((int) m.tier);
        System.out.println(m.maxLoans);

        Member other = new Member();
        other.maxLoans = 5;
        System.out.println(m.maxLoans + " " + other.maxLoans);
    }
}
```

```
ana@vm:~/members$ javac Defaults.java && java Defaults
null
0
0.0
false
0
3
3 5
```

**Todo tipo tem o seu padrão, e ele é o zero daquele tipo**:

| tipo do atributo | padrão | impresso como |
|---|---|---|
| qualquer referência, como `String` | `null` | `null` |
| `int`, `long`, `short`, `byte` | zero | `0` |
| `double`, `float` | zero | `0.0` |
| `boolean` | `false` | `false` |
| `char` | o caractere de código 0 | nada visível, então o programa imprimiu o código |

O `(int)` antes de `m.tier` é um cast, da lição 6. Impresso como caractere, o código 0 é invisível, e
a linha pareceria vazia. Como número ele mostra o que realmente está ali.

**Um inicializador vence o padrão, e uma atribuição vence o inicializador.** `maxLoans` começou em 3
para os dois sócios, porque o inicializador rodou para cada um. Depois `other.maxLoans = 5` mudou um
deles, e a última linha mostra que `m` manteve o seu 3. Os dois sócios compartilham a classe e mais
nada.

## Por que atributos ganham um padrão e locais não

Uma variável local vive dentro de um método, e o compilador consegue ler o método inteiro para
conferir que todo caminho a atribui antes de ela ser lida; a lição 5 mostrou o erro quando um não
atribui. Um atributo pode ser definido de qualquer lugar, por qualquer método, a qualquer momento,
então nenhuma conferência dessas é possível. Por isso a JVM **zera a memória de todo objeto novo**
antes de qualquer outra coisa rodar, e o zero de cada tipo é a tabela acima. É uma regra de
segurança, e também uma armadilha: um `null` que ninguém quis deixar ali é idêntico a um `null` que
alguém escolheu. A seção 04 dá à classe um jeito de garantir que todo atributo seja definido.
