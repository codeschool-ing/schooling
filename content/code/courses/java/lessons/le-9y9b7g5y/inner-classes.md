---
title: Inner classes, and the object they carry
version: 1
---

Take `static` away from a nested class and it becomes an **inner class**, and the difference is not
a detail of syntax. **Every object of an inner class is tied to one object of the outer class**, the
one it was created from, and it can read that object's fields as if they were its own.

A library card belongs to a member. Lending on the card counts against that member, so the card
needs to know whose it is. That is the shape an inner class fits. Save this in `~/nested`:

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

`Card` has no field called `name` and none called `borrowed`, yet `borrow()` reads one and adds to
the other. They are the fields of the member the card belongs to:

```
ana@vm:~/nested$ javac Member.java && java Member
card 1 of Ana: 1 borrowed
card 2 of Ana: 2 borrowed
card 3 of Rui: 1 borrowed
true
```

**Cards 1 and 2 share one count, and card 3 has its own.** Ana borrowed once on each of her two
cards and her total is 2; Rui's card counts from 1. The last line is `a1.owner() == a2.owner()`,
and `true` says both cards hold the very same `Member` object, not two copies of it.

## The creation syntax says whose it is

Look at how the cards were made: **`ana.new Card(1)`**. An inner object cannot be made from nothing,
so `new` is called *on* an outer object, and that object becomes the card's owner. Inside the outer
class's own instance methods, plain `new Card(1)` works, because `this` is there to be the owner.
In `main`, which is static, there is no `this`. Change the first card's line to drop the owner and
compile:

```
ana@vm:~/nested$ sed -i 's/ana.new Card(1)/new Card(1)/' Member.java
ana@vm:~/nested$ javac Member.java
Member.java:30: error: non-static variable this cannot be referenced from a static context
        Member.Card a1 = new Card(1);
                         ^
1 error
```

The message is section 02's, about `this` this time instead of a field: the compiler went looking
for an outer object to give the card, and a static method has none.

## Where the owner is kept

The JVM has no idea of inner classes either, so the compiler turns the owner into something it does
understand: **a field**. `javap -p` prints private members too, and it shows what was added:

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

Two things nobody wrote. A field **`this$0`** of type `Member`, and a constructor that takes a
`Member` before the `int` the source declared. `ana.new Card(1)` compiles into a call of that
constructor with `ana` as its first argument, and `name` inside `borrow()` compiles into
`this$0.name`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three Member$Card objects, a1, a2 and r1, each with a hidden field this$0. The this$0 of a1 and of a2 point at the same Member, Ana, who has borrowed 2. The this$0 of r1 points at another Member, Rui, who has borrowed 1.\"><defs><marker id=\"jv17-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Member$Card  a1</text><text x=\"130\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">number 1</text><text x=\"130\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">this$0</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Member$Card  a2</text><text x=\"360\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">number 2</text><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">this$0</text><rect x=\"500\" y=\"30\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Member$Card  r1</text><text x=\"590\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">number 3</text><text x=\"590\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">this$0</text><rect x=\"155\" y=\"160\" width=\"180\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Member</text><text x=\"245\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">name \"Ana\", borrowed 2</text><rect x=\"500\" y=\"160\" width=\"180\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Member</text><text x=\"590\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">name \"Rui\", borrowed 1</text><path d=\"M130 100 L215 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv17-a)\"></path><path d=\"M360 100 L275 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv17-a)\"></path><path d=\"M590 100 L590 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv17-a)\"></path><text x=\"360\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every inner object holds the outer one it was made from</text></svg>", "caption": "ana.new Card(...) wrote ana into the new card's hidden field. Two cards share one member, so they share its borrowed count."}
```

`Member.this` is how the source spells that field. Inside `Card`, plain `this` is the card, and
**`Member.this` is the member it belongs to**, which is what `owner()` returns. You need the long
form only when you must name the outer object itself, or when the inner class has a field with the
same name as an outer one and the short name would mean the inner.

**The hidden field is the cost.** Every card holds a reference to its member for as long as the card
exists, and lesson 19 shows that an object stays in memory while anything still refers to it. An
inner object handed to some long-lived part of a program keeps its outer object alive with it, which
is the classic way a nested class leaks memory. That is why section 02 said to start with `static`
and drop it only when the inner object needs its owner, as a card does.
