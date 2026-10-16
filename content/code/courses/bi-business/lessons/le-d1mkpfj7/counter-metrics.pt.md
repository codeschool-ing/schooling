---
title: A guarda ao lado de cada KPI
version: 1
---

A aula 10 terminou com uma meta cumprida sem entregar mais rápido. Essa não é uma história sobre
gente desonesta. **Qualquer número pelo qual as pessoas são recompensadas vai ser mexido pelo caminho
mais barato que existir**, e o caminho mais barato muitas vezes não é aquele que o número foi
escolhido para medir. O economista Charles Goodhart fez essa observação sobre metas monetárias nos
anos 1970, e a formulação mais conhecida é da antropóloga Marilyn Strathern: *quando uma medida vira
meta, ela deixa de ser uma boa medida*.

A conclusão errada é que metas são má ideia. Um KPI que ninguém é cobrado por ele é um número sobre o
qual ninguém age, e a aula 10 gastou uma seção construindo um pelo qual alguém é cobrado. A conclusão
certa é mais estreita: **um KPI que importa precisa de um segundo número ao lado, escolhido para se
mexer quando o primeiro é cumprido do jeito errado.** Esta aula chama esse número de guarda; ele
também é conhecido como contramétrica.

## O que aconteceu na Varanda

Em março de 2026, as transportadoras do Caio foram avisadas de que o entregue no prazo decidiria
parte do contrato delas. Em maio o KPI marcava 86,2%, acima dos 76,9% de fevereiro e acima do
objetivo de 85% marcado para dezembro. As entregas com avaria também estavam na página, porque
ficaram em segundo na planilha de notas da seção anterior. Numa planilha nova:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Mês | Entregues | Avariadas | No prazo % |
| 2 | fev | 1840 | 22 | 76,9 |
| 3 | mai | 1910 | 59 | 86,2 |

```localised
=ARRED(C2/B2*100;1)      1,2
=ARRED(C3/B3*100;1)      3,1
```

**A taxa de avaria foi de 1,2% para 3,1%**, enquanto as entregas quase não cresceram. As vans
estavam sendo carregadas às pressas e dirigidas para bater a data, e sofás chegavam no prazo com o
braço rasgado. Sozinho, o KPI dizia que a cláusula do contrato funcionou; com a guarda ao lado, a
página dizia que parte do ganho tinha sido paga com os móveis dos clientes. O Caio não tirou a
cláusula. Acrescentou a ela uma condição sobre avarias.

## Escolhendo a guarda

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 328\" role=\"img\" aria-label=\"Quatro pares. À esquerda um KPI, à direita a guarda que o vigia, e entre eles o jeito de cumprir o KPI sem melhorar nada: entregue no prazo e entregas com avaria; tempo de atendimento e nova ligação em sete dias; conversão online e taxa de devolução; rupturas e dias de estoque.\" data-fig=\"l11-pairs\"><text x=\"115.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">KPI</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o atalho que ele convida</text><text x=\"605.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a guarda</text><rect x=\"20.0\" y=\"44.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"75.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">entregue no prazo</text><rect x=\"510.0\" y=\"44.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"75.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">entregas com avaria</text><path d=\"M212.0 70.0 L508.0 70.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"63.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">correr com a van, derrubar o sofá</text><rect x=\"20.0\" y=\"116.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"147.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">tempo de atendimento</text><rect x=\"510.0\" y=\"116.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"147.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">nova ligação em 7 dias</text><path d=\"M212.0 142.0 L508.0 142.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"135.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">encerrar antes de resolver</text><rect x=\"20.0\" y=\"188.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"219.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">conversão online</text><rect x=\"510.0\" y=\"188.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"219.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">taxa de devolução</text><path d=\"M212.0 214.0 L508.0 214.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"207.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vender o que não cabe na sala</text><rect x=\"20.0\" y=\"260.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"291.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">rupturas</text><rect x=\"510.0\" y=\"260.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"291.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">dias de estoque</text><path d=\"M212.0 286.0 L508.0 286.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"279.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lotar o depósito</text></svg>", "caption": "Cada KPI com a guarda lida ao lado. A coluna do meio é o motivo de a guarda existir: o jeito mais barato de mexer o número da esquerda aparece no número da direita.", "same": ["KPI"]}
```

A guarda se acha fazendo uma pergunta a cada KPI: **qual é o jeito mais barato de mexer este número
sem melhorar aquilo que ele representa?** O que esse atalho estraga é o que a guarda mede.

- O entregue no prazo se cumpre correndo, então a guarda são as entregas com avaria. Ele também se
  cumpre alongando a promessa, e é por isso que os dias prometidos ficam escritos no cartão, onde uma
  mudança precisa ser defendida.
- O tempo de atendimento de uma central se cumpre encerrando ligações antes de o problema ser
  resolvido, então a guarda é a parcela de clientes que ligam de novo em até sete dias.
- A conversão online se cumpre vendendo a quem vai devolver o produto, então a guarda é a taxa de
  devolução.
- As rupturas se cumprem lotando o depósito, então a guarda são os dias de estoque, que custam
  dinheiro ao Otávio a cada dia que crescem.

Os pares funcionam porque os dois números puxam para lados opostos. Dias de estoque e rupturas não
podem cair juntos pelo mesmo atalho preguiçoso, e um depósito que melhora os dois melhorou de
verdade. **Uma guarda é lida ao lado do seu KPI, toda vez, nunca em outra página**, porque outra
página é uma que ninguém abre numa semana boa.

## A guarda não é um sexto KPI

Uma guarda não precisa de meta própria, nem de um dono diferente do dono do KPI. Ela precisa de uma
linha no cartão do KPI dizendo que número o mantém honesto, e de um limite a partir do qual os dois
são discutidos juntos. Isso mantém a página curta: na planilha de notas, entregas com avaria e dias
de estoque ganharam o lugar por conta própria, e servem de guarda para dois dos outros. **Os melhores
indicadores de uma página curta muitas vezes fazem os dois trabalhos.**
