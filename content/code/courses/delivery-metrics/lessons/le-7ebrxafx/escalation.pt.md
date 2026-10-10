---
title: A escalada, e o especialista que todo mundo chama
version: 1
---

Uma **política de escalada** diz o que acontece quando um acionamento não é atendido, ou quando quem atendeu não consegue resolver. Ela tem duas direções, e os times que as confundem acabam com a pessoa errada acordada.

## Para cima na cadeia quando ninguém atende

A primeira direção é mecânica, e a ferramenta de acionamento a faz sozinha:

| depois de | o acionamento vai para |
|---|---|
| 0 minutos | o primário |
| 5 minutos sem reconhecimento | o secundário |
| 15 minutos sem reconhecimento | a tech lead |

Os tempos são curtos porque se somam: um incidente que precisa de dois acionamentos perdidos antes que alguém olhe para ele já perdeu um quarto de hora, que é mais ou menos o que o time de Billing perdeu em 30 de setembro esperando um lojista ligar. Cinco minutos bastam para achar um celular e são pouco o bastante para que um sono pesado não seja a única proteção.

## Para o lado, para quem sabe

A segunda direção é um julgamento. O primário reconheceu, olhou e achou um problema num código que não conhece bem. Ele pode **passá-lo para quem conhece**, e todo time tem uma pessoa assim. No time de Billing é o Rafa, que escreveu a maior parte do código de cartão.

Passar um problema difícil ao especialista é a decisão certa durante um incidente. Fazer isso toda vez, por meses, tem um custo que ninguém registra, porque a escala mostra o Rafa de plantão uma semana em cinco e o pager mostra outra coisa.

## O que o pager mostra

**Salve o programa abaixo como `oncall.py`.** Ele escreve um trimestre de acionamentos do time de Billing, treze semanas a partir de 8 de julho, e conta quem cada acionamento acordou.

```schooling-example
{
  "language": "python",
  "file": "oncall.py",
  "parts": [
    {
      "code": "\"\"\"oncall.py: who the pager woke, over a quarter of the Billing team's rota.\"\"\"\nimport random\nfrom collections import Counter\nfrom datetime import datetime, timedelta\n\nROTA = [\"Duda\", \"Ines\", \"Rafa\", \"Teo\", \"Caio\"]        # one week each, in turn\nEXPERT = \"Rafa\"                                       # wrote most of the card code\nrng = random.Random(13)\n\n# Thirteen weeks from Wednesday 8 July, the handover day. Each day brings some pages at\n# random hours, more in the last days of the month; a page about the card provider is\n# passed to Rafa when Rafa is not the one on call, because nobody else knows that code.\npages = []\nfor week in range(13):\n    start = datetime(2026, 7, 8) + timedelta(weeks=week)\n    on_call = ROTA[week % len(ROTA)]\n    for day in range(7):\n        when = start + timedelta(days=day)\n        for _ in range(rng.choice([0, 0, 0, 1, 1, 2] if when.day < 25 else [1, 2, 3])):\n            at = when + timedelta(minutes=rng.randrange(24 * 60))\n            card = rng.random() < 0.4\n            pages.append((at, on_call, EXPERT if card and on_call != EXPERT else None))\n\n",
      "note": "**A escala e os acionamentos, escritos pelo programa.** Cinco pessoas ficam uma semana cada, com troca de plantão às quartas. Todo dia traz até dois acionamentos em horas aleatórias, e até três na última semana do mês, quando as lojas fecham as contas. Quatro acionamentos em dez são sobre o provedor de cartão, e esses são passados ao Rafa sempre que outra pessoa está com o pager."
    },
    {
      "code": "woken, nights, passed = Counter(), Counter(), Counter()\nfor at, on_call, expert in pages:\n    night = at.hour >= 22 or at.hour < 7\n    for person in filter(None, (on_call, expert)):\n        woken[person] += 1\n        nights[person] += night\n    passed[expert] += expert is not None\nprint(f\"{len(pages)} pages in 13 weeks, {sum(1 for p in pages if p[0].hour >= 22 or p[0].hour < 7)} at night\")\nfor person in ROTA:\n    weeks = sum(1 for w in range(13) if ROTA[w % len(ROTA)] == person)\n    print(f\"  {person:5} {weeks} weeks on call  {woken[person]:3} pages  \"\n          f\"{nights[person]:2} at night  {passed[person]:2} passed on by others\")\n",
      "note": "**Quem cada acionamento acordou.** Um acionamento acorda quem está de plantão, e também o Rafa quando foi repassado. O programa conta os acionamentos de cada pessoa, os que caíram entre 22:00 e 07:00, e quantos chegaram a ela vindos da semana de outra pessoa."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 oncall.py
82 pages in 13 weeks, 25 at night
  Duda  3 weeks on call   17 pages   6 at night   0 passed on by others
  Ines  3 weeks on call   21 pages   7 at night   0 passed on by others
  Rafa  3 weeks on call   54 pages  14 at night  29 passed on by others
  Teo   2 weeks on call   13 pages   3 at night   0 passed on by others
  Caio  2 weeks on call    6 pages   3 at night   0 passed on by others
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 270\" role=\"img\" data-fig=\"l17-load\" aria-label=\"Barras horizontais, uma por pessoa da escala do time de Billing, mostrando quantos acionamentos as acordaram em treze semanas. Duda 17, Inês 21, Téo 13 e Caio 6, todos das próprias semanas. Rafa 54: 25 das próprias semanas e 29 repassados das semanas dos outros.\"><text x=\"100.0\" y=\"68.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Duda</text><path d=\"M110.0 58.0 L248.8 58.0 L248.8 78.0 L110.0 78.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"256.8\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">17</text><text x=\"100.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Inês</text><path d=\"M110.0 90.0 L281.5 90.0 L281.5 110.0 L110.0 110.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"289.5\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">21</text><text x=\"100.0\" y=\"132.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rafa</text><path d=\"M110.0 122.0 L314.2 122.0 L314.2 142.0 L110.0 142.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M314.2 122.0 L551.0 122.0 L551.0 142.0 L314.2 142.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"559.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">54</text><text x=\"100.0\" y=\"164.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Téo</text><path d=\"M110.0 154.0 L216.2 154.0 L216.2 174.0 L110.0 174.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"224.2\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">13</text><text x=\"100.0\" y=\"196.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Caio</text><path d=\"M110.0 186.0 L159.0 186.0 L159.0 206.0 L110.0 206.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"167.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><text x=\"110.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"273.3\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"436.7\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><text x=\"600.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M110.0 50.0 L110.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M110.0 250.0 L124.0 250.0 L124.0 260.0 L110.0 260.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"130.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na própria semana de plantão</text><path d=\"M340.0 250.0 L354.0 250.0 L354.0 260.0 L340.0 260.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"360.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">repassado da semana de outra pessoa</text><text x=\"110.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acionamentos que acordaram cada pessoa, de 8 de julho a 6 de outubro</text></svg>", "caption": "A escala divide as semanas por igual. O pager não divide os acionamentos.", "same": ["Caio", "Duda", "Inês", "Rafa", "Téo"]}
```

