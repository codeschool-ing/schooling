---
title: Pedir dinheiro
version: 1
---

O pedido de dinheiro típico da engenharia descreve a tecnologia: "precisamos refatorar o módulo de
reservas", "precisamos de um ambiente de teste de carga", "precisamos de mais duas pessoas na
Plataforma". Cada um é verdadeiro, e cada um chega a quem cuida das finanças como um custo sem
retorno nenhum ao lado. **Otávio recusa pedidos assim por um motivo simples: não tem com o que
compará-los.** Todos os outros pedidos na mesa dele dizem o que devolvem.

A saída é escrever o pedido nas unidades do orçamento: uma linha, um valor, uma data de início e o
que a empresa recebe de volta.

## Do que quem cuida das finanças precisa

Seis perguntas cobrem quase todo pedido, e o pedido as responde nesta ordem:

| pergunta | como é uma boa resposta |
|---|---|
| Qual linha? | uma das quatro, com o nome |
| Quanto, a partir de quando? | reais por ano, começando num mês que alguém consiga pôr num plano |
| O que devolve? | dinheiro economizado, dinheiro ganho ou um risco reduzido, com número quando houver |
| O que espera? | o trabalho que não acontece porque este acontece |
| O que acontece sem ele? | o custo de dizer não, nas mesmas unidades |
| Qual é a menor versão? | a parte que vale a pena mesmo se o resto for recusado |

A quarta pergunta é a que os pedidos de engenharia mais deixam de fora, e a primeira que um CFO
confere. **A maioria dos pedidos nem é de dinheiro novo**; é para que pessoas que já estão na folha
parem de fazer uma coisa e comecem outra. Isso continua sendo um custo, e ele é pago com o que essas
pessoas deixam de fazer. A aula 13 dá a ele um nome e um preço.

## O pedido da Coreto

A estratégia da aula 1 precisa de um time de Reservas: quatro engenheiros vindos de Checkout e
Pagamentos, a partir de 1º de março, tirando os bloqueios de linha do caminho das reservas de
assento. Davi escreve o pedido com os números que a aula 5 produziu:

> **Pedido: um time de Reservas a partir de 1º de março**
>
> Linha: Pessoas. Nenhuma contratação: quatro engenheiros saem de Checkout e Pagamentos. O custo
> deles, R$ 1.056.000 por ano, já está no orçamento.
>
> O que devolve: a dívida das reservas de assento é paga nos dois primeiros trimestres do time. A
> aula 5 precificou o principal em 320 horas, R$ 48.000, e os juros em 31 horas por sprint nos
> times que mexem nela: R$ 120.900 por ano que deixam de ser pagos. Nesse ritmo o trabalho se paga
> em 10,3 sprints.
>
> O que espera: Checkout e Pagamentos perdem a capacidade de quatro pessoas. O Pix parcelado e a
> API de parceiros vão para trás; a ordenação da aula 13 mostra quanto.
>
> Sem ele: as grandes aberturas de vendas continuam falhando no código das reservas de assento,
> umas doze vezes por ano em risco, e todos os times continuam pagando os juros.
>
> Menor versão: dois engenheiros por um trimestre, montando a regra de revisão pelo dono e o
> teste de carga, com o resto decidido pelos resultados.
>
> Como vamos saber: o teste de carga da abertura de vendas passa num nível de tráfego combinado com
> a Plataforma, e os erros de checkout nos dias de abertura caem.

Leia como o Otávio leria. O custo são pessoas que a empresa já paga, então a decisão é sobre onde
elas trabalham, não sobre gastar ou não. O retorno tem número e prazo de retorno. **R$ 48.000 de
trabalho para parar de pagar R$ 120.900 por ano** é uma frase que um CFO consegue repetir para o
próprio conselho sem um engenheiro na sala.

## O número que fica de fora

Os juros são a parte menor do argumento. O que torna urgente o trabalho nas reservas é a abertura
de vendas que falha, e o pedido do Davi diz isso em palavras — "umas doze vezes por ano em risco" —
porque ele ainda não pôs preço nisso. Uma abertura que falha tem custo em reembolsos, taxas perdidas
e casas que vão embora, e pôr uma probabilidade e um valor nisso é o assunto da aula 20. Até lá, o
pedido é honesto sobre qual parte está medida e qual está argumentada.

Vale manter essa honestidade. **Um pedido que infla o retorno para ganhar está gastando a confiança
de que vai precisar no próximo**, e o CFO que descobre um número inventado desconta todos os
números que vêm depois. A aula 4 de architect-communication é sobre traduzir um risco técnico em
risco de negócio; o trabalho desta aula é o orçamento em volta dele.

## Quando pedir

Um pedido disputa com todos os outros o dinheiro do mesmo ano, e a disputa acontece enquanto o
orçamento está sendo feito. Um pedido que chega no meio do ano pede ao Otávio que reabra uma decisão
que ele já defendeu, e por isso começa com uma desvantagem que o mesmo pedido não teria uma estação
antes.

**Peça quando o orçamento estiver sendo montado, e peça nos termos dele**: por ano, em reais, contra
uma linha que o Otávio já tem. Um pedido que faz tudo isso e mesmo assim é recusado ao menos produziu
uma decisão que alguém consegue explicar, o que é mais do que o pedido de "uma refatoração" jamais
consegue.
