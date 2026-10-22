---
title: Um atributo que pertence à classe
version: 1
---

Todo atributo das lições 12 a 14 tinha uma cópia por objeto, que é do que o título de um livro ou os
empréstimos de um sócio precisam. Alguns dados não são sobre um objeto. Quantos sócios a biblioteca
cadastrou? Nenhum sócio sozinho sabe, e guardar o número em cada um deles obrigaria a atualizar todas
as cópias a cada vez. **Um atributo `static` tem uma cópia, que pertence à classe**, compartilhada por
todos os objetos dela e alcançável sem objeto nenhum.

Num diretório novo, `~/static`, um sócio que conta quantos sócios foram criados:

```java
// Member.java
class Member {
    static int created = 0;
    String name;
    int loans = 0;

    Member(String name) {
        this.name = name;
        created = created + 1;
    }
}
```

O construtor soma um a `created` cada vez que um sócio é criado. Como `created` é estático, é o mesmo
atributo para todos eles, e por isso conta pelo programa inteiro:

```java
// Counter.java
public class Counter {
    public static void main(String[] args) {
        System.out.println(Member.created);
        Member a = new Member("Ana");
        Member b = new Member("Bruno");
        a.loans = a.loans + 1;
        System.out.println(Member.created + " " + a.loans + " " + b.loans);
        System.out.println(a.created + " " + b.created);
    }
}
```

```
ana@vm:~/static$ javac Counter.java && java Counter
0
2 1 0
2 2
```

A primeira linha leu `Member.created` **antes de existir qualquer sócio**, pelo nome da classe, e
obteve 0. Depois de dois construtores, vale 2. `a.loans` é 1 e `b.loans` é 0, porque `loans` é um
atributo comum e cada sócio tem o seu:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma classe e dois objetos. A classe Member guarda um atributo estático, created, igual a 2. Cada objeto, Ana e Bruno, guarda o seu name e os seus loans: Ana tem 1 empréstimo e Bruno 0. Os dois objetos apontam para a mesma classe, então a.created e b.created leem o mesmo atributo.\"><defs><marker id=\"jv15-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"240\" y=\"16\" width=\"240\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a classe Member, carregada uma vez</text><rect x=\"270\" y=\"52\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">static created = 2</text><rect x=\"60\" y=\"150\" width=\"240\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">objeto a</text><text x=\"180\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">name = \"Ana\"</text><text x=\"180\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loans = 1</text><rect x=\"420\" y=\"150\" width=\"240\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">objeto b</text><text x=\"540\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">name = \"Bruno\"</text><text x=\"540\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loans = 0</text><path d=\"M180 150 V120 H330 V96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv15-a)\"></path><path d=\"M540 150 V120 H390 V96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv15-a)\"></path><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada objeto conhece a sua classe</text></svg>", "caption": "Depois dos dois construtores do Counter: um created para a classe, um name e uma contagem de loans para cada objeto. a.created e b.created são duas grafias de Member.created."}
```

A última linha é a que engana. `a.created` e `b.created` parecem atributos de dois objetos, e são o
mesmo atributo, lido duas vezes. O compilador aceita essa grafia, e com `-Xlint:static` ele diz o que
pensa dela:

```
ana@vm:~/static$ javac -Xlint:static Counter.java
Counter.java:9: warning: [static] static variable should be qualified by type name, Member, instead of by an expression
        System.out.println(a.created + " " + b.created);
                            ^
Counter.java:9: warning: [static] static variable should be qualified by type name, Member, instead of by an expression
        System.out.println(a.created + " " + b.created);
                                              ^
2 warnings
```

**Escreva um membro estático pelo nome da classe, `Member.created`, nunca por um objeto.** Quem lê
sabe na hora que ele é compartilhado, que é a única coisa que importa sobre ele.

O `javap` mostra onde mora a diferença:

```
ana@vm:~/static$ javap -p Member
Compiled from "Member.java"
class Member {
  static int created;
  java.lang.String name;
  int loans;
  Member(java.lang.String);
  static {};
}
```

`created` está marcado como `static` e os outros dois atributos não. A última linha, `static {}`, é
código que o compilador escreveu para rodar `created = 0` uma vez, quando a classe é carregada, e não
uma vez por objeto. A lição 27 mostra esses blocos por inteiro e a ordem em que rodam.
