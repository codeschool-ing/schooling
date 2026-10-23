---
title: Classes internas, e o objeto que elas carregam
version: 1
---

Tire o `static` de uma classe aninhada e ela vira uma **classe interna**, e a diferença não é um
detalhe de sintaxe. **Todo objeto de uma classe interna está preso a um objeto da classe de fora**,
aquele a partir do qual foi criado, e consegue ler os atributos desse objeto como se fossem seus.

Uma carteirinha de biblioteca pertence a um sócio. O que se empresta com a carteirinha conta contra
aquele sócio, então a carteirinha precisa saber de quem é. Esse é o formato em que uma classe interna
se encaixa. Salve isto em `~/nested`:

```java
// Member.java
public class Member {
    private final String name;
    private int borrowed;

    Member(String name) {
        this.name = name;
    }

    class Card {
        private final int number;

        Card(int number) {
            this.number = number;
        }

        void borrow() {
            borrowed++;
            System.out.println("card " + number + " of " + name + ": " + borrowed + " borrowed");
        }

        Member owner() {
            return Member.this;
        }
    }

    public static void main(String[] args) {
        Member ana = new Member("Ana");
        Member rui = new Member("Rui");
        Member.Card a1 = ana.new Card(1);
        Member.Card a2 = ana.new Card(2);
        Member.Card r1 = rui.new Card(3);
        a1.borrow();
        a2.borrow();
        r1.borrow();
        System.out.println(a1.owner() == a2.owner());
    }
}
```

`Card` não tem atributo chamado `name` nem chamado `borrowed`, e mesmo assim `borrow()` lê um e soma
no outro. São os atributos do sócio a quem a carteirinha pertence:

```
ana@vm:~/nested$ javac Member.java && java Member
card 1 of Ana: 1 borrowed
card 2 of Ana: 2 borrowed
card 3 of Rui: 1 borrowed
true
```

**As carteirinhas 1 e 2 dividem uma contagem, e a 3 tem a sua.** A Ana pegou um livro em cada uma das
duas carteirinhas e o total dela é 2; a carteirinha do Rui conta a partir de 1. A última linha é
`a1.owner() == a2.owner()`, e o `true` diz que as duas carteirinhas guardam exatamente o mesmo objeto
`Member`, e não duas cópias dele.

## A sintaxe de criação diz de quem é

Repare em como as carteirinhas foram criadas: **`ana.new Card(1)`**. Um objeto interno não pode ser
criado do nada, então o `new` é chamado *sobre* um objeto de fora, e esse objeto vira o dono da
carteirinha. Dentro dos métodos de instância da própria classe de fora, um simples `new Card(1)`
funciona, porque o `this` está ali para ser o dono. No `main`, que é estático, não há `this`. Mude a
linha da primeira carteirinha para tirar o dono e compile:

```
ana@vm:~/nested$ sed -i 's/ana.new Card(1)/new Card(1)/' Member.java
ana@vm:~/nested$ javac Member.java
Member.java:30: error: non-static variable this cannot be referenced from a static context
        Member.Card a1 = new Card(1);
                         ^
1 error
```

A mensagem é a da seção 02, desta vez sobre o `this` em vez de um atributo: o compilador foi procurar
um objeto de fora para dar à carteirinha, e um método estático não tem nenhum.

## Onde o dono fica guardado

A JVM também não tem ideia de classe interna, então o compilador transforma o dono em algo que ela
entende: **um atributo**. O `javap -p` imprime também os membros privados, e mostra o que foi
acrescentado:

```
ana@vm:~/nested$ ls Member*
Member$Card.class
Member.class
Member.java
ana@vm:~/nested$ javap -p 'Member$Card'
Compiled from "Member.java"
class Member$Card {
  private final int number;
  final Member this$0;
  Member$Card(Member, int);
  void borrow();
  Member owner();
}
```

Duas coisas que ninguém escreveu. Um atributo **`this$0`** do tipo `Member`, e um construtor que
recebe um `Member` antes do `int` que o código-fonte declarou. `ana.new Card(1)` compila numa chamada
desse construtor com `ana` como primeiro argumento, e o `name` dentro de `borrow()` compila em
`this$0.name`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três objetos Member$Card, a1, a2 e r1, cada um com um atributo escondido this$0. O this$0 de a1 e o de a2 apontam para o mesmo Member, Ana, que pegou 2. O this$0 de r1 aponta para outro Member, Rui, que pegou 1.\"><defs><marker id=\"jv17-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Member$Card  a1</text><text x=\"130\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">number 1</text><text x=\"130\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">this$0</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Member$Card  a2</text><text x=\"360\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">number 2</text><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">this$0</text><rect x=\"500\" y=\"30\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Member$Card  r1</text><text x=\"590\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">number 3</text><text x=\"590\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">this$0</text><rect x=\"155\" y=\"160\" width=\"180\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Member</text><text x=\"245\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">name \"Ana\", borrowed 2</text><rect x=\"500\" y=\"160\" width=\"180\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Member</text><text x=\"590\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">name \"Rui\", borrowed 1</text><path d=\"M130 100 L215 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv17-a)\"></path><path d=\"M360 100 L275 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv17-a)\"></path><path d=\"M590 100 L590 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv17-a)\"></path><text x=\"360\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">todo objeto interno guarda o de fora de onde foi criado</text></svg>", "caption": "ana.new Card(...) gravou ana no atributo escondido da carteirinha nova. Duas carteirinhas dividem um sócio, então dividem a contagem dele."}
```

`Member.this` é como o código-fonte escreve esse atributo. Dentro de `Card`, o `this` simples é a
carteirinha, e **`Member.this` é o sócio a quem ela pertence**, que é o que `owner()` devolve. Você
só precisa da forma longa quando tem de nomear o próprio objeto de fora, ou quando a classe interna
tem um atributo com o mesmo nome de um de fora e o nome curto significaria o de dentro.

**O atributo escondido é o custo.** Cada carteirinha guarda uma referência ao seu sócio enquanto a
carteirinha existir, e a lição 19 mostra que um objeto fica na memória enquanto algo ainda se refere a
ele. Um objeto interno entregue a alguma parte do programa que vive muito mantém vivo, junto com ele,
o objeto de fora, que é o jeito clássico de uma classe aninhada vazar memória. É por isso que a seção
02 mandou começar pelo `static` e só tirá-lo quando o objeto interno precisa do dono, como uma
carteirinha precisa.
