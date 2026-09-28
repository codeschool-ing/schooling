---
title: RTO e RPO, para a frente e para trás a partir do incidente
version: 1
---

A disponibilidade descreve um mês. Dois outros números descrevem um dia ruim, e são eles que orientam um
plano para esse dia. O **RTO**, recovery time objective, objetivo de tempo de recuperação, é quanto tempo o
serviço pode ficar fora depois de um incidente. O **RPO**, recovery point objective, objetivo de ponto de
recuperação, é quantos dados podem se perder, medido em tempo: quanto antes do incidente os dados
restaurados podem terminar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 208\" role=\"img\" aria-label=\"Um eixo de tempo. Um ponto marca a última cópia boa dos dados; mais adiante uma linha marca o incidente; mais adiante ainda uma linha marca a volta do serviço. Entre a última cópia boa e o incidente, uma chave diz: RPO, o que foi gravado aqui se perde. Entre o incidente e a volta do serviço, uma chave diz: RTO, o serviço está fora, dividido em perceber, decidir e restaurar.\"><defs><marker id=\"rr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 110 L700 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rr-ah)\"></path><text x=\"700\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><circle cx=\"150\" cy=\"110\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"150\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">última cópia boa</text><path d=\"M380 40 L380 118\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"380\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o incidente</text><path d=\"M610 40 L610 118\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"610\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">serviço de volta</text><path d=\"M150 76 L150 70 L380 70 L380 76\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"265.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">RPO: o que foi gravado aqui se perde</text><path d=\"M380 146 L380 152 L610 152 L610 146\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"495.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">RTO: o serviço está fora</text><text x=\"418.3333333333333\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">perceber</text><text x=\"495.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">decidir</text><text x=\"571.6666666666666\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">restaurar</text><path d=\"M456.6666666666667 182 L456.6666666666667 198\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M533.3333333333334 182 L533.3333333333334 198\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "O RPO olha para trás a partir do incidente e o RTO para a frente. A frequência das cópias define o primeiro; a rapidez com que a falha é percebida e o serviço é movido define o segundo."}
```

O erro comum com o RTO é lê-lo como o tempo de consertar o que quebrou. **O RTO é o tempo de restaurar o
serviço, que muitas vezes fica em outro lugar.** Quando o HAProxy de `lb1` morreu na aula 16, o serviço
voltou em 2,694 segundos, em `lb2`, enquanto `lb1` continuou quebrado até alguém reiniciá-lo. O conserto e
a recuperação são relógios separados, e só o segundo está na promessa.

O erro comum com o RPO é esquecer que ele existe. Um sistema que não guarda dados tem RPO zero de graça, e
é por isso que os failovers medidos até aqui pareceram tão limpos. Qualquer coisa que guarde o que os
usuários fazem precisa responder à pergunta explicitamente, e a resposta é definida pela frequência com
que os dados são copiados para outro lugar, que é a última seção desta aula.

## Os dois números para os sistemas deste curso

| sistema e falha | RTO | RPO |
|---|---|---|
| gateway do escritório, cabo do roteador puxado (aula 15) | 3,264 s medidos | nada a perder: um roteador não guarda dados |
| balanceador, HAProxy morto (aula 16) | 2,694 s medidos | as conexões em andamento por `lb1` se perderam |
| um banco de dados com backup noturno, restaurado à mão | horas: buscar, restaurar, conferir | até 24 horas de gravações |
| um banco de dados com réplica síncrona, promovida automaticamente | de segundos a minutos | nada confirmado se perde |

A segunda linha mostra que um RPO não é só assunto de banco de dados. O que vivia na memória
da máquina que falhou, um download pela metade ou uma sessão guardada na RAM, se foi, e a aula 16 terminou
no que é preciso para guardar esse tipo de estado num lugar que sobreviva.

**Um RTO e um RPO pertencem a uma falha, não a um sistema.** O mesmo banco de dados tem um par de respostas
para um disco que morre, outro para um data center que alaga, e outro para uma pessoa que apaga uma tabela
por engano. A replicação resolve os dois primeiros, se a cópia estiver em outro lugar, e não faz nada pelo
terceiro, já que copia a exclusão tão fielmente quanto copia todo o resto. Um plano que lista um RTO e um
RPO para "o banco de dados" respondeu a uma dessas três perguntas e supôs as outras.
