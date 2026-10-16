---
title: Eficiência hospitalar: leitos, permanência e o hospital lotado
version: 1
---

O Hospital Jacarandá é um hospital geral de Campinas com 240 leitos e um pronto-socorro que nunca
fecha. Ele é inventado, como a Varanda, e todo número desta aula também. A analista de dados do
hospital, Débora Kato, responde à diretoria clínica e ao financeiro, e as perguntas que recebe se
encaixam nas quatro perguntas da aula 17 assim:

| a pergunta da aula 17 | num hospital |
|---|---|
| as decisões tomadas sem parar | para onde vai o próximo paciente, quantos enfermeiros cada turno precisa, que leitos e salas cirúrgicas abrir, quais pacientes podem ter alta hoje |
| os indicadores que servem a elas | taxa de ocupação de leitos, tempo médio de permanência, giro de leitos, tempo de espera no pronto-socorro, reinternações em 30 dias; para uma região, taxas por 100 mil habitantes |
| os dados, e o que eles têm de estranho | são escritos para cuidar do paciente e para receber por isso, não para análise; e **quase tudo neles é dado pessoal sensível** |
| a armadilha típica | uma média entre alas, pacientes ou cidades que esconde o lugar onde está o problema |

## Três indicadores a partir de um mês

O hospital conta seus pacientes à meia-noite. **Um paciente num leito na contagem da meia-noite é um
paciente-dia**, e os pacientes-dia do mês contra os leitos disponíveis são o número mais vigiado do
hospital. Digite o novembro de 2025 do Jacarandá, por ala:

| | A | B | C |
|---|---|---|---|
| 1 | Ala | Leitos | Pacientes-dia |
| 2 | Clínica médica | 96 | 2736 |
| 3 | Cirúrgica | 64 | 1670 |
| 4 | UTI | 20 | 591 |
| 5 | Maternidade | 32 | 598 |
| 6 | Pediatria | 28 | 543 |

Novembro tem 30 dias, então cada leito oferece 30 leitos-dia. Em D2, copiado para baixo, e a
**taxa de ocupação** em E2:

```localised
=B2*30      2880
=ARRED(C2/D2*100;1)      95
```

Na linha 7, os totais do hospital, `=SOMA(B2:B6)` e o mesmo para C e D, e a ocupação dele:

```localised
=SOMA(C2:C6)      6138
=SOMA(D2:D6)      7200
=ARRED(C7/D7*100;1)      85,3
```

O hospital deu alta a 1.365 pacientes em novembro. Digite isso em B8. O **tempo médio de
permanência** é pacientes-dia por alta, e o **giro de leitos** é altas por leito no período:

```localised
=ARRED(C7/B8;1)      4,5
=ARRED(B8/B7;1)      5,7
```

Um paciente ficou em média 4,5 dias, e cada leito recebeu 5,7 pacientes no mês.

## Por que a média fica num lugar confortável

85,3% é o número que vai para o relatório mensal, e ele parece sensato: a maioria dos leitos
ocupada, alguns de folga. **Copie E2 para baixo e o hospital se divide em dois hospitais.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Barras horizontais de ocupação de leitos em novembro de 2025 em cinco alas, contra uma linha tracejada na média do hospital, 85,3%: UTI 98,5%, clínica médica 95,0%, cirúrgica 87,0%, pediatria 64,6%, maternidade 62,3%.\" data-fig=\"l19-occupancy\"><text x=\"170.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">leitos ocupados à meia-noite, média de novembro de 2025</text><text x=\"158.0\" y=\"62.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">UTI</text><path d=\"M170.0 46.0 H633.0 V70.0 H170.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"641.0\" y=\"62.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">98,5%</text><text x=\"158.0\" y=\"102.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Clínica médica</text><path d=\"M170.0 86.0 H616.5 V110.0 H170.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"624.5\" y=\"102.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">95,0%</text><text x=\"158.0\" y=\"142.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Cirúrgica</text><path d=\"M170.0 126.0 H578.9 V150.0 H170.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"586.9\" y=\"142.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">87,0%</text><text x=\"158.0\" y=\"182.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pediatria</text><path d=\"M170.0 166.0 H473.6 V190.0 H170.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"481.6\" y=\"182.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">64,6%</text><text x=\"158.0\" y=\"222.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Maternidade</text><path d=\"M170.0 206.0 H462.8 V230.0 H170.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"470.8\" y=\"222.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">62,3%</text><path d=\"M570.9 34 L570.9 244\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></path><text x=\"570.9\" y=\"262.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">hospital 85,3%</text><path d=\"M170.0 34.0 L170.0 244.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M170.0 274.0 H180.0 V284.0 H170.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"186.0\" y=\"284.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">acima de 90%, onde um paciente a mais não tem para onde ir</text></svg>", "caption": "O mesmo mês por ala. A média do hospital fica num lugar confortável, enquanto duas alas estão cheias e outras duas têm um terço dos leitos vazios."}
```

A UTI rodou a 98,5%: dos seus 20 leitos, 19,7 estavam ocupados numa noite média. A clínica médica
rodou a 95,0%. A maternidade e a pediatria ficaram com um terço dos leitos vazios. A média é uma
mistura ponderada de alas cheias e alas vazias, e ninguém é internado na média. O paciente que
precisa de UTI às duas da manhã precisa de um daqueles 20 leitos, e os 12 leitos vazios da
maternidade não servem para nada a ele.

## Por que 100% é um fracasso

Numa loja, a prateleira que vende tudo é uma ruptura (aula 18). Num hospital, uma ala a 100% é
pior: **a próxima emergência não tem para onde ir**. As internações não se espalham por igual no
mês; segundas-feiras e semanas de inverno trazem mais. Uma ala com média de 98,5% fica cheia em
muitas noites. Nessas noites, o pronto-socorro mantém pacientes já internados em macas, cirurgias
são canceladas para liberar leitos e pacientes vão para qualquer ala que tenha vaga, onde a
enfermagem conhece menos a doença deles.

Por isso um hospital não mira em 100%. Um número que planejadores costumam citar é de cerca de 85%
para leitos gerais, acima do qual noites lotadas começam a ficar comuns. É uma regra de trabalho, e
não uma lei, e o nível certo depende de quanto variam as internações de cada ala: uma maternidade
com partos agendados aguenta ficar mais cheia que uma clínica médica que recebe emergências. **O
que a regra diz é que a ocupação tem um teto bem abaixo de 100%**, o contrário da maioria dos
indicadores deste curso, em que mais do que se mede é melhor.

## Permanência menor, com uma proteção

O tempo de permanência puxa para o outro lado. Se os pacientes da clínica médica ficassem meio dia
a menos, os mesmos leitos receberiam mais pacientes, e os 95% cairiam. Isso faz do tempo médio de
permanência uma meta que os hospitais gostam de cortar, e uma meta com um jeito óbvio de ser
burlada: mandar o paciente para casa antes da hora. **A proteção é a taxa de reinternação**, a
parcela dos pacientes que voltam em até 30 dias, que a próxima seção mede. É o par de
contramétricas da aula 11 aplicado a um hospital: o indicador que você empurra, e o que mostra
quando você empurrou demais.
