---
title: A economia unitária da Faro, numa planilha
version: 1
---

**Economia unitária** é a conta de um cliente: quanto ele custa, quanto traz e quando as duas coisas se
cruzam. São poucas multiplicações, e fazê-las você mesmo é o que deixa você responder a uma pergunta do
financeiro na sala, em vez de prometer perguntar ao financeiro.

## Margem por caixa

```localised
=189,9*0,31
```

Preço vezes margem bruta. O Calc dá **58,869**: R$ 58,87 de margem por caixa.

## Quanto tempo um cliente fica

Os clientes da Faro que sobrevivem aos primeiros noventa dias passam a sair a cerca de 4% ao mês. Quando
uma fatia constante sai a cada mês, a permanência média restante é um dividido por essa fatia, então **1 /
0,04 = 25 meses**, mais os três já sobrevividos:

```localised
=3+1/0,04
```

O Calc dá **28** meses. Os 4% são a taxa medida da Faro; a fórmula supõe que ela fica constante, que é o tipo
de hipótese que o financeiro deve confirmar antes de o número ir para um slide do conselho.

## Valor do tempo de vida, de dois jeitos

```localised
=189,9*0,31*(3+1/0,04)
```

Para um cliente que sobrevive: **R$ 1.648,33** de margem ao longo da vida. Para um que cancela cedo, 1,6
caixa em vez de 28:

```localised
=189,9*0,31*1,6
```

**R$ 94,19.** A diferença, R$ 1.554,14, é o que cada cancelamento precoce custa à Faro em margem que ela de
outro modo ganharia.

## Duas razões que o financeiro vai perguntar

- **LTV sobre CAC.** R$ 1.648,33 contra R$ 152 dá **10,8**. Uma regra prática comum em empresas de
  assinatura trata três como saudável; os sobreviventes da Faro são muito lucrativos, e é por isso que
  perdê-los cedo dói.
- **Retorno (payback).** R$ 152 dividido por R$ 58,87 dá **2,6 caixas**. Quem cancela cedo, com 1,6, nunca
  chega lá.

Ponha essas fórmulas numa planilha salva ao lado do `faro.csv`, como `faro.ods`, com um rótulo na célula
seguinte dizendo o que cada uma é. Quando a Renata perguntar de onde vieram os R$ 1.554, **a resposta é um arquivo que
ela pode abrir**, o que é uma resposta mais forte que qualquer frase.
