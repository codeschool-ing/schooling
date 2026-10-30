---
title: O ponto de equilíbrio entre bytes e slots
version: 1
---

**Sob demanda e slots custam o mesmo quando um TiB de consultas usa um certo número de slot-horas, e os
dois preços fixam esse número.** Sob demanda cobra 11,25 USD por TiB. Uma slot-hora Enterprise custa
0,093 USD. Então uma carga que usa 11,25 ÷ 0,093, cerca de 121 slot-horas para cada TiB que lê, custa o
mesmo dos dois jeitos. **Uma carga que precisa de mais computação por byte do que isso** sai mais
barata sob demanda, porque sob demanda não cobra nada pela computação. **Uma carga que precisa de
menos** sai mais barata em slots, porque slots não cobram nada pelos bytes.

Essa razão, slot-horas por TiB, é o número que se precisa saber de uma carga, e não é o número em que
alguém pensa primeiro. As pessoas comparam os totais do mês, e os totais não dizem por que um modelo
ganhou.

## O programa

Salve isto como `~/gcp/breakeven.py`:

```schooling-example
{"language": "python", "file": "breakeven.py", "parts": [{"code": "import sys\n\n# USD, southamerica-east1, cloud.google.com/bigquery/pricing, read 2026-10-30\nON_DEMAND_PER_TIB, FREE_TIB = 11.25, 1\nAUTOSCALED = {'Standard': 0.062, 'Enterprise': 0.093, 'Enterprise Plus': 0.155}\nCOMMITTED = {'Enterprise, 1 year': 0.0744, 'Enterprise, 3 years': 0.0558}\nHOURS, SMALLEST = 730, 50\n\n", "note": "**Todo preço é o da página, para São Paulo.** As três edições na tarifa sem compromisso, os dois compromissos do Enterprise e o TiB gratuito das consultas sob demanda. Um mês são 730 horas, a convenção da própria página: 0,093 × 730 são os 67,89 USD por mês que ela imprime para um slot Enterprise. 50 slots é o menor compromisso que a página permite."}, {"code": "tib, slot_hours = float(sys.argv[1]), float(sys.argv[2])\nprint(f'a month of {tib:,g} TiB billed, using {slot_hours:,g} slot-hours')\nprint(f'  {\"on demand\":<31}{max(tib - FREE_TIB, 0) * ON_DEMAND_PER_TIB:>10,.2f} USD')\n", "note": "**Um mês de trabalho são dois números**: os TiB que as consultas teriam cobrados sob demanda e as slot-horas que usariam em slots. Nenhum dos dois dá para medir aqui. Num projeto real os dois estão na view `INFORMATION_SCHEMA.JOBS`, uma linha por consulta, como `total_bytes_billed` e `total_slot_ms`. Sob demanda subtrai o TiB gratuito e multiplica."}, {"code": "for name, price in AUTOSCALED.items():\n    tie = ON_DEMAND_PER_TIB / price\n    print(f'  {name + \", autoscaled\":<31}{slot_hours * price:>10,.2f} USD'\n          f'   same as on demand at {tie:,.0f} slot-hours a TiB')\n", "note": "**Slots com autoscaling custam as slot-horas vezes o preço**, sem nada reservado. `tie` é o número de que esta seção inteira trata: quantas slot-horas um TiB de consultas pode usar antes de os slots custarem mais do que ler esse TiB sob demanda. Ele só depende dos dois preços."}, {"code": "for name, price in COMMITTED.items():\n    print(f'  {name + \", 50 slots\":<31}{SMALLEST * HOURS * price:>10,.2f} USD'\n          f'   {SMALLEST * HOURS:,} slot-hours, used or not')\n", "note": "**Um compromisso é pago por toda hora do mês**, façam as consultas o que fizerem, então ele aparece como o custo do menor possível. Ele só sai mais barato por slot-hora quando os slots dele estão ocupados."}]}
```

**Os dois números de um mês real vêm de `INFORMATION_SCHEMA.JOBS`**, e neste laboratório não vêm de
lugar nenhum: uma consulta do DuckDB não tem slots nem bytes cobrados. Então os dois meses abaixo são
declarados, não medidos. O primeiro são as analistas da Quitanda: perguntas avulsas com joins, funções
de janela e trabalho com texto, 3 TiB cobrados e 600 slot-horas, 200 por TiB. O segundo são as
transformações noturnas: varreduras largas que filtram e somam, 40 TiB cobrados e 2.500 slot-horas,
cerca de 62 por TiB.

