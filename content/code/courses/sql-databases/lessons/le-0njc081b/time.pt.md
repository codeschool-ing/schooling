---
title: Tempo, e a coluna que erra duas vezes por ano
version: 1
---

Esta seção carrega uma regra que evita uma classe inteira de bug, e a regra é curta:

> **Use `timestamptz`. Não `timestamp`.**

Todo o resto aqui é o porquê.

## Os quatro tipos

| tipo | guarda |
|---|---|
| `date` | um dia. Sem hora, sem fuso |
| `time` | uma hora do dia, sem dia e sem fuso |
| `timestamp` | uma data e uma hora, **sem fuso** |
| `timestamptz` | um momento no tempo, sem ambiguidade |

## O que `timestamp` de fato guarda

`timestamp` guarda dígitos: `2026-10-25 01:30:00`. Não guarda onde aquilo foi, o que significa que
não identifica um momento.

Isso está bem enquanto todo mundo está num lugar só e nunca mexe no relógio. Aí o horário de verão
acaba, e na maior parte da Europa `01:30` acontece **duas vezes** naquela madrugada de domingo — uma
em UTC+01:00 e outra uma hora depois em UTC+00:00. Dois momentos diferentes, os mesmos dígitos, sem
jeito de distinguir. Ordene uma lista deles e a ordem está errada. Subtraia dois e o intervalo erra
em uma hora.

E quando alguém implanta a mesma aplicação num segundo país, todo `timestamp` já guardado vira
ambíguo retroativamente, porque nada registrou que fuso ele queria dizer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 282\" role=\"img\" aria-label=\"Uma linha do tempo absoluto em UTC, marcada de meia-noite e meia até duas e meia. Dois pontos acesos ficam sobre ela com uma hora de distância, à uma e à uma e meia UTC, e cada um desce até uma caixa com o mesmo horário de relógio de parede, uma e meia, um em mais um e outro em mais zero. Embaixo, dois painéis: timestamp, guardando os dígitos 2026-10-25 01:30:00 e lugar nenhum; e timestamptz, guardando 2026-10-25 00:30:00 mais zero, um momento convertido na saída.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">No domingo os relógios voltam em boa parte da Europa. Uma leitura de relógio de parede, dois momentos diferentes, uma hora entre eles.</text><text x=\"14\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo absoluto, em UTC</text><path d=\"M14 76 L706 76\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M60 70 L60 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"60\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">00:30</text><path d=\"M200 70 L200 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"200\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">01:00</text><path d=\"M340 70 L340 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"340\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">01:30</text><path d=\"M480 70 L480 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"480\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">02:00</text><path d=\"M620 70 L620 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"620\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">02:30</text><circle cx=\"200\" cy=\"76\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"140\" y=\"112\" width=\"120\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">01:30 local</text><text x=\"200\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">UTC+01:00</text><path d=\"M200 82 L200 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><circle cx=\"340\" cy=\"76\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"280\" y=\"112\" width=\"120\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"340\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">01:30 local</text><text x=\"340\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">UTC+00:00</text><path d=\"M340 82 L340 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><rect x=\"14\" y=\"176\" width=\"330\" height=\"74\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"28\" y=\"194\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">timestamp</text><text x=\"28\" y=\"214\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">'2026-10-25 01:30:00'</text><text x=\"28\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dígitos, e lugar nenhum</text><rect x=\"376\" y=\"176\" width=\"330\" height=\"74\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"194\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">timestamptz</text><text x=\"390\" y=\"214\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">'2026-10-25 00:30:00+00'</text><text x=\"390\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um momento, convertido na saída</text><text x=\"14\" y=\"270\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ordene uma coluna do primeiro tipo e a ordem sai errada; subtraia duas e o intervalo sai uma hora fora. Nada denuncia nenhum dos dois.</text></svg>", "caption": "Os dois pontos são momentos diferentes. O tipo da esquerda não tem como distingui-los, e o dia em que isso importa é um dia em que ninguém está olhando."}
```

## O que `timestamptz` guarda

Apesar do nome, **ele não guarda um fuso**. Guarda um momento absoluto — internamente UTC — e
converte na entrada e na saída usando o fuso da sessão:

```sql
SET TIME ZONE 'Europe/Lisbon';
INSERT INTO invoices (paid_at) VALUES ('2026-10-25 01:30:00');

