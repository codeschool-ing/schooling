---
title: "Modelos de preço: sob demanda, reservado, savings plans e spot"
version: 1
---

O preço por hora da seção de dimensionamento é um jeito de comprar a máquina, e é o mais caro. **O
mesmo tipo de instância tem vários preços, e o que os separa é o que você promete ao provedor** em
troca: nada, um ano de uso, um ano de gasto, ou o direito de tomar a máquina de volta.

## Sob demanda: nenhuma promessa

Sob demanda é o preço que você paga por padrão. Você inicia a instância quando quer, para quando
quer, e paga pelo tempo entre as duas coisas. Nada é comprometido, então nada tem desconto. É o preço
certo para tudo cujo futuro você ainda não conhece, e para tudo o que roda só parte do tempo.

## Reservado: um ano desta máquina

Uma **reserva** é a promessa de pagar por um tipo específico de instância durante um prazo, um ou três
anos, rodando ou não. Em troca, a tarifa por hora cai. A tabela traz o prazo de um ano sem pagamento
adiantado, para a mesma máquina de antes:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | grep -E 'sa-east-1|on demand|reserved|m7i.large'
                                        sa-east-1    us-east-1
EC2, Linux, on demand, USD per hour
  m7i.large   2 vCPU   8 GiB              0.16065      0.10080
EC2, Linux, 1-year reserved, no upfront, USD per hour
  m7i.large                               0.09956      0.06668
```

Em `sa-east-1` a tarifa reservada é 0,09956 contra 0,16065 sob demanda. O desconto se calcula como
qualquer desconto:

1 − 0,09956 / 0,16065 = 1 − 0,620 = 0,380, ou seja, **38% de desconto**.

Em 730 horas isso dá 72,68 USD por mês em vez de 117,27: a tarifa é 0,06109 menor por hora, o que dá
44,60 por mês. O porém está na palavra *prazo*. Você deve a tarifa reservada pelas 8.760 horas do
ano, o que dá 872,15 USD, mesmo que a instância seja parada em março e nunca mais iniciada. Então a
reserva só compensa se a máquina fosse rodar mais de 62% das horas do ano, que é o mesmo 0,620 lido ao contrário. Abaixo disso, pagar sob demanda pelas horas que você de fato usa sai mais barato.

É por isso que reservas são compradas para o piso de um sistema e não para os picos. As duas máquinas
que rodam toda hora de todo dia valem uma reserva. As quatro extras que um grupo acrescenta nas tardes
de dia útil, não.

Prazos de três anos e pagamento adiantado dão descontos maiores, e a tabela não lê essas linhas; este
curso só cita o que consegue mostrar.

## Savings plans: um ano de gasto

Uma reserva nomeia uma máquina, e um ano é tempo suficiente para a máquina certa mudar. Um **savings
plan** compromete um valor de gasto por hora, por um ou três anos, e o desconto vale para o que você
rodar que se encaixe no plano. O tipo mais amplo na AWS cobre qualquer família, tamanho e região de
instância, e também parte da computação serverless, então passar de `m7i` para `m7g` no meio do ano
não desperdiça o compromisso. O desconto é um pouco menor que o de uma reserva de um tipo fixo, e a
flexibilidade é o que ele compra. A forma da promessa é a mesma: você paga o valor comprometido toda
hora, usado ou não.

## Spot: o provedor pode tomar de volta

Os hosts de um provedor nunca estão cheios, e o **spot** vende a capacidade ociosa com um desconto que
muda conforme a quantidade disponível. O preço desse desconto é que o provedor pode recuperar a
instância quando precisar da capacidade; a AWS avisa com dois minutos de antecedência. Trabalho que
pode ser interrompido e retomado se encaixa: tarefas em lote que salvam o progresso, executores de
testes, uma fila de vídeo em que um trabalho perdido é simplesmente refeito. Um banco de dados, ou a
única cópia de qualquer coisa, não.

O preço spot não está na tabela, e não por esquecimento: a lista pública de preços que este curso lê
não o traz, porque ele muda com a oferta em vez de ser publicado como lista. Então este curso não cita
nenhum valor spot, e a figura abaixo o desenha sem um.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Barras para uma m7i.large em sa-east-1 por 730 horas: sob demanda 117,27 dólares, reservada por um ano sem pagamento adiantado 72,68 dólares, e spot desenhada como faixa tracejada sem número porque o preço varia e não está na lista de preços.\"><defs><marker id=\"price-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">uma m7i.large, sa-east-1, Linux, 730 horas</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Sob demanda</text><rect x=\"190\" y=\"46\" width=\"420\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">117.27 USD</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Reservada 1 ano</text><text x=\"20\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem adiantamento</text><rect x=\"190\" y=\"102\" width=\"260\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">72.68 USD</text><text x=\"20\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Spot</text><rect x=\"190\" y=\"164\" width=\"480\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"430\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">varia com a capacidade ociosa; fora da lista de preços</text><path d=\"M190 34 L190 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "A mesma máquina no mesmo mês, comprada de três jeitos. As duas primeiras barras são 730 horas vezes uma linha da tabela de preços. Spot não tem comprimento de barra porque não tem preço fixo: ele acompanha a capacidade ociosa, e a lista pública não o traz.", "same": ["Spot"]}
```

Sistemas reais misturam os três. Um grupo pode manter o mínimo em reserva ou savings plan, acrescentar
máquinas sob demanda para o pico do dia e rodar em spot o trabalho que pode ser interrompido. A aula
10 volta a isso como orçamento; o que esta seção precisa que você guarde é que cada desconto é pago
com uma promessa, e uma promessa que você não consegue cumprir é um custo, não uma economia.
