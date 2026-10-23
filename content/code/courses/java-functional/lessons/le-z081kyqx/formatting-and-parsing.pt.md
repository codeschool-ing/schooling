---
title: Formatando e interpretando
version: 1
---

**Uma data tem uma forma de texto que todo programa entende, a ISO 8601, `2026-12-28`, e é ela que o
`toString` dá e o `parse` lê.** Para pessoas há outras, e um `DateTimeFormatter` transforma uma data em
qualquer uma delas e de volta, a partir de um padrão de letras ou das convenções de um locale:

```java
// Formats.java: printing and parsing dates, and the pattern letter that lies once a year
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.FormatStyle;
import java.time.format.ResolverStyle;
import java.util.Locale;

public class Formats {
    public static void main(String[] args) {
        LocalDate date = LocalDate.of(2026, 12, 28);
        System.out.println("ISO:        " + date);
        System.out.println("dd/MM/uuuu: " + date.format(DateTimeFormatter.ofPattern("dd/MM/uuuu")));
        System.out.println("pt-BR long: " + date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(Locale.forLanguageTag("pt-BR"))));
        System.out.println("en-US long: " + date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(Locale.US)));
        System.out.println("dd/MM/YYYY: " + date.format(DateTimeFormatter.ofPattern("dd/MM/YYYY")));

        DateTimeFormatter smart = DateTimeFormatter.ofPattern("dd/MM/uuuu");
        DateTimeFormatter strict = smart.withResolverStyle(ResolverStyle.STRICT);
        for (String text : new String[] {"07/09/2026", "31/02/2026", "2026-09-07"}) {
            System.out.println(text + "  smart: " + parse(text, smart) + "  strict: " + parse(text, strict));
        }
    }

    static String parse(String text, DateTimeFormatter format) {
        try {
            return LocalDate.parse(text, format).toString();
        } catch (DateTimeParseException e) {
            return "refused";
        }
    }
}
```

```
ana@vm:~/fp/time$ java Formats.java
ISO:        2026-12-28
dd/MM/uuuu: 28/12/2026
pt-BR long: 28 de dezembro de 2026
en-US long: December 28, 2026
dd/MM/YYYY: 28/12/2027
07/09/2026  smart: 2026-09-07  strict: 2026-09-07
31/02/2026  smart: 2026-02-28  strict: refused
2026-09-07  smart: refused  strict: refused
```

## Padrões, locales e uma letra errada

`dd/MM/uuuu` é dia, mês e ano, e `MM` é mês onde `mm` seria minutos; as letras diferenciam maiúsculas, e a
tabela delas está na documentação do `DateTimeFormatter`. **Um formato localizado costuma ser a melhor
escolha para uma pessoa**, porque segue a língua de quem lê sem um padrão no código: a mesma data saiu como
`28 de dezembro de 2026` e `December 28, 2026`.

A quinta linha imprimiu **2027 para uma data de dezembro de 2026**. `YYYY` não é o ano: é o ano *baseado em
semanas*, o ano a que uma semana pertence pelas regras de semana do locale, e os últimos dias de dezembro
podem pertencer à primeira semana do ano seguinte. O padrão funciona por cinquenta e uma semanas e imprime
o ano errado nos últimos dias, e é assim que ele chega à produção. **O ano é `uuuu`** (ou `yyyy`, o ano da
era).

## Interpretar texto é entrada

Texto de um formulário ou de um arquivo é entrada, e os dois formatadores discordaram sobre ele.
`07/09/2026` foi lido igual nos dois. **`31/02/2026` virou 28 de fevereiro com o formatador padrão**, que
se chama smart e ajusta um dia grande demais para o seu mês; o `withResolverStyle(ResolverStyle.STRICT)` o
recusou. Texto em outro formato foi recusado pelos dois; por trás de cada `refused` há uma
`DateTimeParseException`, cuja mensagem diz em que caractere o texto deixou de casar.

Um formatador estrito é o certo para entrada, para que uma data que ninguém escreveu não vire, calada, uma
que alguém escreveu. O estrito também é o motivo de o padrão dizer `uuuu`: no modo estrito `yyyy` é um ano
de uma era, e sem uma era no padrão ele não pode virar uma data de jeito nenhum.
