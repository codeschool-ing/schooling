---
title: "Contagens numa tabela: o teste qui-quadrado"
version: 1
---

A Horta testa uma nova página de pagamento, mostrando a cada visitante a página antiga ou a nova por sorteio. Dos 2.000 visitantes que viram a página antiga, 220 compraram
algo; dos 2.000 que viram a nova, 262 compraram.

| | comprou | não comprou | total |
|---|---|---|---|
| página antiga | 220 | 1.780 | 2.000 |
| página nova | 262 | 1.738 | 2.000 |
| **total** | **482** | **3.518** | **4.000** |

As taxas de conversão são 11,0% e 13,1%. A diferença é real?

## Como seria a ausência de diferença

A hipótese nula é que a página não faz diferença: as duas convertem à mesma taxa, e a taxa geral, 482 de
4.000, vale para cada uma. Então se esperaria que os 2.000 visitantes de cada página produzissem 241 compras
e 1.759 não compras.

A **contagem esperada** de cada célula é o total da linha vezes o total da coluna, dividido pelo total
geral: 2.000 × 482 ÷ 4.000 = 241.

## A estatística

A **estatística qui-quadrado** soma, em todas as células, quão longe a contagem observada está da esperada,
ao quadrado e dividida pela contagem esperada: **χ² = Σ (observado − esperado)² ÷ esperado**.

Para a tabela do pagamento: (220 − 241)² ÷ 241 + (1.780 − 1.759)² ÷ 1.759 + (262 − 241)² ÷ 241 + (1.738 −
1.759)² ÷ 1.759 = **4,16**.

Sob a nula, a estatística segue a distribuição qui-quadrado com (linhas − 1) × (colunas − 1) graus de
liberdade, aqui 1. O p-valor para 4,16 é **0,041**. Abaixo de 0,05: a página nova converte melhor, embora sem
uma margem larga de evidência.

A função `TESTE.QUIQUA` da planilha recebe a tabela observada e a tabela de contagens esperadas e devolve o
p-valor direto:

```localised
=TESTE.QUIQUA(E2:F3; G2:H3)      0,0413607680611259
```

## Qualidade do ajuste

A mesma estatística confere um modelo. A aula 8 comparou 60 dias de reclamações com uma distribuição de
Poisson. Agrupando cinco ou mais reclamações juntas, para que toda contagem esperada seja razoavelmente
grande, a estatística qui-quadrado dá 7,98 com 5 graus de liberdade, e p = 0,16: o modelo de Poisson é
compatível com os dados, como o olho da aula 8 sugeria.

## As condições dele

- As contagens precisam ser de **unidades independentes**: cada visitante contado uma vez.
- As **contagens esperadas não devem ser pequenas**: uma regra comum pede pelo menos 5 em cada célula. A
  tabela da aula 1, com doze pedidos por bairro e pagamento, falha feio, com contagens esperadas abaixo de 1,
  e não deve ser testada assim.
- Ele trabalha com **contagens**, nunca com porcentagens: 11% de 2.000 e 11% de 20 são evidências muito
  diferentes, e são as contagens que carregam essa diferença.
