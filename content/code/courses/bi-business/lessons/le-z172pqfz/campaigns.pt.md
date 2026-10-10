---
title: Campanhas: o que aconteceria de qualquer jeito
version: 1
---

Todo relatório de campanha responde a uma pergunta que ninguém fez. "A campanha de primavera trouxe
1.512 pedidos e R$ 574.560 em vendas" conta os pedidos feitos por quem a recebeu. **A pergunta de
que o dinheiro depende é quantos desses pedidos a campanha causou**, e os clientes que iam comprar
uma mangueira naquela semana de qualquer jeito também estão nos 1.512.

Isso é **incrementalidade**: as vendas que a campanha acrescentou ao que teria acontecido sem ela.
A dificuldade é que o "sem ela" nunca aconteceu. Ninguém consegue ver o mesmo cliente, na mesma
semana, receber e não receber um e-mail. A resposta do varejo é fazer a comparação acontecer de
propósito, antes de a campanha começar.

## O grupo de controle

Em setembro de 2025, Renata Sá, diretora de marketing da Varanda, planejou uma campanha de
primavera por e-mail, de duas semanas, para os 40.000 clientes da loja online: três e-mails e um
cupom de 15% de desconto. Lívia pediu uma mudança antes do envio. **Dez por cento da lista,
sorteados, não receberiam nada.** Esses 4.000 clientes são o **grupo de controle** (em inglês,
*holdout*), e o que eles compraram nas duas semanas é a melhor estimativa do que os outros 36.000
teriam comprado sem a campanha.

A escolha tem de ser por sorteio. Deixar de fora os clientes que não compravam havia um ano,
porque "eles não iam responder mesmo", monta um grupo de controle que compra menos por motivos
próprios, e a campanha leva o crédito pela diferença.

## A planilha

Duas semanas depois, os pedidos de cada grupo. Digite numa planilha nova, com as condições da
campanha embaixo:

| | A | B | C |
|---|---|---|---|
| 1 | Grupo | Clientes | Pedidos |
| 2 | Campanha | 36000 | 1512 |
| 3 | Controle | 4000 | 136 |
| 4 | Tíquete médio | 380 | |
| 5 | Desconto | 0,15 | |
| 6 | Custo de envio | 3600 | |

A taxa de pedidos de cada grupo, em porcentagem:

```localised
=ARRED(C2/B2*100;2)      4,2
=ARRED(C3/B3*100;2)      3,4
```

O grupo da campanha pediu a 4,20%, o de controle a 3,40%. **Só a diferença, 0,80 ponto, é da
campanha.** Aplicada aos 36.000 que a receberam:

```localised
=ARRED(B2*(C2/B2-C3/B3);0)      288
```

São 288 pedidos incrementais. Os outros 1.224 viriam de qualquer jeito, que é o que a taxa do grupo
de controle prevê para 36.000 clientes:

```localised
=ARRED(B2*C3/B3;0)      1224
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma barra horizontal com os 1.512 pedidos do grupo da campanha. A parte maior, 1.224 pedidos, é o que o grupo de controle diz que o grupo faria de qualquer jeito; a parte menor, 288 pedidos, é o que a campanha acrescentou.\" data-fig=\"l18-holdout\"><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">1.512 pedidos do grupo da campanha, duas semanas</text><path d=\"M40.0 60.0 H558.1 V116.0 H40.0 Z\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M558.1 60.0 H680.0 V116.0 H558.1 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"40.0\" y=\"60.0\" width=\"640.0\" height=\"56.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"40.0\" y=\"140.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">1.224 aconteceriam de qualquer jeito</text><text x=\"40.0\" y=\"158.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o controle comprou a 3,40%: 36.000 × 3,40%</text><text x=\"680.0\" y=\"140.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">288 causados pela campanha</text><text x=\"680.0\" y=\"158.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4,20% − 3,40% = 0,80 ponto</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o desconto de 15% foi para os 1.512; a campanha mudou o que 288 fizeram</text><text x=\"360.0\" y=\"236.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">custo por pedido incremental: R$ 312, contra R$ 59 por pedido da campanha</text></svg>", "caption": "Os pedidos do grupo da campanha divididos pelo que o grupo de controle mostra. A maioria viria de qualquer jeito, e também levou o desconto."}
```

## Quanto custou cada pedido

O custo da campanha é o desconto em todo pedido feito com o cupom, mais o envio. Em reais:

```localised
=C2*B4*B5+B6      89784
```

**O desconto foi para os 1.512 pedidos, inclusive os 1.224 que não precisavam ser convencidos.**
Esse é o custo que o relatório de campanha esconde, porque divide pelo número errado:

```localised
=ARRED((C2*B4*B5+B6)/C2;1)      59,4
=ARRED((C2*B4*B5+B6)/(B2*(C2/B2-C3/B3));0)      312
```

R$ 59 por pedido é o que o relatório disse. **R$ 312 por pedido que a campanha de fato causou** é o
que a Varanda pagou. Num tíquete médio de R$ 380, isso é 82% de cada venda incremental, antes do
custo da própria mercadoria:

```localised
=ARRED((C2*B4*B5+B6)/(B2*(C2/B2-C3/B3))/B4*100;1)      82
```

Não existe varejista de jardim com margem bruta perto de 82%. A campanha perdeu dinheiro em cada
pedido que causou, e teria sido apresentada como um sucesso.

## O que o grupo de controle não faz sozinho

Dois cuidados mantêm o resultado honesto. **O grupo de controle é pequeno**: 136 pedidos bastam
para enxergar uma diferença desse tamanho, mas o acaso sozinho mexe alguns décimos de ponto numa
taxa medida em 4.000 clientes. Quão segura é uma diferença, dado o tamanho dos grupos, é a pergunta
da aula 22 de `statistics`, e uma equipe que faz muitas campanhas a responde antes de citar
qualquer uma delas.

**E algumas campanhas não deixam ninguém de fora.** Uma vitrine, um comercial de televisão ou uma
redução de preço em todas as lojas alcançam todo mundo. Nesses casos, o varejista compara lojas que
receberam a campanha com lojas parecidas que não receberam, ou um período com o mesmo período do
ano anterior e a tendência das lojas em volta. Cada um desses métodos é mais fraco que um grupo de
controle sorteado, e cada um diz isso no seu relatório. O que nenhum pode fazer é contar os pedidos
da campanha e chamar a contagem de efeito.

A campanha seguinte de Renata saiu com o mesmo grupo de controle, 10% de desconto em vez de 15%, e
só para clientes que não compravam havia noventa dias.
