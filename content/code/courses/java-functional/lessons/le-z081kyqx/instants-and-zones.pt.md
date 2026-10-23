---
title: Um instante, e o nome que ele tem onde você está
version: 1
---

**O `java.time` separa duas perguntas que o código antigo misturava: quando algo aconteceu, e o que o
calendário e o relógio da parede diziam ali naquele momento.** Um `Instant` responde a primeira: um ponto
numa única linha do tempo, contado em segundos desde o início de 1970 em UTC, o mesmo em todo lugar da
Terra. Um `ZonedDateTime` responde a segunda, e o `LocalDate` tirado dele também:

```java
// Moment.java: one instant, seen from three time zones
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;

public class Moment {
    public static void main(String[] args) {
        Instant launch = Instant.parse("2026-03-08T02:30:00Z");
        System.out.println("instant:   " + launch);
        System.out.println("epoch s:   " + launch.getEpochSecond());

        for (String zone : new String[] {"America/Sao_Paulo", "America/New_York", "Asia/Tokyo"}) {
            ZonedDateTime there = launch.atZone(ZoneId.of(zone));
            LocalDate day = there.toLocalDate();
            System.out.printf("%-18s %s  date %s, %s%n", zone, there.toLocalDateTime(), day, day.getDayOfWeek());
        }
    }
}
```

```
ana@vm:~/fp/time$ java Moment.java
instant:   2026-03-08T02:30:00Z
epoch s:   1772937000
America/Sao_Paulo  2026-03-07T23:30  date 2026-03-07, SATURDAY
America/New_York   2026-03-07T21:30  date 2026-03-07, SATURDAY
Asia/Tokyo         2026-03-08T11:30  date 2026-03-08, SUNDAY
```

## Um momento, duas datas

O foguete partiu uma vez, no segundo 1.772.937.000. **Em São Paulo e em Nova York ainda era sábado, dia 7;
em Tóquio já era domingo, dia 8.** Nada no instante está errado para nenhuma delas, e nada nele diz qual
data é a certa, porque nenhuma é: uma data só existe depois que se escolhe um fuso horário.

| tipo | guarda | um exemplo |
|---|---|---|
| `Instant` | um ponto na linha do tempo, em UTC | `2026-03-08T02:30:00Z` |
| `LocalDate` | uma data sem hora e sem fuso | `2026-03-07` |
| `LocalDateTime` | uma data e uma hora, sem fuso | `2026-03-07T23:30` |
| `ZonedDateTime` | uma data e uma hora num fuso com nome | `2026-03-07T23:30-03:00[America/Sao_Paulo]` |

**Guarde e compare instantes; mostre datas locais.** Uma linha de log, um pagamento, a hora em que uma
linha foi criada são instantes, e dois deles se comparam certo onde quer que tenham sido registrados. Um
aniversário, um feriado ou o dia em que um empréstimo vence é um `LocalDate`, porque é o mesmo dia em
qualquer fuso em que o leitor esteja. O `LocalDateTime` sem fuso é o que pede cuidado: ele dá uma hora
numa parede qualquer, sem dizer qual, então não pode virar um instante até que se acrescente um fuso.

Um fuso é um nome como `America/Sao_Paulo`, não um deslocamento como `-03:00`, porque o deslocamento é uma
regra que muda: o Brasil parou de mexer nos relógios em 2019, e Nova York mexe neles duas vezes por ano.
O JDK traz a história dessas regras, e o `atZone` usou a que valia naquele instante.

Cada uma dessas classes é **imutável**: `plusDays` devolve um objeto novo e deixa o antigo como estava. É
por isso que um `LocalDate` pode ser compartilhado entre threads sem nenhum dos cuidados das aulas 11 a
15: um objeto imutável é publicado com segurança, como a aula 12 seção 05 mostrou. Os antigos
`java.util.Date` e `SimpleDateFormat` eram mutáveis, e um `SimpleDateFormat` compartilhado entre threads
pode dar datas erradas.
