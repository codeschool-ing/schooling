---
title: O que um compromisso compra, e quando ele compensa
version: 1
---

**Um compromisso é pago por toda hora do seu prazo, usada ou não; sob demanda é pago só pelas horas
que rodaram.** Então um desconto de 38% não é uma economia de 38%. É economia se a máquina roda
horas suficientes, e prejuízo se não roda. O número de horas em que um vira o outro é o **ponto de
equilíbrio** (*break-even*). É a primeira coisa a calcular antes de comprar qualquer coisa, e a
última coluna do `terms.py` é esse número.

## O ponto de equilíbrio, em horas por mês

Sob demanda, um `m7i.large` custa 0,16065 dólar por hora que roda. A reserva padrão de um ano sem
adiantamento custa 0,09956 por hora do ano, haja instância rodando ou não. Isso dá 72,68 dólares por
mês. O mês sob demanda chega a 72,68 depois de 72,68 / 0,16065 = **452 horas**, 62% de um mês de 730
horas. Abaixo disso, sob demanda é mais barato; acima, a reserva é. A tarifa do Compute Savings Plan
é mais alta, então o ponto de equilíbrio dele vem depois, em **496 horas**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l14-breakeven\" aria-label=\"Dólares por mês contra horas rodadas no mês, para um m7i.large em sa-east-1, pelas listas de preços de 25 de setembro de 2026. Sob demanda é uma linha que sobe de 0 dólar em 0 hora até 117,27 em 730 horas. A reserva padrão de um ano sem adiantamento é plana em 72,68, e a linha sob demanda a cruza em 452 horas. O Compute Savings Plan de um ano sem adiantamento é plano em 79,68, cruzado em 496 horas. À esquerda do cruzamento, sob demanda é mais barato; à direita, o compromisso é.\"><path d=\"M90.0 290.0 L670.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 290.0 L90.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"248.9\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"407.8\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><text x=\"566.7\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">600</text><text x=\"670.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">730</text><text x=\"380.0\" y=\"324.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">horas que a máquina roda no mês</text><text x=\"82.0\" y=\"290.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"82.0\" y=\"197.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><text x=\"82.0\" y=\"105.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><text x=\"90.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dólares por mês</text><path d=\"M90.0 155.8 L670.0 155.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"97.9\" y=\"169.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">reserva padrão: 72,68</text><path d=\"M90.0 142.9 L670.0 142.9\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"97.9\" y=\"130.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Compute Savings Plan: 79,68</text><path d=\"M90.0 290.0 L670.0 73.5\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"666.0\" y=\"61.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sob demanda: 117,27</text><path d=\"M449.1 161.9 L449.1 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"449.1\" cy=\"155.9\" r=\"4.5\" fill=\"var(--amber)\"></circle><path d=\"M484.1 148.9 L484.1 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"484.1\" cy=\"142.9\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"445.1\" y=\"278.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">452 h</text><text x=\"488.1\" y=\"278.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">496 h</text><text x=\"288.6\" y=\"267.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--phosphor)\">sob demanda é mais barato</text><text x=\"582.6\" y=\"216.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">o compromisso é mais barato</text></svg>", "caption": "Um compromisso é uma linha plana; sob demanda sobe com as horas. Onde elas se cruzam é o ponto de equilíbrio.", "same": ["452 h", "496 h"]}
```

**O ponto de equilíbrio transforma a compra numa pergunta sobre o horário da máquina.** Um banco de
dados que roda o mês todo está muito além dele. Um servidor de build que roda dez horas por dia em
22 dias úteis roda 220 horas. Sob demanda isso custa 220 × 0,16065 = 35,34 dólares, menos da metade
do que a reserva custaria. Ambientes de staging desligados à noite são o lugar comum onde alguém
compra uma reserva e a desperdiça.

## A que uma reserva está presa

Uma **Reserved Instance** é uma promessa sobre um tipo de instância, um sistema operacional e uma
tenancy, numa região. A documentação da AWS descreve dois escopos:

- uma reserva **regional** vale para uma instância que combine em qualquer zona da região, e, para
  Linux em hardware compartilhado, para qualquer tamanho da mesma família: uma reserva de um
  `m7i.xlarge` cobre dois `m7i.large`, porque os tamanhos são contados em unidades da família;
- uma reserva **zonal** vale só numa zona, e em troca também reserva a capacidade ali, então uma
  instância desse tipo pode ser iniciada nessa zona quando outras não conseguem.

Ela vem em duas classes. Você pode mudar a zona, o escopo e o tamanho de uma reserva **padrão**
(*standard*) dentro da família, e vendê-la a outra pessoa no Reserved Instance Marketplace da AWS
quando não precisar mais dela. Você pode trocar uma reserva **conversível** (*convertible*) por
outra conversível de valor igual ou maior, em outra família ou para outro sistema operacional. A
tabela da seção anterior mostra quanto custa essa liberdade, 0,10915 contra 0,09956 por hora.

## A que um Savings Plan está preso

**Um Savings Plan se compromete com dólares por hora, não com uma máquina.** A loja compra um
Compute Savings Plan de um ano de 0,10915 dólar por hora, a tarifa de um `m7i.large`. Em cada hora
do ano a AWS pega o uso que o plano pode cobrir e o cobra pelas tarifas do plano, até 0,10915 dólar.
O que passar disso é sob demanda, e qualquer parte dos 0,10915 que ficar sem uso naquela hora se
perde. A loja pode mudar a aplicação para outra família, para outra região, ou para fora do EC2, em
contêineres no Fargate ou funções no Lambda. Um Savings Plan **Compute** a acompanha, porque cobre
tudo isso. Um Savings Plan **EC2 Instance** cobre uma família numa região, qualquer tamanho e
sistema. Ele tem preço de reserva padrão por ser estreito assim. A documentação da AWS diz que
nenhum dos dois tipos pode ser vendido ou trocado depois de comprado.

A documentação da AWS também dá a ordem. Em cada hora a AWS aplica as reservas primeiro, e os
Savings Plans depois, ao que sobrar. E dá a ligação com a lição 3. **Numa organização o desconto é
compartilhado pela fatura consolidada.** Uma reserva ou um plano comprado numa conta cobre primeiro
o uso que combina nessa conta, e depois em qualquer outra conta da organização. A exceção é uma
conta para a qual a conta de gerenciamento desligou o compartilhamento. É por isso que uma loja com
seis contas compra os compromissos num lugar só e os deixa circular, em vez de um por conta.

Quanto se comprometer, e quando comprar mais, é o assunto da lição 22 de `aws-operations`. É uma
questão de medir as horas antes de prometê-las. A próxima seção lê como um compromisso aparece
depois que está numa fatura.
