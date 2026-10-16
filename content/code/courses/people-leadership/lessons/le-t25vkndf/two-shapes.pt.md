---
title: A liderança técnica e a gestão de engenharia
version: 1
---

"Liderar um time de engenharia" descreve dois trabalhos diferentes, e boa parte da confusão nesse
assunto vem de tratá-los como um só. **Um deles responde por como o software é construído. O outro
responde pelas pessoas que o constroem e pelo que elas entregam.** Um time pequeno pode dar os dois
a uma pessoa só. Um time de sete em geral não pode, e a primeira conversa que a Renata precisava ter
era sobre qual dos dois era o dela.

## Dois trabalhos, muitas vezes sob uma palavra

A **liderança técnica** (o *tech lead*) é o engenheiro que lidera. Ela é dona da direção técnica do
time: o design do que está sendo construído, o padrão de qualidade na revisão, a decisão entre duas
abordagens quando o time não chega a um acordo e o desbloqueio de quem está travado num problema
técnico. Ela ainda escreve código, e a credibilidade dela depende disso, porque uma decisão técnica
de quem não trabalha mais no código é um palpite com autoridade.

A **gestão de engenharia** (o *engineering manager*) responde pelo time como um grupo de pessoas. É
dona da contratação, do crescimento, do feedback e do desempenho, dos compromissos que o time assume
com o resto da empresa, do processo com que ele trabalha e de as pessoas ainda estarem lá, e bem,
daqui a um ano. Algumas pessoas nesse papel escrevem código, a maioria escreve muito pouco, e quase
nenhuma deveria escrever código de que os planos do time dependem, pelo motivo que a aula 1 deu: a
semana delas é picada em pedaços, e o caminho crítico não pode esperar pelos buracos.

As empresas nomeiam esses trabalhos de forma inconsistente. Algumas chamam o primeiro de staff
engineer, principal, arquiteto. Algumas juntam os dois num papel só, com um título como *tech lead
manager*, que funciona para um time de três ou quatro pessoas e começa a forçar bem antes de dez. O
livro *Staff Engineer* (2021), de Will Larson, lista a liderança técnica como um de quatro formatos
que o trabalho de uma pessoa engenheira sênior assume, ao lado do arquiteto, do solucionador e do
braço direito, o que já diz alguma coisa: **liderar tecnicamente é um trabalho sênior de
engenharia, não um trabalho júnior de gestão.**

## O que cada uma é dona, e onde se sobrepõem

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-shapes\" aria-label=\"Duas áreas que se sobrepõem. A liderança técnica, à esquerda, é dona da direção técnica, do design, do padrão de qualidade na revisão e do desbloqueio técnico, e ainda escreve código. A gestão de engenharia, à direita, é dona das decisões de contratação, do crescimento e do feedback, do desempenho, dos compromissos do time com a empresa, do processo e de as pessoas ficarem. Na interseção ficam quatro coisas em que as duas mexem: estimativas e planos, entrevistas, incidentes e quem trabalha em quê.\"><rect x=\"30.0\" y=\"50.0\" width=\"400.0\" height=\"225.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><rect x=\"290.0\" y=\"50.0\" width=\"400.0\" height=\"225.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><rect x=\"290.0\" y=\"50.0\" width=\"140.0\" height=\"225.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M290.0 50.0 L290.0 275.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M430.0 50.0 L430.0 275.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M290.0 50.0 L430.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M290.0 275.0 L430.0 275.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"160.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">liderança técnica</text><text x=\"560.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">gestão de engenharia</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">as duas mexem</text><text x=\"50.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">direção técnica</text><text x=\"50.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o design</text><text x=\"50.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o padrão na revisão</text><text x=\"50.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desbloqueio técnico</text><text x=\"50.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ainda escreve código</text><text x=\"670.0\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">decisões de contratação</text><text x=\"670.0\" y=\"119.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">crescimento e feedback</text><text x=\"670.0\" y=\"152.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desempenho</text><text x=\"670.0\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">compromissos com a empresa</text><text x=\"670.0\" y=\"218.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o processo do time</text><text x=\"670.0\" y=\"251.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">as pessoas ficarem</text><text x=\"360.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">estimativas</text><text x=\"360.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">e planos</text><text x=\"360.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">entrevistas</text><text x=\"360.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">incidentes</text><text x=\"360.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quem trabalha</text><text x=\"360.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">em quê</text></svg>", "caption": "As duas metades raramente estão em disputa. O meio é onde duas pessoas agem ao mesmo tempo, e discordam na frente do time."}
```

As duas metades da figura são claras o bastante. O meio é onde está o atrito, e vale olhar item por
item.

- **Estimativas e planos.** A liderança técnica sabe o que o trabalho envolve; a gestão sabe do que a
  empresa precisa e quando. Um plano feito por uma delas sozinha erra numa direção previsível.
- **Entrevistas.** A liderança técnica julga melhor a habilidade técnica; a gestão é dona da decisão
  de contratar e do resto do que o cargo exige.
- **Incidentes.** Durante um, quem está mais bem posicionado para liderar a resposta técnica lidera.
  Depois dele, a gestão é dona de o trabalho de acompanhamento entrar no planejamento.
- **Quem trabalha em quê.** A liderança técnica sabe quem conseguiria fazer uma tarefa. A gestão sabe
  quem precisa dela para crescer, quem está sobrecarregado e quem pediu algo diferente na última 1:1.

Nenhum desses itens tem um dono correto em geral. Cada um precisa de um dono na Caju, por escrito,
porque o custo de ninguém ser dono é as duas pessoas fazerem, e discordarem na frente do time.

## Como o Agenda dividiu

Na rodada de escuta, a Renata fez ao Diego a pergunta que a aula 1 recomendou, em particular: o que
ele queria do próximo ano. A resposta a surpreendeu. Ele tinha querido o cargo de gestão no sentido
de que queria decidir como o software do Agenda era construído, e imaginava que isso vinha junto.
Quando os dois listaram o que o cargo de gestão de fato continha, ele não queria quase nada daquilo.
**Ele queria a metade esquerda da figura, e ninguém nunca tinha oferecido essa metade sem a
direita.**

Então o Agenda ficou com os dois papéis, em duas pessoas: o Diego como liderança técnica, a Renata
como gestora de engenharia. A Renata não passa por cima do Diego em design, e o Diego continua se
reportando a ela como gestora. Essa combinação é comum e funciona, mas só com as duas próximas
seções: uma ideia clara do que cada pessoa está abrindo mão, e um acordo escrito sobre o meio.
