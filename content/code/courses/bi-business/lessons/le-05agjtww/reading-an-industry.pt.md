---
title: Lendo um setor: quatro perguntas
version: 1
---

As cinco últimas aulas do curso levam o BI a setores: finanças aqui, depois varejo, saúde, indústria e
os relatórios regulatórios. Um analista que muda de setor não recomeça do zero a cada vez. **Ele faz as
mesmas quatro perguntas a todo setor novo, e as respostas dizem onde está o trabalho e onde ele dá
errado.** Esta seção apresenta as quatro, e as aulas 18 a 21 as usam sem explicá-las de novo.

| | a pergunta | o que ela encontra |
|---|---|---|
| 1. as decisões | que decisões este setor toma sem parar? | o trabalho para o qual o BI existe: uma decisão repetida, respondida sempre do mesmo jeito (aula 1) |
| 2. os indicadores | que indicadores servem a elas? | o vocabulário de números do setor, cada um ligado a uma dessas decisões (aulas 10 a 12) |
| 3. os dados | de onde vêm os dados, e o que eles têm de estranho? | os sistemas que registram o trabalho, e o hábito desses registros que engana quem chega |
| 4. a armadilha | qual armadilha é típica? | o indicador enganoso que esse setor produz com mais frequência, a aula 12 daquele setor |

## Por que estas quatro, e nesta ordem

**As decisões vêm primeiro porque decidem todo o resto**, que é a definição da aula 1 aplicada a um
setor inteiro. Uma financeira decide milhares de vezes por dia a quem emprestar; um hospital decide toda
manhã qual paciente fica com qual leito. Um indicador que não serve a nenhuma das decisões repetidas é
uma curiosidade, por mais padrão que seja nos relatórios do setor.

Os indicadores vêm em segundo, e a maioria dos setores tem mais do que alguém consegue usar. Vale
aprender cada um com sua definição, numerador e denominador, porque duas empresas do mesmo setor
calculam com frequência "a mesma" razão de jeitos diferentes, e o cartão da aula 10 é como você
descobre.

**Os dados são a pergunta que o novato pula**, e é onde o setor esconde suas peculiaridades. Todo setor
registra o próprio trabalho pelos próprios motivos, e cada conjunto de registros tem um hábito: chega
atrasado, registra só parte do que aconteceu, é digitado à mão no fim do turno. Conhecer esse hábito é a
diferença entre o analista que lê os números e o que é lido por eles.

