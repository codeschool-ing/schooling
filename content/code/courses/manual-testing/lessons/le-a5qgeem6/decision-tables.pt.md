---
title: Tabelas de decisão
version: 1
---

**A aula 4 testou um campo de cada vez, e algumas regras não se testam assim.** O R5, a regra de
preço, depende de três coisas ao mesmo tempo: se quem compra é estudante, se a conta é de membro, e
se o pedido tem cinco ingressos ou mais. O plano óbvio é um caso por desconto: um pedido como
estudante, um como membro, um de cinco ingressos. Três casos, três descontos vistos, e a frase que
torna o R5 difícil continua sem teste: "Descontos não se somam: vale o maior." Essa frase só faz
alguma coisa quando dois descontos se encontram, e nenhum dos três casos deixa que se encontrem.

Uma **tabela de decisão** é a técnica para regras como essa. Ela lista todas as combinações das
condições e, ao lado de cada combinação, o resultado que o requisito pede. Nada fica por conta do
faro do testador sobre quais combinações parecem interessantes; a tabela torna todas visíveis, e aí
a decisão sobre quais rodar é uma decisão que alguém consegue ver.

## As partes de uma tabela

Uma tabela de decisão tem três partes, e vale saber os nomes, porque ferramentas de teste e outros
testadores os usam:

- **condições**, as perguntas que a regra faz, uma por linha, em cima. Para o R5: quem compra é
  estudante? a conta é de membro? são 5 ingressos ou mais?
- **ações**, o que o sistema faz, uma por linha, embaixo. Para o R5 há uma: o desconto aplicado,
  em porcentagem;
- **regras**, as colunas. Cada regra é uma combinação de respostas às condições, e a ação que ela
  deve produzir.

Quando toda condição é sim ou não, o número de regras é 2 elevado ao número de condições: uma
condição dá 2, duas dão 4, três dão 8. O R5 tem três, então a tabela completa tem oito regras.

## Preenchendo sem esquecer nenhuma

Oito colunas de S e N são fáceis de errar à mão, escrevendo uma combinação duas vezes e deixando
outra de fora. O padrão que evita isso vai dividindo ao meio a cada linha: a primeira condição é S
na primeira metade das colunas e N na segunda; a seguinte alterna de duas em duas; a última alterna
coluna a coluna. Toda combinação aparece exatamente uma vez, e uma que falte aparece como uma quebra
no padrão.