**O Rafa ficou de plantão três semanas, como a Duda e a Inês, e foi acionado mais do que as duas juntas**: 54 vezes, 29 delas nas semanas de outras pessoas. A escala diz que a carga é dividida por cinco. O pager diz que uma pessoa carrega quase metade dela, e nada na escala jamais mostraria isso.

O programa mostra uma segunda injustiça, mais discreta. O Caio foi acionado 6 vezes e a Inês 21, e nenhum dos dois teve nada a ver com isso: duas das três semanas da Inês, e todas as três do Rafa, incluíram o fim do mês, quando as lojas fecham as contas e os acionamentos vêm de três em três; nenhuma das do Caio incluiu. Uma escala de cinco semanas contra um mês de pouco mais de quatro anda devagar, então o fim do mês cai nas mesmas pessoas por vários meses seguidos antes de mudar. A seção 06 volta às duas coisas.

## Por que o padrão do especialista prejudica todo mundo

- **O especialista nunca descansa.** As semanas fora do plantão são quando as pessoas se recuperam. Um especialista que pode ser chamado toda semana está de plantão toda semana, sem receber por quatro delas.
- **Ninguém mais aprende.** Cada problema passado ao Rafa é um problema que o Caio, a Duda, a Inês e o Téo não precisaram resolver, e por isso não conseguem resolver na próxima vez.
- **O time tem um ponto único de falha.** Na noite em que o Rafa está num avião, ou doente, ou saiu da empresa, o código de cartão não tem ninguém.

## Espalhando o que uma pessoa sabe

A solução não é proibir passar problemas adiante, o que só deixaria os incidentes mais longos. É tornar isso menos necessário:

- **um runbook para cada alerta que aciona alguém**, escrito pelo especialista, dizendo o que o alerta significa e o que tentar primeiro; a aula 18 transforma isso em regra;
- **turnos de sombra**, em que alguém novo carrega o pager ao lado de alguém experiente antes de carregá-lo sozinho;
- **o especialista ajuda numa chamada, sem assumir o controle**, para que a pessoa de plantão digite os comandos e os aprenda;
- **o próximo postmortem pergunta "quem tivemos que acordar, e por quê"**, para que o conhecimento que faltou vire uma ação como qualquer outra.
