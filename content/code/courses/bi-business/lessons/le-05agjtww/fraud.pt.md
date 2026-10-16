---
title: Fraude: caçando algo raro
version: 1
---

Toda compra no cartão que a Ipê autoriza passa por regras que decidem, numa fração de segundo, se ela
parece fraude. A compra que parece é bloqueada até o cliente confirmar. O BI não escreve essas regras:
ele **mede quanto elas custam**, em fraude que passa e em clientes bons barrados. Esta seção é escrita
desse lado, o da detecção e da medição.

## A taxa de base

Em dezembro de 2025, o cartão da Ipê processou 400.000 compras. Nas semanas seguintes, conforme clientes
contestavam cobranças que não fizeram, 400 delas se revelaram fraude: **0,1%, uma compra em mil**. Esse
número, quão comum a coisa é antes de qualquer regra procurá-la, é a taxa de base, e quase toda surpresa
na medição de fraude vem de esquecê-la.

A regra principal da Ipê, a regra A, sinalizou 300 das 400 fraudes, três em cada quatro. Também
sinalizou 2% das compras legítimas. Dois por cento parece pouco. De 399.600 compras legítimas, são
7.992.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Uma árvore dos 400.000 pagamentos com cartão de dezembro. 400 são fraude e 399.600 são legítimos. Dos 400 fraudulentos, a regra A sinaliza 300 e deixa passar 100. Dos 399.600 legítimos, sinaliza 7.992 e deixa passar 391.608. Entre os 8.292 sinalizados, 300 são fraude: precisão de 3,6%.\" data-fig=\"l17-fraud\"><rect x=\"250.0\" y=\"14.0\" width=\"220.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"35.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pagamentos com cartão em dezembro</text><text x=\"360.0\" y=\"55.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">400.000</text><rect x=\"100.0\" y=\"110.0\" width=\"180.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190.0\" y=\"131.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fraude</text><text x=\"190.0\" y=\"151.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">400</text><rect x=\"440.0\" y=\"110.0\" width=\"180.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530.0\" y=\"131.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">legítimos</text><text x=\"530.0\" y=\"151.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">399.600</text><rect x=\"20.0\" y=\"206.0\" width=\"150.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"227.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fraude sinalizada</text><text x=\"95.0\" y=\"247.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">300</text><rect x=\"195.0\" y=\"206.0\" width=\"150.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"227.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fraude que passou</text><text x=\"270.0\" y=\"247.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">100</text><rect x=\"375.0\" y=\"206.0\" width=\"150.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"227.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">legítimos sinalizados</text><text x=\"450.0\" y=\"247.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">7.992</text><rect x=\"550.0\" y=\"206.0\" width=\"150.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"227.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">legítimos liberados</text><text x=\"625.0\" y=\"247.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">391.608</text><path d=\"M360.0 66.0 L360.0 88.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M190.0 88.0 L530.0 88.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M190.0 88.0 L190.0 108.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M530.0 88.0 L530.0 108.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M190.0 162.0 L190.0 184.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M95.0 184.0 L270.0 184.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M95.0 184.0 L95.0 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M270.0 184.0 L270.0 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M530.0 162.0 L530.0 184.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M450.0 184.0 L625.0 184.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M450.0 184.0 L450.0 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M625.0 184.0 L625.0 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"360.0\" y=\"292.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">sinalizados pela regra A: 8.292, dos quais 300 são fraude</text><text x=\"360.0\" y=\"314.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">precisão de 3,6%: cerca de 27 clientes bons bloqueados para cada fraude pega</text></svg>", "caption": "A regra A pega três fraudes em cada quatro, e ainda assim a maior parte do que ela sinaliza são clientes bons, porque os pagamentos legítimos superam a fraude mil para um."}
```

## Precisão: quantos alertas acertam

A regra A disparou 8.292 alertas no mês, e 300 eram fraude. **A precisão dela, a parte dos alertas que
acertou, é 3,6%.** Para cada fraude pega, cerca de 27 clientes bons tiveram uma compra bloqueada no
caixa, ligaram para a central ou desistiram. Uma regra que pega três fraudes em quatro e erra 96 alertas
em 100 não é uma contradição; é a cara de qualquer regra quando a coisa caçada é mil vezes mais rara que
a coisa em que ela não pode encostar.

Digite as duas regras entre as quais a Ipê escolhia numa aba nova a partir de A1. B é quantas fraudes
cada uma pegou, das 400 do mês; C, quantas compras legítimas cada uma bloqueou:

| | A | B | C |
|---|---|---|---|
| 1 | Regra | Pegas | Legítimas bloqueadas |
| 2 | Regra A | 300 | 7992 |
| 3 | Regra B | 240 | 3996 |

A regra B é mais rígida: sinaliza 1% das compras legítimas em vez de 2%, e pega 60% da fraude em vez de
75%. Em D1 digite `Precisão %`, e em D2:

```localised
=ARRED(B2/(B2+C2)*100;1)      3,6
```

Copie para D3: a precisão da regra B é **5,7%**. Melhor, e ainda na maior parte alertas errados.

## Os dois custos

A precisão sozinha não escolhe entre as regras, porque os dois erros custam valores diferentes. Uma
fraude que passa custa à Ipê, em média, R$ 1.100. Uma compra legítima bloqueada custa uns R$ 15 para
atender, no tempo da central; o que ela custa em clientes que deixam de usar o cartão é real e mais
difícil de precificar, e a Ipê deixa isso fora desta conta de propósito e diz que deixou. Em E1 digite
`Passaram`, e em E2 as fraudes que a regra deixou passar:

```localised
=400-B2      100
```

Em F1 `Custo`, e em F2 o custo do mês dos dois erros, em reais:

```localised
=E2*1100+C2*15      229880
```

Copie E2:F2 para a linha 3. **A regra A custa R$ 229.880 por mês e a regra B, R$ 235.940**: a regra
mais rígida economiza R$ 59.940 em compras legítimas bloqueadas e perde R$ 66.000 a mais em fraude que
passa. Sem regra nenhuma, as 400 fraudes teriam custado R$ 440.000.

As duas regras estão perto, e a resposta se inverteria se um cliente bloqueado custasse alguns reais a
mais. É o resultado honesto: **o limiar de uma regra de fraude é uma decisão de negócio sobre o preço de
cada erro**, tomada por quem é dono dos dois preços, que é o argumento da aula 11 de `machine-learning`
sobre o limiar de qualquer modelo e o da aula 14 sobre os alertas do Marcos.

## O que os dados de fraude têm de estranho

Dois hábitos dos dados mudam todos os números acima.

- **Os rótulos chegam tarde.** Uma compra só é conhecida como fraude quando alguém a contesta, muitas
  vezes semanas depois. Um relatório sobre a fraude de ontem conta só o que já foi contestado e sempre
  parece melhor do que o mês vai ser. É o problema da carteira jovem da seção anterior, com outra cara.
- **Uma fraude bloqueada não deixa resultado.** Quando a regra A barra uma compra e o cliente nunca a
  confirma, a Ipê supõe que era fraude, e parte eram clientes bons que desistiram. As decisões da própria
  regra moldam os dados com que ela é medida depois.

Como se constrói um modelo para achar fraude, e por que a acurácia é a medida errada quando um caso em
mil é positivo, são as aulas 10 e 13 de `machine-learning`. A parte do analista de BI é a desta seção: a
taxa de base, a precisão, os dois custos, e um relatório que diz quanto da fraude do mês passado ainda
não foi descoberto.
