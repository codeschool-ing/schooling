---
title: Uma escolha feita do começo ao fim, do perfil à decisão
version: 1
---

As peças desta aula só se pagam quando decidem alguma coisa, então aqui está uma decisão tomada do
começo ao fim. **O caso é inventado e os números dele são um exemplo**; o método é a parte a guardar.

## O caso

Uma loja em São Paulo está tirando a API de pedidos de uma única instância EC2 que a roda há três
anos. Três desenvolvedores cuidam dela. Eles já constroem uma imagem de contêiner da API para os
próprios laptops, o tipo de imagem com que as aulas 8 a 10 trabalham. Mais duas coisas vivem na mesma
máquina: um **relatório de vendas** que um cron monta toda noite, e que leva uns seis minutos, e um
endpoint de **exportação** que o financeiro chama algumas vezes por dia e que responde em até 45
segundos. A conta na AWS foi aberta este ano.

As contagens de requisições do load balancer na semana mais movimentada dão um perfil: um fio de 2
por segundo durante a noite, uma subida a partir das 07:00, um ombro no almoço e um pico à noite de
80 por segundo das 18:00 às 20:00.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"O perfil de requisições da loja em 24 barras: 2 requisições por segundo da meia-noite às 07:00, subindo a 40 no almoço, caindo a 20 à tarde e chegando ao pico de 80 das 18:00 às 20:00, antes de voltar a 2 às 23:00. Duas linhas tracejadas o cruzam: a média da loja, 26,5 por segundo, e abaixo dela o equilíbrio com duas tasks de Fargate, 21,8 por segundo.\"><rect x=\"81.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"106.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"131.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"156.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"181.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"206.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"231.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"256.0\" y=\"205.0\" width=\"23.0\" height=\"25.0\" fill=\"var(--phosphor)\"></rect><rect x=\"281.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"306.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"331.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"356.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"381.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"406.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"431.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"456.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"481.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"506.0\" y=\"80.0\" width=\"23.0\" height=\"150.0\" fill=\"var(--phosphor)\"></rect><rect x=\"531.0\" y=\"30.0\" width=\"23.0\" height=\"200.0\" fill=\"var(--phosphor)\"></rect><rect x=\"556.0\" y=\"30.0\" width=\"23.0\" height=\"200.0\" fill=\"var(--phosphor)\"></rect><rect x=\"581.0\" y=\"80.0\" width=\"23.0\" height=\"150.0\" fill=\"var(--phosphor)\"></rect><rect x=\"606.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"631.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"656.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><path d=\"M80 230 L680 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80 30 L80 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><path d=\"M80 163.8 L680 163.8\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"88\" y=\"155.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a média da loja, 26,5 por segundo</text><path d=\"M80 175.5 L680 175.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"88\" y=\"187.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">equilíbrio com duas tasks, 21,8</text><text x=\"80.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><text x=\"230.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><text x=\"380.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><text x=\"530.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><text x=\"680.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"380.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requisições por segundo, hora a hora</text><text x=\"555.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pico de 80, das 18:00 às 20:00</text><text x=\"167.5\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um fio de 2</text></svg>", "caption": "O pico decide quantas tasks rodam; a média decide a conta do Lambda. A média da loja fica acima do equilíbrio, então as tasks saem mais baratas."}
```

## A aritmética

O perfil entra no `compare.py` como argumento, as 24 taxas a partir da meia-noite:

```
ana@laptop:~/aws$ python3 prices.py | python3 compare.py shop=2,2,2,2,2,2,2,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,2
profile      requests   EC2 c7g.large    Fargate, Arm     Lambda, Arm     App Runner*
shop           69.64M          162.21           49.60           60.36           56.94

Lambda costs what two Fargate tasks cost at 57.23M requests a month, 21.8 a second on average.
* App Runner is priced in us-east-1: it is not offered in sa-east-1.
```

O Fargate é o mais barato, a 49,60 USD por mês, porque o pico de 80 cabe nas duas tasks que o
programa mantém de qualquer jeito. O Lambda custa 60,36: 69,64 milhões de requisições ficam acima do
equilíbrio de 57,23, e a média da loja, 26,5 por segundo, fica acima dos 21,8 da última linha. O App
Runner sairia 56,94, e **o fio de tráfego é o motivo**: duas requisições por segundo às 03:00 mantêm
as instâncias dele ativas a noite toda. O mesmo perfil com as noites em silêncio mostra quanto esse
fio custa:

```
ana@laptop:~/aws$ python3 prices.py | python3 compare.py shop=0,0,0,0,0,0,0,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,0
profile      requests   EC2 c7g.large    Fargate, Arm     Lambda, Arm     App Runner*
shop           67.89M          162.21           49.60           58.84           41.37

Lambda costs what two Fargate tasks cost at 57.23M requests a month, 21.8 a second on average.
* App Runner is priced in us-east-1: it is not offered in sa-east-1.
```

São 15,57 USD por mês entre os dois números do App Runner, tudo isso processador cobrado à noite.
Aqui não faz diferença, porque a conta é nova e o App Runner está fechado para ela (aula 22). Ainda
assim é o reflexo certo: antes de escolher o App Runner ou o Lambda pelas horas ociosas, descubra se
as horas são mesmo ociosas.

## As restrições

O preço diz Fargate, por pouco. A lista da seção 04 confirma ou derruba isso:

- a exportação leva 45 segundos, o que nenhuma integração de HTTP API permite; no Lambda atrás do
  API Gateway ela teria de virar um job numa fila. Atrás de um load balancer e numa task, ela
  funciona como está, dentro dos 60 segundos que um Application Load Balancer espera por padrão;
- o relatório leva seis minutos, o que uma função permite, já que o limite é quinze. Ele poderia ser
  uma função Lambda agendada, ou a mesma imagem rodando uma vez por noite como task de Fargate. A
  segunda opção não pede empacotamento novo;
- o disco da instância guarda os relatórios gerados, e isso precisa mudar em qualquer mudança: eles
  vão para o S3, o que neste exemplo é uma semana de trabalho, seja qual for a coluna vencedora;
- a equipe conhece contêineres e nunca rodou uma função em produção, o que as aulas 14 a 18 mostram
  ser uma habilidade à parte.

## A decisão

**A API vai para o Fargate como duas tasks, a exportação continua um endpoint síncrono nela, e o
relatório roda como uma task agendada a partir da mesma imagem.** É a opção mais barata e a mudança
mais barata, e pede a menor alteração no código. O Lambda perde no preço por quase onze dólares por
mês, e ainda custaria uma fila para a exportação e um jeito novo de empacotar.

Uma decisão assim só está pronta quando nomeia o que a reabriria. Dois números saem direto do
programa:

- se o tráfego médio cair abaixo de umas **21,8 requisições por segundo** e ficar lá, o Lambda fica
  mais barato, e a diferença de preço cresce conforme ele cai;
- se a API crescer na direção de **400 por segundo**, vale a linha busy da seção 03: instâncias, com
  um Savings Plan, vencem as tasks.

Nenhum dos dois está perto hoje, e os dois são baratos de vigiar. A aula 24 é sobre escrever isto
numa forma que alguém consiga encontrar daqui a dois anos, com o lock-in que a decisão aceita ao
lado.
