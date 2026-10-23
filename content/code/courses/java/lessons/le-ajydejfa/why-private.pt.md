---
title: Por que privado é o padrão sensato
version: 1
---

O motivo óbvio para fazer um atributo privado é o segredo, e é o motivo errado: quem lê o código-fonte
lê o nome do atributo. **O motivo é que uma classe só consegue cumprir uma promessa sobre dados que
mais ninguém pode alterar.** A regra de uma biblioteca é simples. Um empréstimo pode ser renovado duas
vezes, e o terceiro pedido é recusado. Num diretório novo, `~/loans`, aqui está essa regra com um
atributo aberto:

```java
// OpenLoan.java
class OpenLoan {
    int renewals;

    boolean renew() {
        if (renewals == 2) {
            return false;
        }
        renewals = renewals + 1;
        return true;
    }
}
```

O `renew()` aplica a regra corretamente, e nada obriga ninguém a chamá-lo:

```java
// OpenMain.java
public class OpenMain {
    public static void main(String[] args) {
        OpenLoan loan = new OpenLoan();
        System.out.println(loan.renew() + " " + loan.renew() + " " + loan.renew());
        loan.renewals = 0;
        System.out.println(loan.renew() + " " + loan.renewals);
        loan.renewals = 7;
        System.out.println(loan.renew() + " " + loan.renewals);
    }
}
```

```
ana@vm:~/loans$ javac OpenMain.java && java OpenMain
true true false
true 1
true 8
```

A primeira linha é a regra funcionando: duas renovações, depois uma recusa. Então uma atribuição
voltou a contagem a zero e o empréstimo pôde ser renovado de novo, e outra a pôs em 7, depois do que o
`renew()` disse `true` e a contagem chegou a 8. **A verificação `renewals == 2` nunca dispara depois
que a contagem passou do 2**, então agora o empréstimo pode ser renovado para sempre. Nada falhou,
nada imprimiu aviso, e a regra está quebrada em todo programa que tenha uma atribuição perdida, em
qualquer lugar.

## A mesma classe, com o atributo fechado

```java
// Loan.java
class Loan {
    private int renewals;

    boolean renew() {
        if (renewals == 2) {
            return false;
        }
        renewals = renewals + 1;
        return true;
    }

    int renewals() {
        return renewals;
    }
}
```

Duas mudanças. O atributo é `private`, e um método `renewals()` deixa as outras classes **lerem** a
contagem sem poder escrevê-la. Um programa que usa o empréstimo do jeito previsto funciona como antes:

```java
// LoanMain.java
public class LoanMain {
    public static void main(String[] args) {
        Loan loan = new Loan();
        System.out.println(loan.renew() + " " + loan.renew() + " " + loan.renew());
        System.out.println(loan.renewals());
    }
}
```

E um que tenta o atalho não compila:

```java
// Cheat.java
public class Cheat {
    public static void main(String[] args) {
        Loan loan = new Loan();
        loan.renewals = 0;
    }
}
```

```
ana@vm:~/loans$ javac LoanMain.java && java LoanMain
true true false
2
ana@vm:~/loans$ javac Cheat.java
Cheat.java:5: error: renewals has private access in Loan
        loan.renewals = 0;
            ^
1 error
```

**Agora o único código que pode mudar `renewals` é o código dentro de `Loan`**, e ele inteiro cabe na
tela. Para saber se a regra se mantém, você lê uma classe, não o programa todo. É isso que
*encapsulamento* quer dizer, e a lição 22 vai além.

## Comece do privado, e abra o que precisar

A regra prática é declarar todo atributo `private` e todo método tão fechado quanto possível, e então
abrir um membro só quando outra classe tiver um motivo para usá-lo. Um modificador restrito demais
custa um erro de compilação, no momento em que alguém precisa de mais, que é o momento de pensar no
assunto. Um modificador aberto demais não custa nada no dia em que é escrito, e é muito difícil de
apertar depois, porque aí outro código já depende dele, e parte desse código não é seu para mudar.
