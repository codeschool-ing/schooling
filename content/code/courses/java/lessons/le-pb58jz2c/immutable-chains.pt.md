---
title: Cadeias em objetos que nunca mudam
version: 1
---

O `StringBuilder` e o recibo encadeavam alterando um objeto e devolvendo-o. O outro tipo de cadeia
parece igual na página e funciona ao contrário: **cada chamada deixa o objeto como está e devolve um
novo**. A `String` funciona assim, e também toda classe de data e hora do `java.time`. Uma cadeia
nelas é uma série de objetos novos, cada um construído a partir do anterior.

## Uma data de devolução, e uma renovação que não fez nada

```java
// Dates.java
import java.time.LocalDate;

public class Dates {
    public static void main(String[] args) {
        LocalDate lent = LocalDate.of(2026, 10, 9);
        LocalDate due = lent.plusWeeks(3).plusDays(1);
        System.out.println("lent " + lent + ", due " + due);

        due.plusDays(7);
        System.out.println("after renewing: " + due);

        String title = "iracema";
        title.toUpperCase();
        System.out.println(title);
    }
}
```

```
ana@vm:~/fluent$ javac Dates.java && java Dates
lent 2026-10-09, due 2026-10-31
after renewing: 2026-10-31
iracema
```

A primeira cadeia fez o que diz: três semanas e um dia depois de 9 de outubro é 31 de outubro, e
`due` guarda o resultado. `lent` continua dizendo dia 9, porque o `plusWeeks` nunca tocou nele.

**A renovação é o bug.** `due.plusDays(7)` calculou 7 de novembro, devolveu, e o programa jogou fora,
porque nada foi atribuído. `due` continua dizendo 31 de outubro. O mesmo aconteceu com o título: o
`toUpperCase()` construiu `IRACEMA` e a linha o descartou, então saiu `iracema`. O compilador não
disse nada sobre nenhum dos dois, já que chamar um método e ignorar o resultado é Java legal. **A
correção é a atribuição que o leitor achou que estava lá**: `due = due.plusDays(7);`.

## Escrevendo uma

Uma classe imutável com métodos encadeáveis devolve uma instância nova em cada um deles. A multa da
biblioteca:

```java
// Fine.java
public final class Fine {
    private final long cents;
    private final String reason;

    public Fine(long cents, String reason) {
        this.cents = cents;
        this.reason = reason;
    }

    public Fine plus(long more) {
        return new Fine(cents + more, reason);
    }

    public Fine withReason(String newReason) {
        return new Fine(cents, newReason);
    }

    @Override
    public String toString() {
        return cents + " cents for " + reason;
    }
}
```

```java
// Fines.java
public class Fines {
    public static void main(String[] args) {
        Fine first = new Fine(150, "late return");
        Fine second = first.plus(50).plus(50).withReason("late return, two reminders");
        System.out.println(first);
        System.out.println(second);
    }
}
```

```
ana@vm:~/fluent$ javac Fine.java Fines.java && java Fines
150 cents for late return
250 cents for late return, two reminders
```

`first` continua dizendo 150 centavos e o primeiro motivo, depois de uma cadeia de três chamadas que
partiu dele. Cada chamada construiu um `Fine` novo e a cadeia continuou nesse; `second` é o último
deles, 250 centavos com o motivo novo. O prefixo `with` é a convenção para "uma cópia com esta parte
trocada", e os records da lição 29 são para onde o Java está indo com ela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois tipos de cadeia. Em cima, uma cadeia mutável: o objeto recibo devolve a si mesmo em line, então toda chamada trabalha num objeto só. Embaixo, uma cadeia imutável em Fine: first, 150 centavos por atraso, depois plus(50) constrói um Fine novo de 200 centavos, plus(50) outro de 250, e withReason um quarto com o motivo novo, que é second. first não muda.\"><defs><marker id=\"jv26-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">uma cadeia mutável</text><rect x=\"250\" y=\"40\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o recibo</text><text x=\"360\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um objeto, alterado a cada chamada</text><path d=\"M470 60 C520 40, 520 92, 472 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv26-a)\"></path><text x=\"528\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">line(...) returns this</text><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">uma cadeia imutável</text><rect x=\"20\" y=\"160\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">first</text><text x=\"80\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150, late return</text><rect x=\"210\" y=\"160\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um Fine novo</text><text x=\"270\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200, late return</text><rect x=\"400\" y=\"160\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um Fine novo</text><text x=\"460\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">250, late return</text><rect x=\"590\" y=\"160\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">second</text><text x=\"650\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">250, reminders</text><path d=\"M140 188 H208\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv26-a)\"></path><text x=\"174.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">plus(50)</text><path d=\"M330 188 H398\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv26-a)\"></path><text x=\"364.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">plus(50)</text><path d=\"M520 188 H588\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv26-a)\"></path><text x=\"554.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">withReason</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">quatro objetos; ninguém recebe os dois do meio, e first nunca muda</text></svg>", "caption": "Em cima, cada chamada altera um objeto. Embaixo, cada chamada cria um novo e o antigo fica como estava, e é por isso que o resultado precisa ser guardado."}
```

## Qual tipo está na sua frente

Os dois tipos de cadeia não se distinguem olhando a chamada. Eles diferem no que o método devolve, e
a documentação diz:

| classe | `x.algumaCoisa()` | para guardar o resultado |
|---|---|---|
| `StringBuilder`, o recibo, um builder | altera `x` e devolve `x` | nada a fazer; `x` mudou |
| `String`, `LocalDate`, `BigDecimal`, `Fine` | devolve um objeto novo; `x` não muda | atribua: `x = x.algumaCoisa();` |

**Uma cadeia imutável é mais segura para compartilhar**: um `Fine` entregue a outra parte do programa
não pode ser alterado pelas suas costas, pelo motivo que a lição 22 deu sobre listas. O que ela pede
em troca é que você nunca chame um dos seus métodos como instrução isolada, sem nada recebendo o
resultado.