Depois cada coluna recebe sua ação, lida do requisito e de nada mais. As regras 1 a 4 têm um
estudante, e meia-entrada, 50%, é maior que qualquer dos outros descontos, então as quatro dão 50.
A regra 6 é um membro comprando menos de cinco, 10%. A regra 7 é alguém que não é membro comprando
cinco ou mais, 15%. A regra 8 não tem direito a nada, 0%. **A regra 5 é a que se lê devagar**: um
membro comprando cinco ou mais tem direito a 10% e a 15%, os descontos não se somam, vale o maior,
e então a resposta é 15%, não 25%.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 245\" role=\"img\" data-fig=\"l05-discount-table\" aria-label=\"Uma tabela de decisão com oito colunas de regras. Condições: estudante, S nas regras 1 a 4 e N de 5 a 8; membro, S S N N S S N N; 5 ingressos ou mais, alternando S e N. Ação, o desconto: 50, 50, 50, 50, 15, 10, 15 e 0 por cento. As regras 1 a 4 têm uma chave: estudante, 50% não importa o resto. A regra 5 tem contorno: 10% e 15% valem, e o maior vence.\"><path d=\"M214 42 L214 34 L438 34 L438 42\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"326.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">estudante: 50%, não importa o resto</text><rect x=\"20.0\" y=\"52.0\" width=\"654.0\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445.0\" y=\"55.0\" width=\"52.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"30.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">regra</text><text x=\"239.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"297.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"355.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"413.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"471.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"529.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"587.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">7</text><text x=\"645.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">8</text><rect x=\"20.0\" y=\"82.0\" width=\"654.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445.0\" y=\"85.0\" width=\"52.0\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"30.0\" y=\"95.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estudante?</text><text x=\"239.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"297.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"355.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"413.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"471.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"529.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"587.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"645.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><rect x=\"20.0\" y=\"112.0\" width=\"654.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445.0\" y=\"115.0\" width=\"52.0\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"30.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">membro?</text><text x=\"239.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"297.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"355.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"413.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"471.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"529.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"587.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"645.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><rect x=\"20.0\" y=\"142.0\" width=\"654.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445.0\" y=\"145.0\" width=\"52.0\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"30.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5 ingressos ou mais?</text><text x=\"239.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"297.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"355.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"413.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"471.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"529.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"587.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">S</text><text x=\"645.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><rect x=\"20.0\" y=\"172.0\" width=\"654.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445.0\" y=\"175.0\" width=\"52.0\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"30.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">desconto (R5)</text><text x=\"239.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">50%</text><text x=\"297.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">50%</text><text x=\"355.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">50%</text><text x=\"413.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">50%</text><text x=\"471.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">15%</text><text x=\"529.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">10%</text><text x=\"587.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">15%</text><text x=\"645.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">0%</text><path d=\"M20.0 170.0 L674.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"471.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">regra 5: 10% e 15% valem; o maior vence</text></svg>", "caption": "O R5 como tabela de decisão completa: três condições, oito regras e o desconto que o requisito pede em cada uma. A regra 5 é a coluna em que a frase \"vale o maior\" decide a resposta."}
```

Escrever essa linha já é testar. Fazer isso arranca uma pergunta do requisito para cada
combinação, e às vezes o requisito não tem resposta. Se o R5 não dissesse o que acontece quando
descontos se encontram, a regra 5 seria um espaço em branco sem nada para pôr, e o certo seria
perguntar à gerente do teatro antes de alguém escrever código em cima de um palpite. Uma tabela de
decisão acha lacunas num requisito além de defeitos num programa, e acha mais cedo.

## Reduzindo uma tabela

As regras 1 a 4 dizem 50%, sejam quais forem as outras duas condições. Uma tabela pode dizer isso
numa coluna só, com um traço nas condições que não importam, lido como "tanto faz": estudante S,
membro –, cinco ou mais –, desconto 50%. As oito regras viram cinco, e cinco casos as cobrem.

**Reduzir é uma aposta sobre o código, feita sem ver o código.** Ela supõe que um programa que dá
50% a um estudante faz isso não importa o que mais seja verdade, como o requisito diz. Se o programa
conferir primeiro o desconto de membro e sair mais cedo, um estudante que também é membro é tratado
por uma linha diferente da de um estudante que não é, e a tabela reduzida roda só uma delas. Para a
maioria das regras a aposta é razoável e economiza esforço de verdade: uma tabela com cinco condições
tem 32 colunas. Para o preço, que a aula 1 pôs no topo da grade de riscos do boxoffice como risco A,
oito casos são baratos e a aposta não compensa. Esta aula roda as oito.

## Condições que não são sim ou não

"Cinco ingressos ou mais" é uma condição sobre um número, e as técnicas da aula 4 decidem o que
digitar para ela. Ela divide as quantidades válidas em duas partições, de 1 a 4 e 5 ou mais, com uma
fronteira entre 4 e 5. A tabela precisa de um valor para S e um para N; esta aula usa 5 para S, a
própria fronteira, e 2 para N. Seis seria a outra escolha para S, e a seção 04 da aula 4 mostrou
que o boxoffice 1.0 recusa seis, então cinco é a única quantidade que o programa aceita nessa
partição. Combinar técnicas assim é normal: uma condição numa tabela de decisão muitas vezes é uma
partição, e os valores dela vêm da análise de fronteira.
