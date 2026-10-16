---
title: Um plantão, e a passagem entre turnos
version: 1
---

A lição 10 terminou com um chamado chegando a um tópico. Alguém tem de estar do outro lado, às três da
manhã tanto quanto às três da tarde, e **o plantão é o acordo que diz quem**: uma pessoa por vez atende
os chamados de um serviço, num turno fixo, e depois passa para a próxima. Ninguém fica de plantão para
sempre, e ninguém fica de plantão sozinho.

## Principal e secundário

Um plantão nomeia duas pessoas para cada turno. O **principal** atende todo chamado. O **secundário** é
chamado quando o principal não responde, o que acontece com todo mundo cedo ou tarde: um telefone em
outro cômodo, um túnel, um banho. Uma semana é o turno comum numa equipe pequena, começando de manhã num
dia útil para a passagem acontecer com todos acordados. Uma regra que não custa nada torna o secundário
útil: **o secundário desta semana é o principal da semana passada**, que ainda lembra o que estava
estranho.

Um plantão é uma lista e uma data, então é um programa pequeno:

```python
# rotation.py: who is primary and who is secondary, week by week
import datetime as dt

people = ["Ana", "Bruno", "Carla", "Davi"]
first = dt.date(2026, 10, 19)  # a Monday; every shift starts at 10:00

for week in range(8):
    start = first + dt.timedelta(weeks=week)
    primary = people[week % len(people)]
    secondary = people[(week - 1) % len(people)]  # last week's primary
    print(f"{start:%a %d %b}  primary {primary:<6} secondary {secondary}")
```

```
ana@laptop:~/aws/oncall$ python3 rotation.py
Mon 19 Oct  primary Ana    secondary Davi
Mon 26 Oct  primary Bruno  secondary Ana
Mon 02 Nov  primary Carla  secondary Bruno
Mon 09 Nov  primary Davi   secondary Carla
Mon 16 Nov  primary Ana    secondary Davi
Mon 23 Nov  primary Bruno  secondary Ana
Mon 30 Nov  primary Carla  secondary Bruno
Mon 07 Dec  primary Davi   secondary Carla
```

Quatro pessoas, então cada uma é principal uma semana em quatro e secundária na semana seguinte. Com
menos de quatro as semanas voltam rápido demais para descansar entre elas; o livro de SRE do Google
defende pelo menos oito pessoas por local para um serviço que chama à noite, ou seis em cada um de dois
locais que passam o turno entre fusos horários.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma grade com quatro pessoas, Ana, Bruno, Carla e Davi, ao longo de oito semanas, de 19 de outubro a 7 de dezembro. A cada semana uma pessoa é a principal e quem foi principal na semana anterior é o secundário, então as células de principal descem a grade na diagonal e as de secundário vêm uma semana atrás. Cada pessoa é principal uma semana em quatro.\"><defs><marker id=\"rot-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"123.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">19 out</text><text x=\"201.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">26 out</text><text x=\"279.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 nov</text><text x=\"357.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">9 nov</text><text x=\"435.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">16 nov</text><text x=\"513.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">23 nov</text><text x=\"591.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30 nov</text><text x=\"669.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">7 dez</text><text x=\"20\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Ana</text><rect x=\"87\" y=\"54\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"123.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">principal</text><rect x=\"165\" y=\"54\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"201.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secundário</text><rect x=\"399\" y=\"54\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"435.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">principal</text><rect x=\"477\" y=\"54\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"513.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secundário</text><text x=\"20\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Bruno</text><rect x=\"165\" y=\"92\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"201.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">principal</text><rect x=\"243\" y=\"92\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"279.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secundário</text><rect x=\"477\" y=\"92\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"513.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">principal</text><rect x=\"555\" y=\"92\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"591.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secundário</text><text x=\"20\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Carla</text><rect x=\"243\" y=\"130\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"279.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">principal</text><rect x=\"321\" y=\"130\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"357.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secundário</text><rect x=\"555\" y=\"130\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"591.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">principal</text><rect x=\"633\" y=\"130\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"669.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secundário</text><text x=\"20\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Davi</text><rect x=\"87\" y=\"168\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"123.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secundário</text><rect x=\"321\" y=\"168\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"357.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">principal</text><rect x=\"399\" y=\"168\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"435.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secundário</text><rect x=\"633\" y=\"168\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"669.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">principal</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">A cada semana, o principal da semana anterior vira o secundário.</text></svg>", "caption": "Quatro pessoas: uma semana em quatro como principal, uma como secundário e duas de folga.", "same": ["Ana", "Bruno", "Carla", "Davi"]}
```

## Quanto um turno pode custar

Um plantão é humano ou não por números que dá para medir:

- **chamados por turno**. O número do livro de SRE é no máximo dois incidentes num turno de doze horas,
  porque um incidente e seu acompanhamento tomam boa parte de um dia; mais que isso e o acompanhamento
  nunca acontece;
- **chamados à noite**, contados à parte, já que um chamado às 03:00 custa também o dia seguinte;
- **folga depois de uma noite ruim**, escrita nas regras da equipe em vez de deixada à coragem de cada
  um para pedir.

A seção sobre fadiga mede os dois primeiros a partir de um mês de chamados.

## A passagem

**Um turno termina com uma nota**, escrita pelo principal que sai e lida pelo que entra, no lugar onde a
equipe as guarda. Ela traz o que a próxima pessoa precisa e não consegue ver num painel:

> **Passagem, seg 26 out, Ana para Bruno.** Dois chamados: `api-errors` na qua (deploy ruim, rollback,
> revisão na qui) e `db-cpu` no sáb (nada a fazer, ticket para reajustar). Em aberto: o certificado de
> `checkout.example.com` renova na sex, fique de olho. Nada foi mudado à mão.

A última linha é a que mais importa. Uma mudança feita à mão durante um turno, e não registrada, é a
causa do incidente da próxima pessoa.
