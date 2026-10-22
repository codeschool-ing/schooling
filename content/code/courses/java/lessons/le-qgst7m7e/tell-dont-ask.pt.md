---
title: Mande, não pergunte
version: 1
---

Atributos privados com um getter cada ainda conseguem espalhar o conhecimento de uma classe pelo
programa inteiro. Os atributos estão seguros; as **regras** sobre eles ficam escritas em cada
chamador que os lê. "Tell, don't ask" (mande, não pergunte) é o hábito que traz a regra de volta: em
vez de pedir os dados a um objeto e decidir alguma coisa com eles, você diz ao objeto o que precisa
e deixa que ele decida.

## Perguntando

Um empréstimo com getters, e um chamador que calcula a multa por atraso:

```java
// AskLoan.java
import java.time.LocalDate;

public class AskLoan {
    private final String title;
    private final LocalDate due;

    public AskLoan(String title, LocalDate due) {
        this.title = title;
        this.due = due;
    }

    public String getTitle() {
        return title;
    }

    public LocalDate getDue() {
        return due;
    }
}
```

```java
// AskDemo.java
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

public class AskDemo {
    public static void main(String[] args) {
        AskLoan loan = new AskLoan("Iracema", LocalDate.of(2026, 10, 9));
        LocalDate today = LocalDate.of(2026, 10, 12);
        long late = ChronoUnit.DAYS.between(loan.getDue(), today);
        long fee = late > 0 ? late * 50 : 0;
        System.out.println(loan.getTitle() + ": " + fee + " cents");
    }
}
```

```
ana@vm:~/encap$ javac AskLoan.java AskDemo.java && java AskDemo
Iracema: 150 cents
```

Três dias de atraso, cinquenta centavos por dia, 150 centavos. A resposta está certa. O problema é
onde ela foi calculada: **a regra da multa está escrita no `AskDemo`**, e também a proteção que
impede um empréstimo devolvido antes do prazo de render multa negativa. A impressora de recibos, o
e-mail de lembrete e a página da conta do sócio precisam do mesmo número, e cada uma vai escrever as
mesmas três linhas, até que uma delas esqueça o `late > 0`.

## Mandando

```schooling-example
{
  "language": "java",
  "file": "Loan.java",
  "parts": [
    {
      "code": "import java.time.LocalDate;\nimport java.time.temporal.ChronoUnit;\n\npublic class Loan {\n    private static final long FEE_PER_DAY_CENTS = 50;\n\n    private final String title;\n    private final LocalDate due;",
      "note": "**O número da regra mora na classe a que pertence**, como constante: cinquenta centavos por dia. A multa é uma contagem de centavos num `long`, nunca num `double`, pelo motivo que a lição 8 dá."
    },
    {
      "code": "\n    public Loan(String title, LocalDate due) {\n        this.title = title;\n        this.due = due;\n    }",
      "note": "O construtor guarda os dois fatos de que um empréstimo é feito. Não há getter nenhum, porque nada de fora precisa das datas cruas."
    },
    {
      "code": "\n    public long lateFeeCents(LocalDate today) {\n        long late = ChronoUnit.DAYS.between(due, today);\n        return late > 0 ? late * FEE_PER_DAY_CENTS : 0;\n    }",
      "note": "**A pergunta que os chamadores tinham de fato, respondida onde os dados estão.** Dias de atraso vezes a multa diária, e zero para um empréstimo que ainda não atrasou, então ninguém consegue produzir uma multa negativa."
    },
    {
      "code": "\n    public String describe(LocalDate today) {\n        return title + \": \" + lateFeeCents(today) + \" cents\";\n    }\n}",
      "note": "Um método construído sobre o outro. Quem chama entrega a data de hoje, então a classe nunca lê o relógio sozinha, e o mesmo empréstimo dá a mesma resposta num teste em qualquer dia."
    }
  ]
}
```

```java
// TellDemo.java
import java.time.LocalDate;

public class TellDemo {
    public static void main(String[] args) {
        Loan loan = new Loan("Iracema", LocalDate.of(2026, 10, 9));
        System.out.println(loan.describe(LocalDate.of(2026, 10, 12)));
        System.out.println(loan.describe(LocalDate.of(2026, 10, 5)));
    }
}
```

```
ana@vm:~/encap$ javac Loan.java TellDemo.java && java TellDemo
Iracema: 150 cents
Iracema: 0 cents
```

Os mesmos 150 centavos, e um empréstimo consultado antes da data de devolução dá 0. **Agora a regra
existe uma vez só**, na classe dona das datas, e todo chamador pede `lateFeeCents` em vez de
repeti-la. As próprias datas nunca saem do objeto, que é o encapsulamento fazendo o trabalho para o
qual existe: no dia em que a biblioteca cobrar mais no fim de semana, um método muda.

## Onde isso para

Nem toda classe deve esconder os seus dados. Uma classe cujo único propósito é levar valores de um
lugar para outro não tem nada a decidir: uma linha lida de um arquivo, digamos, ou uma resposta
enviada pela rede. Embrulhá-la em comportamento inventaria regras que ela não tem. **Para dados que são só
dados, o `record` da lição 29 é a ferramenta certa**, e os métodos de acesso dele são do tipo
honesto: existem porque ler os valores é o objetivo.

A pergunta a fazer a um getter é quem o chama, e o que faz com a resposta. Se todo chamador faz a
mesma conta com ele, a conta pertence ao lado de dentro, e o getter talvez nem precise existir.
