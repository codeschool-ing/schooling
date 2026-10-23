---
title: Perguntando a um Clock
version: 1
---

**`LocalDate.now()` lê o relógio do sistema, e código que lê o relógio do sistema dá uma resposta diferente
a cada dia em que roda.** Uma regra sobre datas de vencimento fica então impossível de conferir para o dia
anterior, o próprio dia e o dia seguinte sem esperar. A saída é a ideia da aula 4, comportamento passado
como valor: todo método `now` recebe um `java.time.Clock`, e um código que recebe o relógio como argumento
pode receber qualquer relógio:

```java
// Loans.java: code that asks a Clock for the date can be run on any day
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;

public class Loans {
    record Loan(String title, LocalDate due) {
        boolean overdue(Clock clock) {
            return LocalDate.now(clock).isAfter(due);
        }
    }

    public static void main(String[] args) {
        Loan loan = new Loan("Dune", LocalDate.of(2026, 3, 20));
        ZoneId saoPaulo = ZoneId.of("America/Sao_Paulo");

        Clock dueDay = Clock.fixed(Instant.parse("2026-03-20T15:00:00Z"), saoPaulo);
        Clock nextDay = Clock.offset(dueDay, Duration.ofDays(1));
        Clock lateEvening = Clock.fixed(Instant.parse("2026-03-21T01:30:00Z"), saoPaulo);
        Clock sameInstantUtc = lateEvening.withZone(ZoneOffset.UTC);

        System.out.println("on the due day:        " + loan.overdue(dueDay));
        System.out.println("a day later:           " + loan.overdue(nextDay));
        System.out.println("22:30 in Sao Paulo:    " + loan.overdue(lateEvening));
        System.out.println("same instant, in UTC:  " + loan.overdue(sameInstantUtc));
        System.out.println("today, by the system:  " + LocalDate.now(Clock.systemDefaultZone()));
    }
}
```

```
ana@vm:~/fp/time$ java Loans.java
on the due day:        false
a day later:           true
22:30 in Sao Paulo:    false
same instant, in UTC:  true
today, by the system:  2026-10-22
```

## Quatro relógios, uma regra

O `overdue` não sabe que dia é. Ele pergunta ao relógio que recebeu, então **a mesma regra foi conferida no
dia do vencimento, no dia seguinte e em dois momentos delicados**, tudo numa execução e nenhum deles hoje.
O `Clock.fixed` para o tempo num instante, e o `Clock.offset` desloca outro relógio por uma `Duration`, que
é como um teste atravessa um mês num milissegundo. Só a última linha leu o relógio de verdade, e é a única
cuja saída muda de uma execução para outra.

As duas do meio são o mesmo instante, 01:30 UTC de 21 de março, e discordam. **Em São Paulo eram 22:30 do
dia 20**, o dia do vencimento, e o empréstimo não estava atrasado; em UTC já era dia 21. Um servidor que
roda em UTC e uma biblioteca em São Paulo diriam ao mesmo aluno duas coisas diferentes. O relógio leva o
fuso, então o código que monta o relógio decide isso uma vez, para o programa inteiro, e tudo o que
pergunta ao relógio concorda.

O `Clock.systemDefaultZone()` usa o fuso em que a máquina está configurada, e o `Clock.systemUTC()` usa UTC.
Um programa cria um onde começa, na `main`, e o passa adiante, do mesmo jeito que a aula 16 passou um
executor; um teste passa um fixo no lugar. **Código que chama `now()` sem argumento decidiu o relógio por
conta própria**, e o teste não tem onde lhe dar outro.