SET TIME ZONE 'UTC';
SELECT paid_at FROM invoices;
```

```
        paid_at
------------------------
 2026-10-25 00:30:00+00
```

O mesmo instante, escrito do jeito que o leitor pediu. É esse o recurso inteiro: **o momento é
guardado uma vez, e cada leitor o vê nos termos dele.** Comparações, ordenação e aritmética ficam
todas corretas porque acontecem sobre o valor absoluto.

O custo é que você precisa saber qual é o fuso da sessão quando uma string pelada chega. Diga
explicitamente e a ambiguidade some:

```sql
INSERT INTO invoices (paid_at) VALUES ('2026-10-25 01:30:00+01');
```

## Quando `date` é certo, e quando é erro

`date` é correto quando a coisa genuinamente não tem hora nem fuso: uma data de nascimento, a data
de uma fatura, um feriado. Um aniversário é o mesmo dia em todo lugar, e guardá-lo como momento faz
alguém nascer um dia antes em outro fuso.

É erro quando a coisa é um momento que alguém arredondou para um dia por conveniência.
`delivered_on date` perde a informação de que uma encomenda chegou às 23:50 e não às 00:10 — e a
diferença decide em que relatório diário ela cai.

O teste é o mesmo de todo este curso: **alguém registrou um dia, ou algo aconteceu num instante e
foi truncado?**

## `now()` e seus vários significados

```sql
SELECT now();                    -- timestamptz, do início da TRANSAÇÃO
SELECT clock_timestamp();        -- timestamptz, de agora mesmo, andando
SELECT current_date;             -- date, no fuso da sessão
SELECT current_timestamp;        -- a grafia padrão de now()
```

**`now()` é o instante em que a transação começou e não anda durante ela.** Isso é recurso: toda
linha inserida por uma transação recebe o mesmo timestamp, então um lote é coerente. Se você quer o
relógio de parede de verdade dentro de uma transação longa, `clock_timestamp()` é o que anda.

`current_date` depende do fuso da sessão, o que significa que um job rodando às 23:30 em Lisboa e um
job rodando no mesmo instante configurado como UTC escrevem **datas diferentes**. Para qualquer
coisa que precise concordar, guarde o momento e derive o dia no ponto em que alguém lê.

## Intervalos, e a aritmética

```sql
SELECT paid_at - issued_on::timestamptz AS took FROM invoices;   -- um interval
SELECT now() + interval '30 days';
SELECT date_trunc('month', issued_on);
```

`interval` é um tipo: `'1 mon 3 days 04:00:00'`. E não é uma quantidade fixa, que é a surpresa:

```sql
SELECT '2026-01-31'::date + interval '1 month';   -- 2026-02-28
SELECT '2026-03-29 00:00'::timestamptz + interval '1 day';
SELECT '2026-03-29 00:00'::timestamptz + interval '24 hours';
```

Os dois últimos podem diferir em uma hora atravessando uma fronteira de horário de verão, porque
*um dia* e *24 horas* são coisas diferentes. Isso é comportamento correto e pega todo mundo uma vez.

## O resumo, como regra que você aplica sem pensar

- **Um momento que aconteceu** → `timestamptz`.
- **Um dia de calendário que alguém escolheu** → `date`.
- **Uma duração** → `interval`, ou um inteiro com a unidade no nome da coluna
  (`timeout_seconds`).
- **`timestamp` sem fuso** → só quando você está deliberadamente guardando uma leitura de relógio
  local que não é um momento, como "a loja abre às 09:00" no fuso em que a loja está. É raro, e você
  deve saber dizer por quê.
