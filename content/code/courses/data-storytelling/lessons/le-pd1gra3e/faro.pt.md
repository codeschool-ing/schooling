---
title: O caso que o curso carrega
version: 1
---

Toda aula deste curso trabalha sobre a mesma análise, para que as técnicas sejam vistas sobre algo que
fica parado. Ela é da Faro, e é inventada: a empresa, as pessoas e as contagens são do próprio curso,
geradas para se comportar como dados reais de assinatura.

## A pergunta e os dados

**A pergunta:** por que os assinantes novos cancelam nos primeiros noventa dias?

**Os dados:** todo assinante que entrou na Faro entre janeiro e junho de 2025, 6.113 pessoas,
acompanhados por noventa dias depois da primeira caixa. Para cada um, a análise registrou a região (a
cidade de São Paulo, chamada *capital*, ou o resto do estado, *interior*), se a primeira entrega chegou
até a data prometida na compra e se a assinatura foi cancelada em noventa dias.

Agregada por mês, região e primeira entrega, são vinte e quatro linhas. Esta é a tabela inteira, e você
vai usá-la a partir da próxima seção:

```
cohort,region,first_delivery,subscribers,cancelled_90d
2025-01,capital,on time,546,83
2025-01,capital,late,92,33
2025-01,interior,on time,329,65
2025-01,interior,late,96,45
2025-02,capital,on time,515,80
2025-02,capital,late,87,34
2025-02,interior,on time,280,55
2025-02,interior,late,91,37
2025-03,capital,on time,570,95
2025-03,capital,late,85,34
2025-03,interior,on time,293,56
2025-03,interior,late,85,35
2025-04,capital,on time,516,78
2025-04,capital,late,81,33
2025-04,interior,on time,290,59
2025-04,interior,late,90,38
2025-05,capital,on time,563,94
2025-05,capital,late,78,29
2025-05,interior,on time,301,67
2025-05,interior,late,104,49
2025-06,capital,on time,534,88
2025-06,capital,late,75,30
2025-06,interior,on time,318,61
2025-06,interior,late,94,42
```

Os nomes das colunas e os valores ficam em inglês, como num arquivo de verdade: `cohort` é a coorte (o
mês de entrada), `first_delivery` diz se a primeira entrega foi `late` (atrasada) ou `on time` (no prazo),
e `cancelled_90d` conta quem cancelou em noventa dias.

## O que ela diz

| | assinantes | cancelaram em 90 dias | taxa |
|---|---|---|---|
| primeira entrega atrasada | 1.058 | 439 | **41,5%** |
| primeira entrega no prazo | 5.055 | 881 | **17,4%** |
| todos os assinantes novos | 6.113 | 1.320 | 21,6% |

Então **17,3% dos assinantes novos receberam a primeira caixa atrasada, e esses clientes cancelaram 2,4
vezes mais que os outros**. Esse é o achado.

## As pessoas

Cinco personagens encontram essa análise ao longo do curso, e cada um quer algo diferente dela:

- **Marina**, a analista de dados que fez o trabalho e precisa que ele vire ação.
- **Paulo**, diretor de operações, que conduz a reunião e é dono do orçamento de entrega.
- **Sandra**, gerente de logística, cuja equipe é medida pela fatia de todas as entregas feitas no prazo:
  94,5% nos mesmos seis meses.
- **Renata**, a diretora financeira, que pensa em margem e em retorno.
- **Ligeiro**, a transportadora regional que faz a maior parte das entregas da Faro, uma empresa de fora
  com contrato e metas próprios.

Os 94,5% da Sandra e os 17,3% da Marina estão os dois certos, e a aula 2 parte do fato de que eles
parecem se contradizer.