A armadilha vem por último porque decorre das outras três: é o que acontece quando um indicador da
pergunta 2 é calculado sobre dados com o hábito da pergunta 3 e usado numa decisão da pergunta 1. Todo
setor tem uma que os experientes conhecem e em que os novatos caem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Quatro caixas em linha, numeradas de 1 a 4, cada uma com uma pergunta e a resposta da Ipê Crédito embaixo. 1, as decisões: o que este setor decide sem parar? Na Ipê: para quem emprestar, quanto e a que taxa; que compra no cartão bloquear. 2, os indicadores: quais servem a essas decisões? Margem financeira, custo do risco, inadimplência por safra, precisão da fraude, valor do cliente. 3, os dados: de onde vêm, e o que têm de estranho? O resultado de um empréstimo chega meses depois da decisão, e quem foi recusado nunca mais aparece. 4, a armadilha: qual é a típica? Uma carteira que cresce parece segura, porque os empréstimos novos ainda não tiveram tempo de atrasar. Uma seta vai de cada caixa para a seguinte.\" data-fig=\"l17-four\"><rect x=\"20.0\" y=\"30.0\" width=\"156.0\" height=\"300.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32.0\" y=\"56.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" font-weight=\"600\" fill=\"var(--paper-dim)\">1</text><text x=\"54.0\" y=\"55.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">as decisões</text><text x=\"32.0\" y=\"84.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o que este setor</text><text x=\"32.0\" y=\"102.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">decide sem parar?</text><path d=\"M32.0 120.0 L164.0 120.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"32.0\" y=\"142.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">na Ipê:</text><text x=\"32.0\" y=\"166.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a quem emprestar, quanto</text><text x=\"32.0\" y=\"186.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">e a que taxa; que</text><text x=\"32.0\" y=\"206.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">compra no cartão</text><text x=\"32.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">bloquear</text><path d=\"M178.0 180.0 L194.0 180.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M194.0 180.0 L185.9 183.9 L185.9 176.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"196.0\" y=\"30.0\" width=\"156.0\" height=\"300.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208.0\" y=\"56.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" font-weight=\"600\" fill=\"var(--paper-dim)\">2</text><text x=\"230.0\" y=\"55.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">os indicadores</text><text x=\"208.0\" y=\"84.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">quais servem</text><text x=\"208.0\" y=\"102.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a essas decisões?</text><path d=\"M208.0 120.0 L340.0 120.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"208.0\" y=\"142.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">na Ipê:</text><text x=\"208.0\" y=\"166.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">margem financeira,</text><text x=\"208.0\" y=\"186.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">custo do risco,</text><text x=\"208.0\" y=\"206.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">atraso por safra,</text><text x=\"208.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">precisão da fraude, CLV</text><path d=\"M354.0 180.0 L370.0 180.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M370.0 180.0 L361.9 183.9 L361.9 176.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"372.0\" y=\"30.0\" width=\"156.0\" height=\"300.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"384.0\" y=\"56.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" font-weight=\"600\" fill=\"var(--paper-dim)\">3</text><text x=\"406.0\" y=\"55.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">os dados</text><text x=\"384.0\" y=\"84.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">de onde vêm, e o que</text><text x=\"384.0\" y=\"102.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">têm de estranho?</text><path d=\"M384.0 120.0 L516.0 120.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"384.0\" y=\"142.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">na Ipê:</text><text x=\"384.0\" y=\"166.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o resultado do</text><text x=\"384.0\" y=\"186.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">empréstimo chega meses</text><text x=\"384.0\" y=\"206.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">depois; os recusados</text><text x=\"384.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">nunca mais aparecem</text><path d=\"M530.0 180.0 L546.0 180.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M546.0 180.0 L537.9 183.9 L537.9 176.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"548.0\" y=\"30.0\" width=\"156.0\" height=\"300.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"56.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" font-weight=\"600\" fill=\"var(--paper-dim)\">4</text><text x=\"582.0\" y=\"55.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">a armadilha</text><text x=\"560.0\" y=\"84.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">qual é a típica</text><text x=\"560.0\" y=\"102.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">deste setor?</text><path d=\"M560.0 120.0 L692.0 120.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"560.0\" y=\"142.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">na Ipê:</text><text x=\"560.0\" y=\"166.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma carteira que cresce</text><text x=\"560.0\" y=\"186.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">parece segura: o</text><text x=\"560.0\" y=\"206.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">empréstimo novo ainda</text><text x=\"560.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">não teve tempo de atrasar</text><text x=\"360.0\" y=\"352.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">As aulas 18 a 21 fazem as mesmas quatro perguntas ao varejo, à saúde, à indústria e ao regulador.</text></svg>", "caption": "As quatro perguntas, respondidas para uma financeira. A quarta é aquela em que um analista de fora do setor cai, e as três primeiras são o jeito de vê-la chegando."}
```

## A Ipê Crédito

A organização desta aula é inventada, como todas deste curso. **A Ipê Crédito é uma financeira de
crédito ao consumidor de São Paulo** com dois produtos: um empréstimo pessoal, pago em parcelas
mensais, que ela lançou em janeiro de 2024, e um cartão de crédito. A chefe de BI é a Fernanda Okada.
Uma financeira é um bom primeiro setor para ler, porque o produto dela é dinheiro, então quase tudo o que
ela guarda já é número.

**As decisões.** A Ipê decide, sem parar: se aprova um pedido, quanto emprestar e a que taxa de juros;
que limite dar a um cartão; se deixa passar ou bloqueia uma compra no cartão como possível fraude; quanto
gastar para ganhar um cliente; e o que fazer com o cliente que para de pagar. As quatro primeiras
acontecem milhares de vezes por dia, a maioria por regras e modelos que a equipe de BI mede, e não opera.

**Os indicadores.** Para a empresa como um todo, as receitas e os custos como razões do dinheiro
emprestado: margem financeira, custo do risco, índice de eficiência. Para o crédito, taxas de
inadimplência lidas por safra. Para a fraude, quantos alertas acertam e quantos clientes bons cada um
pega. Para os clientes, o valor ao longo da vida contra o custo de adquiri-los. As próximas quatro seções
tratam de um cada.

**Os dados.** Contratos e parcelas vêm do sistema de crédito, as compras no cartão vêm da processadora,
e muito do que a Ipê sabe sobre quem pede crédito vem dos birôs de crédito. **O que eles têm de estranho
é o tempo e a ausência.** O resultado de uma decisão de crédito chega meses depois dela, quando o cliente
paga ou para de pagar. A fraude muitas vezes só se confirma semanas depois da compra, quando o titular
de verdade a contesta. E um pedido que a Ipê recusou nunca mais aparece: ninguém sabe se aquela pessoa
teria pago, então os dados só descrevem os clientes que a Ipê escolheu. São também dados financeiros
pessoais, protegidos pela LGPD (aulas 6 e 7 de `data-governance`), e a Ipê reporta sobre eles ao Banco
Central, assunto da aula 21.

**A armadilha.** Junte as três primeiras. Os resultados chegam tarde, então os empréstimos mais novos
ainda não tiveram tempo de dar errado. Uma financeira que cresce tem muitos empréstimos novos. **Então
uma carteira que cresce parece segura**: a inadimplência dela é baixa porque a maior parte é jovem, não
porque é boa. A seção de risco de crédito desta aula mostra isso nos números da Ipê, e a seção de fraude
mostra a outra armadilha deste setor, que é a coisa caçada ser rara.
