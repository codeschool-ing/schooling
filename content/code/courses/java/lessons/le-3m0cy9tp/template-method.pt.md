---
title: O template method, uma superclasse com lacunas a preencher
version: 1
---

Uma classe abstrata é mais útil quando é dona de um **algoritmo** e deixa alguns dos passos em
branco. Os passos que são iguais para tudo são escritos uma vez e ficam fora do alcance; os passos que
mudam são métodos abstratos que cada subclasse preenche. Esse arranjo tem nome, **template method**
(método modelo), e você vai encontrá-lo em quase todo framework que usar no `java-back`.

A biblioteca cobra pelas devoluções atrasadas. A regra é a mesma para tudo: nada se o item não está
atrasado, senão uma taxa diária vezes os dias de atraso, nunca mais que um máximo. **O que muda são os
dois números**, então eles são as lacunas. O dinheiro aqui são centavos inteiros num `int`, para nada
se perder numa fração. Num diretório novo, `~/abstract/fees`:

```java
// Loanable.java
public abstract class Loanable {
    private final String title;

    protected Loanable(String title) {
        this.title = title;
    }

    public final int lateFeeCents(int daysLate) {
        if (daysLate <= 0) {
            return 0;
        }
        int fee = daysLate * dailyFeeCents();
        return Math.min(fee, maximumFeeCents());
    }

    protected abstract int dailyFeeCents();

    protected int maximumFeeCents() {
        return 2000;
    }

    public String title() {
        return title;
    }
}
```

Três tipos de método numa classe, e cada um diz como uma subclasse pode tratá-lo:

| método | declarado | uma subclasse |
|---|---|---|
| `lateFeeCents` | `public final`, com corpo | pode chamá-lo, não pode substituí-lo |
| `dailyFeeCents` | `protected abstract`, sem corpo | tem de escrevê-lo |
| `maximumFeeCents` | `protected`, com corpo | pode substituí-lo, e herda 2000 se não o fizer |

Um método como o `maximumFeeCents`, com um padrão razoável que uma subclasse pode sobrescrever, é
chamado de **gancho** (hook). As duas lacunas são `protected`, porque são para as subclasses
preencherem e não para outras classes chamarem. Agora duas subclasses, de poucas linhas cada, e um
programa que pede as taxas às duas:

```java
// Book.java
public class Book extends Loanable {
    public Book(String title) {
        super(title);
    }

    @Override
    protected int dailyFeeCents() {
        return 50;
    }
}
```
```java
// Dvd.java
public class Dvd extends Loanable {
    public Dvd(String title) {
        super(title);
    }

    @Override
    protected int dailyFeeCents() {
        return 150;
    }

    @Override
    protected int maximumFeeCents() {
        return 3000;
    }
}
```
```java
// Fees.java
public class Fees {
    public static void main(String[] args) {
        Loanable[] items = {new Book("Effective Java"), new Dvd("Metropolis")};
        int[] lateness = {0, 3, 30};
        for (Loanable item : items) {
            for (int days : lateness) {
                int cents = item.lateFeeCents(days);
                System.out.println(item.title() + ", " + days + " days late: "
                        + cents / 100 + "." + String.format("%02d", cents % 100));
            }
        }
    }
}
```
```
ana@vm:~/abstract/fees$ javac Loanable.java Book.java Dvd.java Fees.java && java Fees
Effective Java, 0 days late: 0.00
Effective Java, 3 days late: 1.50
Effective Java, 30 days late: 15.00
Metropolis, 0 days late: 0.00
Metropolis, 3 days late: 4.50
Metropolis, 30 days late: 30.00
```

**Nenhuma das subclasses tem um único `if`, uma multiplicação ou um `Math.min`**, e as duas cobram
certo. Os trinta dias do livro deram 15.00, abaixo do máximo de 20.00. Os trinta dias do DVD a 1.50
dariam 45.00, e o máximo dele, de 30.00, os limitou. Os centavos são impressos como unidades e
centavos com aritmética inteira, `cents / 100` e `cents % 100`, então a taxa nunca vira `double`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A classe abstrata Loanable guarda um método final, lateFeeCents, com os passos escritos uma vez: dias de atraso vezes a taxa diária, limitado pelo máximo. Ele chama dailyFeeCents, abstrato e sem corpo, que toda subclasse escreve, e maximumFeeCents, um gancho que devolve 2000 por padrão. Book preenche dailyFeeCents com 50 e herda o máximo de 2000. Dvd preenche dailyFeeCents com 150 e troca o máximo por 3000.\"><defs><marker id=\"jv21-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"330\" height=\"258\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"181\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Loanable, abstrata</text><rect x=\"36\" y=\"54\" width=\"290\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"181\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">final lateFeeCents(daysLate)</text><text x=\"181\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">os passos, escritos uma vez:</text><text x=\"181\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dias × diária, limitado pelo máximo</text><rect x=\"36\" y=\"142\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"181\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">abstract dailyFeeCents()</text><text x=\"181\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem corpo: toda subclasse o escreve</text><rect x=\"36\" y=\"206\" width=\"290\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"181\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">maximumFeeCents()  2000</text><text x=\"181\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um gancho: um padrão que a subclasse pode trocar</text><path d=\"M60 116 V140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv21-a)\"></path><path d=\"M50 116 C20 160 20 200 34 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv21-a)\"></path><rect x=\"400\" y=\"60\" width=\"300\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"550\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dailyFeeCents()  50</text><text x=\"550\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">máximo: herdado, 2000</text><rect x=\"400\" y=\"170\" width=\"300\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Dvd</text><text x=\"550\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dailyFeeCents()  150</text><text x=\"550\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">maximumFeeCents()  3000</text><path d=\"M398 110 L330 160\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M398 206 L330 170\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M398 232 H330\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "A superclasse é dona da ordem dos passos, e ali não pode ser sobrescrita. As subclasses preenchem a lacuna que precisam e a que podem, e mais nada."}
```

## O `final` mantém a ordem dos passos

O `lateFeeCents` é `final`, então nenhuma subclasse pode substituir o próprio algoritmo. Um e-book
que resolvesse cobrar do seu jeito descobre isso na hora:

```java
// Ebook.java
public class Ebook extends Loanable {
    public Ebook(String title) {
        super(title);
    }

    @Override
    protected int dailyFeeCents() {
        return 0;
    }

    @Override
    public int lateFeeCents(int daysLate) {
        return -1;
    }
}
```
```
ana@vm:~/abstract/fees$ javac Ebook.java
Ebook.java:13: error: lateFeeCents(int) in Ebook cannot override lateFeeCents(int) in Loanable
    public int lateFeeCents(int daysLate) {
               ^
  overridden method is final
1 error
```

**`overridden method is final`** (o método sobrescrito é final). Sem o `final`, o `Ebook` compilaria
e devolveria -1 para toda devolução atrasada, e a regra "uma taxa nunca é negativa" valeria para toda
classe menos a que a quebrou, sem nada em `Loanable` capaz de impedir. O `final` num método é assunto
da lição 16; aqui ele é o que transforma "os passos acontecem nesta ordem" de um hábito numa
garantia. Apague o `Ebook.java` antes de seguir, senão todo `javac *.java` posterior neste diretório
falha nele.
