---
title: Como uma empresa de assinatura ganha dinheiro
version: 1
---

Todo achado acaba tendo de responder a uma pergunta do financeiro: **o que isso faz com o dinheiro?**
Responder começa por saber como o dinheiro é feito, e uma empresa de assinatura o faz num formato que vale
aprender, porque muitas empresas hoje vendem assim.

## As partes

- **Preço.** O que o assinante paga por período. A caixa média da Faro custa R$ 189,90 por mês.
- **Margem bruta.** O que sobra do preço depois dos custos diretos de entregá-lo: a ração, a embalagem, o
  frete. A Faro fica com 31%, então cada caixa deixa **R$ 58,87**. A margem, e não o preço, é o que paga todo
  o resto que a empresa faz.
- **Cancelamento (churn).** A fatia de assinantes que sai num período. O da Faro tem duas fases: alto nos
  primeiros noventa dias, onde o curso inteiro esteve olhando, e cerca de 4% ao mês depois disso.
- **Custo de aquisição de cliente, ou CAC.** O que a empresa gasta para conquistar um assinante novo:
  propaganda, descontos, a promoção da primeira caixa. A equipe de marketing da Faro o calcula em
  **R$ 152**.
- **Valor do tempo de vida, ou LTV** (*lifetime value*). A margem que um cliente traz durante todo o tempo em
  que fica. Depende de tudo o que está acima, e a próxima seção o calcula.

## A única relação que importa

Um assinante dá lucro quando a margem dele pagou o que custou conquistá-lo. A R$ 58,87 por caixa contra
R$ 152 de aquisição, **isso leva cerca de 2,6 caixas**. Antes desse ponto, a empresa ainda está pagando pelo
cliente; depois dele, o cliente está pagando pela empresa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" role=\"img\" data-fig=\"l11-payback\" aria-label=\"Margem acumulada de um cliente, subindo R$ 58,87 a cada caixa, contra uma linha reta em R$ 152, o custo de conquistá-lo. A linha que sobe cruza a do custo em cerca de 2,6 caixas. Uma marca em 1,6 caixa, onde o cliente médio que cancela cedo para, fica abaixo da linha do custo, em R$ 94,19.\"><path d=\"M70.0 30.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 0</text><path d=\"M70.0 167.2 L640.0 167.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"167.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 100</text><path d=\"M70.0 114.4 L640.0 114.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"114.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 200</text><path d=\"M70.0 61.7 L640.0 61.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"61.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 300</text><text x=\"70.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"165.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"260.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"355.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"450.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"545.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"640.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"355.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">caixas pagas</text><path d=\"M70.0 220.0 L640.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 139.8 L640.0 139.8\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"640.0\" y=\"129.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">custo de aquisição: R$ 152</text><path d=\"M70.0 220.0 L640.0 33.6\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"573.5\" y=\"43.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">margem até aqui</text><circle cx=\"222.0\" cy=\"170.3\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M222.0 170.3 L222.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"232.0\" y=\"196.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">cancela cedo: 1,6 caixa, R$ 94,19</text><circle cx=\"315.3\" cy=\"139.8\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"305.3\" y=\"125.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">paga de volta em 2,6 caixas</text></svg>", "caption": "Um cliente devolve o que custou conquistá-lo depois de cerca de 2,6 caixas. Quem cancela cedo para, em média, em 1,6, então cada um deles foi comprado com prejuízo.", "same": ["R$ 0", "R$ 100", "R$ 200", "R$ 300"]}
```

Agora a primeira caixa parece outra. **Um cliente que cancela nos primeiros noventa dias paga, em média, 1,6
caixa**, o que dá R$ 94,19 de margem: não o bastante para recuperar os R$ 152 que a Faro pagou para
conquistá-lo. Todo cancelamento precoce é um cliente comprado com prejuízo. Essa frase, mais que qualquer
porcentagem, é o que faz uma diretora financeira se inclinar para a frente.

## Por que um analista precisa disso

Ninguém espera que um analista toque o financeiro. Mas **um achado posto nessa estrutura pode ser pesado
contra todo outro uso do dinheiro da empresa**, e um que não é fica sendo uma curiosidade operacional. A
aula 4 abriu a versão do conselho com dinheiro exatamente por isso; esta aula mostra de onde o dinheiro
veio.
