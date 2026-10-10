---
title: Os intervalos dentro de um incidente
version: 1
---

Uma linha do tempo não é só uma história. Marcada como a seção anterior sugere, ela é dado, e os intervalos entre seus momentos dizem para onde foi o tempo, do jeito que as colunas da aula 2 diziam para onde foi o tempo de um item. **Salve o programa abaixo como `timeline.py`**; a linha do tempo do escriba de 30 de setembro está escrita dentro dele.

```schooling-example
{
  "language": "python",
  "file": "timeline.py",
  "parts": [
    {
      "code": "\"\"\"timeline.py: the scribe's timeline of 30 September, and the intervals inside it.\"\"\"\n\n# Written by the scribe during the incident, one line per event, in local time.\nTIMELINE = \"\"\"\n17:20 change   D047 deployed: BIL-218, BIL-223, BIL-224, BIL-225\n17:21 impact   first duplicate charge, found later in the payment logs\n17:38 detect   a shop owner calls support: charged twice for her subscription\n17:41 report   Lia (support) posts in the team channel with the shop and both charge ids\n17:44 ack      Rafa (on call) acknowledges; finds 11 more duplicates\n17:46 declare  incident declared, SEV2, channel #inc-0930-double-charge\n17:49 roles    Bia IC, Rafa technical lead, Duda scribe, Caio communications\n17:53 severity raised to SEV1: 140 duplicate charges and rising\n17:55 comms    status page notice; support given a sentence for callers\n18:02 decide   roll back D047 now; find the faulty change afterwards\n18:04 action   rollback started\n18:15 restore  rollback complete; no duplicate charge after 18:15\n18:20 action   query: 212 duplicate charges across 167 shops\n18:40 action   refunds of the duplicates start, in batches of 50\n21:10 resolve  all 212 duplicates refunded; incident closed\n21:15 comms    final update; postmortem booked for Friday 2 October\n\"\"\"\n\n",
      "note": "**A linha do tempo é o dado**, digitada no programa como o escriba a escreveu: um horário, um tipo de evento, e o que aconteceu. Os tipos são um vocabulário pequeno e fixo, para um programa achar os momentos que importam."
    },
    {
      "code": "events = {}\nfor line in TIMELINE.strip().splitlines():\n    clock, kind, _ = line.split(maxsplit=2)\n    hours, minutes = clock.split(\":\")\n    events.setdefault(kind, int(hours) * 60 + int(minutes))\n\n",
      "note": "**Cada tipo de evento, e a primeira vez que aparece.** Os horários viram minutos desde a meia-noite para poderem ser subtraídos."
    },
    {
      "code": "phases = [(\"impact\", \"detect\", \"until anybody noticed\"),\n          (\"detect\", \"declare\", \"until an incident was declared\"),\n          (\"declare\", \"decide\", \"until the decision to roll back\"),\n          (\"decide\", \"restore\", \"until service was restored\"),\n          (\"restore\", \"resolve\", \"until every shop was refunded\")]\nstart = events[\"impact\"]\nfor a, b, label in phases:\n    print(f\"{events[b] - events[a]:4} min  {label}\")\nprint(f\"{events['restore'] - start:4} min  from the first duplicate charge to restored\")\nprint(f\"{events['resolve'] - start:4} min  from the first duplicate charge to resolved\")\n",
      "note": "**Os intervalos entre os momentos**: quanto tempo cada fase do incidente levou, e os dois totais que um relatório citaria."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 timeline.py
  17 min  until anybody noticed
   8 min  until an incident was declared
  16 min  until the decision to roll back
  13 min  until service was restored
 175 min  until every shop was refunded
  54 min  from the first duplicate charge to restored
 229 min  from the first duplicate charge to resolved
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 220\" role=\"img\" data-fig=\"l14-phases\" aria-label=\"Uma linha do tempo do incidente de 30 de setembro, das 17h21 às 21h10, em fases: 17 minutos sem ninguém saber, 8 até declarar, 16 até decidir, 13 até restaurar com o rollback, e 175 até estornar cada loja. As lojas foram prejudicadas nos primeiros 54 minutos.\"><path d=\"M30.0 80.0 L76.0 80.0 L76.0 114.0 L30.0 114.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><path d=\"M53.0 78.0 L53.0 36.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"50.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ninguém sabia: 17 min</text><path d=\"M76.0 80.0 L97.7 80.0 L97.7 114.0 L76.0 114.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><path d=\"M86.9 78.0 L86.9 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.9\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">até declarar: 8 min</text><path d=\"M97.7 80.0 L141.0 80.0 L141.0 114.0 L97.7 114.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><path d=\"M119.3 78.0 L119.3 68.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"116.3\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">até decidir: 16 min</text><path d=\"M141.0 80.0 L176.2 80.0 L176.2 114.0 L141.0 114.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><path d=\"M158.6 116.0 L158.6 134.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"155.6\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">rollback: 13 min</text><path d=\"M176.2 80.0 L650.0 80.0 L650.0 114.0 L176.2 114.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"413.1\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estornando cada loja: 175 min</text><path d=\"M30.0 118.0 L30.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"30.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">17:21</text><path d=\"M176.2 118.0 L176.2 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"176.2\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18:15</text><path d=\"M650.0 118.0 L650.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"650.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21:10</text><text x=\"34.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lojas sendo cobradas em dobro</text><path d=\"M30.0 188.0 L176.2 188.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"650.0\" y=\"20.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o incidente de 30 de setembro, fase a fase</text></svg>", "caption": "Restaurar levou menos de uma hora e resolver levou quatro. O DORA conta a primeira; as lojas viveram as duas.", "same": ["rollback: 13 min"]}
```

## Lendo as fases

**Dezessete minutos até alguém perceber**, e quem percebeu foi um cliente ao telefone. Dos 54 minutos em que as lojas foram cobradas em dobro, quase um terço passou antes de o time saber. Nenhuma rapidez na resposta recuperaria esses minutos; só a detecção pode, e a aula 18 pergunta que alerta teria pegado isso.

**Oito minutos para declarar** é rápido. Lia perguntou em até três minutos depois da ligação, e Rafa declarou dois minutos depois de confirmar o recebimento. Um time que espera ter certeza, o alerta da aula 13, normalmente perde mais aqui do que em qualquer outro lugar.

**Dezesseis minutos para decidir** é onde a resposta poderia ter sido mais rápida. A maior parte foi gasta confirmando qual mudança era a culpada, coisa que um rollback não precisa saber. **Mitigar primeiro** teria economizado talvez dez minutos; num produto de pagamentos, dez minutos são muitas cobranças duplicadas.

**Treze minutos para restaurar** é o que um release pequeno compra: o rollback em si levou onze deles.

**175 minutos para resolver** é a limpeza, e é de longe a fase mais longa. Ela é invisível no tempo para restaurar da DORA e é a parte que as lojas mais sentiram, porque um estorno levou horas para chegar a cada uma delas.

## Nomes, e um alerta sobre médias

Esses intervalos têm nomes comuns, normalmente com *mean time to* na frente: **tempo para detectar**, **tempo para reconhecer**, **tempo para mitigar**, **tempo para resolver**. São úteis desde que as fases de cada incidente sejam mantidas. Tirada a média entre incidentes num "MTTR", eles se comportam como o tempo de ciclo médio da aula 2: um incidente longo domina, a forma desaparece, e o número não descreve nenhum incidente que tenha acontecido. **Olhe as fases de cada incidente sério, e a distribuição entre incidentes, antes de citar uma média.**