```
ana@laptop:~/gcp$ python3 breakeven.py 3 600
a month of 3 TiB billed, using 600 slot-hours
  on demand                           22.50 USD
  Standard, autoscaled                37.20 USD   same as on demand at 181 slot-hours a TiB
  Enterprise, autoscaled              55.80 USD   same as on demand at 121 slot-hours a TiB
  Enterprise Plus, autoscaled         93.00 USD   same as on demand at 73 slot-hours a TiB
  Enterprise, 1 year, 50 slots     2,715.60 USD   36,500 slot-hours, used or not
  Enterprise, 3 years, 50 slots    2,036.70 USD   36,500 slot-hours, used or not
ana@laptop:~/gcp$ python3 breakeven.py 40 2500
a month of 40 TiB billed, using 2,500 slot-hours
  on demand                          438.75 USD
  Standard, autoscaled               155.00 USD   same as on demand at 181 slot-hours a TiB
  Enterprise, autoscaled             232.50 USD   same as on demand at 121 slot-hours a TiB
  Enterprise Plus, autoscaled        387.50 USD   same as on demand at 73 slot-hours a TiB
  Enterprise, 1 year, 50 slots     2,715.60 USD   36,500 slot-hours, used or not
  Enterprise, 3 years, 50 slots    2,036.70 USD   36,500 slot-hours, used or not
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um gráfico do custo por TiB lido contra as slot-horas usadas por TiB, de 0 a 250. Sob demanda é uma linha reta em 11,25 USD. Standard, Enterprise e Enterprise Plus são linhas que sobem do zero a 0,062, 0,093 e 0,155 USD por slot-hora, cruzando a reta em 181, 121 e 73 slot-horas por TiB. Duas marcas: as transformações noturnas em cerca de 62, onde toda edição fica abaixo da reta, e as analistas em 200, onde toda edição fica acima.\" data-fig=\"l14-tie\"><polyline points=\"80,280 680,280\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></polyline><polyline points=\"80,280 80,40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></polyline><text x=\"80.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"200.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><text x=\"320.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><text x=\"440.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150</text><text x=\"560.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><text x=\"680.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">250</text><text x=\"72\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"184.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"72\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><text x=\"380.0\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slot-horas usadas por TiB lido</text><text x=\"80\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD por TiB lido</text><polyline points=\"80.0,172.0 680.0,172.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></polyline><text x=\"680.0\" y=\"186.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sob demanda, 11,25</text><polyline points=\"80.0,280.0 467.09677419354836,40.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></polyline><text x=\"463.09677419354836\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Enterprise Plus</text><polyline points=\"255.2,172.0 255.2,280\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"3 3\"></polyline><text x=\"255.2\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">73</text><polyline points=\"80.0,280.0 680.0,56.79999999999998\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></polyline><text x=\"676.0\" y=\"48.79999999999998\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Enterprise</text><polyline points=\"370.4,172.0 370.4,280\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"3 3\"></polyline><text x=\"370.4\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">121</text><polyline points=\"80.0,280.0 680.0,131.2\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></polyline><text x=\"676.0\" y=\"123.19999999999999\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Standard</text><polyline points=\"514.4,172.0 514.4,280\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"3 3\"></polyline><text x=\"514.4\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">181</text><rect x=\"224.8\" y=\"261.6\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"228.8\" y=\"251.60000000000002\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">transformações, 62</text><rect x=\"556.0\" y=\"261.6\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"251.60000000000002\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">analistas, 200</text></svg>", "caption": "Cada edição cruza o sob demanda no seu próprio número de slot-horas por TiB. À esquerda do cruzamento os slots são mais baratos; à direita, o sob demanda.", "same": ["Standard", "Enterprise", "Enterprise Plus"]}
```

**As analistas saem mais baratas sob demanda, e as transformações saem mais baratas em slots.** Com 200
slot-horas por TiB, as analistas ficam acima de todos os empates menos o do Standard: sob demanda são
22,50 USD, Enterprise com autoscaling 55,80 e Enterprise Plus 93. O Standard, a 37,20, ainda é mais caro
que sob demanda, já que 200 fica acima do empate dele, 181. Com cerca de 62 slot-horas por TiB, as
transformações ficam abaixo de todos os empates: sob demanda são 438,75 USD, Enterprise 232,50 e
Standard 155.

**Os compromissos perdem as duas vezes.** Cinquenta slots por um ano custam 2.715,60 USD por mês, e por
três anos 2.036,70, porque um compromisso são 36.500 slot-horas, alguém use ou não. As analistas usaram
600 e as transformações 2.500. Um compromisso só ganha numa carga que mantém os slots ocupados a maior
parte do mês, e a Quitanda não tem nenhuma: o warehouse dela trabalha à noite e no horário comercial e
fica parado no resto.

## Escolher, na ordem que a conta sugere

**Comece sob demanda.** Não custa nada até uma consulta rodar, o primeiro TiB é gratuito, e é o único
modelo cuja conta dá para prever antes de a consulta rodar: o dry run da aula 16 imprime os bytes. Para
uma empresa pequena com um warehouse pequeno, é o modelo certo por muito tempo, e a tabela de pedidos da
Quitanda, na aula 13, é uma tabela em que quase toda consulta custa o mínimo de 10 MB.

**Passe uma carga para slots quando as slot-horas por TiB dela ficarem bem abaixo do empate**, que é o
formato das grandes varreduras com pouca computação por byte, ou quando os 2.000 slots divididos do sob
demanda deixarem de bastar para as consultas que importam. Passe por projeto, com uma atribuição, e
deixe o resto sob demanda: as analistas e as transformações não precisam dividir um modelo.

**Use a edição que os recursos exigem, e nenhuma acima.** Os empates caem conforme a edição sobe, 181
para o Standard, 121 para o Enterprise e 73 para o Enterprise Plus, então cada edição acima do que a
carga precisa faz os slots perderem para o sob demanda mais cedo.

**Comprometa-se por último, e só com o piso.** Um compromisso para a baseline que fica ocupada o mês
inteiro, com autoscaling acima dela, sai mais barato que fazer autoscaling de tudo; um compromisso do
tamanho do pico são os 100 slots da seção de edições, pagos às três da tarde de um domingo.
