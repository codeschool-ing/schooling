---
title: Uma corrente e um par
version: 1
---

Uma requisição para `www.example.com` no laboratório atravessa várias coisas em fila: o roteador do
provedor, o servidor DNS que transforma o nome em endereço, um balanceador de carga e um servidor web.
**Partes em série se multiplicam.** A requisição só dá certo se todas estiverem no ar, então a
disponibilidade da corrente é o produto das delas, e um produto de números menores que um fica abaixo do
menor deles. Quatro partes de 99,9% cada dão 99,6%, antes de acontecer qualquer coisa fora do comum.

**Partes em paralelo multiplicam as falhas.** Dois balanceadores, qualquer um dos quais dá conta da carga,
só ficam fora juntos quando os dois caem ao mesmo tempo. Se cada um fica fora 0,1% do tempo, os dois ficam
fora 0,1% de 0,1%, um milionésimo.

Este programa aplica as duas regras ao data center do laboratório. As disponibilidades nele são
suposições, números redondos para uma máquina de cada tipo, e não medidas de nada do laboratório:

```schooling-example
{"language": "python", "file": "chain.py", "parts": [{"code": "def series(*parts):\n    \"\"\"Every part has to be up: multiply.\"\"\"\n    up = 1.0\n    for p in parts:\n        up *= p\n    return up", "note": "Em série a requisição precisa de todas as partes, então as disponibilidades se multiplicam, e o resultado fica abaixo da mais fraca."}, {"code": "def parallel(*parts):\n    \"\"\"Any one part is enough: it is down only when all of them are.\"\"\"\n    down = 1.0\n    for p in parts:\n        down *= 1 - p\n    return 1 - down", "note": "Em paralelo são as indisponibilidades que se multiplicam. Duas partes fora do ar 0,1% do tempo ficam fora juntas 0,0001% dele, se nada liga as falhas delas."}, {"code": "YEAR_MIN = 365 * 24 * 60\nisp, dns, lb, web = 0.999, 0.999, 0.999, 0.99  # assumed, one machine each", "note": "Suposições, não medidas: três noves para um roteador, um servidor DNS ou um balanceador, dois noves para um servidor web com o software e as implantações dele."}, {"code": "designs = {\n    \"one of everything\": series(isp, dns, lb, web),\n    \"two lb, three web\": series(isp, dns, parallel(lb, lb), parallel(web, web, web)),\n    \"and two isp, two dns\": series(parallel(isp, isp), parallel(dns, dns),\n                                   parallel(lb, lb), parallel(web, web, web)),\n}", "note": "Três projetos do mesmo site. Um projeto é uma série de etapas, e cada etapa é uma parte só ou um grupo em paralelo de partes iguais."}, {"code": "for name, up in designs.items():\n    print(f\"{name:21} {up:.5%}  {(1 - up) * YEAR_MIN:7.1f} min down a year\")", "note": "Cada projeto como porcentagem e como os minutos por ano que ficaria fora do ar."}], "output": "one of everything     98.70330%   6815.5 min down a year\ntwo lb, three web     99.79990%   1051.7 min down a year\nand two isp, two dns  99.99960%      2.1 min down a year"}
```

A saída mostra três coisas. Dobrar os balanceadores e triplicar os servidores web levou o tempo fora do ar
de 6815,5 minutos por ano para 1051,7. Os 1051,7 que sobram são quase todos do enlace do provedor e do
servidor DNS, que continuam únicos: **a parte em série mais fraca define o teto**, por mais que se gaste
nas partes ao lado dela. Só quando essas duas também são dobradas o número cai para 2,1 minutos.

E nesse último número não se deve acreditar. A fórmula de um par supõe que os dois falham de forma
**independente**, como se o único jeito de os dois quebrarem juntos fosse coincidência. Pares de verdade
dividem coisas: a mesma alimentação elétrica, o mesmo switch, a mesma versão de software com o mesmo bug,
a mesma configuração aplicada nos dois pela mesma pessoa no mesmo minuto. Uma falha que derruba os dois de
uma vez é uma **falha de modo comum**, e é por isso que dois servidores num mesmo rack se comportam mais
como um servidor só do que a aritmética diz.

Então a fórmula dá o melhor caso, e o trabalho de projeto é fazer o caso real chegar perto dele:

| o que é compartilhado | como é separá-lo |
|---|---|
| energia | duas fontes por máquina, em dois circuitos, atrás de dois nobreaks |
| a rede | o par em dois switches, o site em dois provedores cujos cabos não dividem o mesmo duto |
| o lugar | um segundo rack, sala ou site, longe o bastante para um incêndio ou uma enchente não pegar os dois |
| software | atualizar um gêmeo, esperar, depois o outro |
| pessoas | uma mudança aplicada num lado e conferida antes do outro |

As duas últimas linhas são de onde as quedas de verdade vêm, e nenhuma quantidade de hardware ajuda com
elas. **Um par que recebe toda mudança no mesmo instante é uma máquina só com dois cabos de força.**
