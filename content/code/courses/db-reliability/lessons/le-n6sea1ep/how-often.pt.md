---
title: Com que frequência, e a aritmética da retenção
version: 1
---

"Regularmente" não é um cronograma. O intervalo entre ensaios é um número com uma consequência que
dá para calcular: **é o tempo máximo que um backup quebrado passa despercebido.** Um ensaio por mês
quer dizer que um backup que parou de funcionar no dia seguinte a um ensaio é descoberto até um mês
depois.

Esse intervalo tem que caber dentro de outro. Quando o ensaio acha um backup quebrado, você precisa
de um bom, mais antigo que a quebra, para recorrer, e você tem exatamente quantos a retenção guarda:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma linha do tempo de seis semanas, com um backup full no início de cada semana. Os backups quebram no começo da semana 3. Um ensaio mensal roda no fim da semana 6 e descobre a falha. A janela de retenção, os dois últimos full, cobre só as semanas 5 e 6, então todo backup ainda guardado foi feito depois da quebra.\"><defs><marker id=\"l7w-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M30 90 L700 90\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7w-wi)\"></path><circle cx=\"40\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"94\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">semana 1</text><circle cx=\"148\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"202\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">semana 2</text><circle cx=\"256\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"310\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">semana 3</text><circle cx=\"364\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"418\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">semana 4</text><circle cx=\"472\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"526\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">semana 5</text><circle cx=\"580\" cy=\"90\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"634\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">semana 6</text><text x=\"40\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">backups full semanais</text><path d=\"M270 40 L270 84\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"270\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">os backups quebram</text><path d=\"M686 40 L686 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"640\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ensaio mensal</text><text x=\"640\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">descobre</text><path d=\"M472 140 L472 148 L700 148 L700 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"586\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">retenção: os dois últimos full</text><rect x=\"330\" y=\"182\" width=\"370\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"515\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">todo backup guardado foi feito depois da quebra</text></svg>", "caption": "Um ensaio mensal contra duas semanas de retenção. Quando o ensaio descobre a falha, todo backup anterior a ela já expirou, e não sobrou nada bom para restaurar."}
```

Com dois backups full guardados e um full por semana, a retenção alcança umas duas semanas para
trás. Um ensaio mensal acha uma falha de até um mês, e a essa altura **todo backup feito antes da
falha já expirou**, e o que o ensaio descobre é que você está há semanas sem um backup restaurável e
continua sem nenhum. A regra é simples e é quebrada com frequência: **o intervalo entre ensaios tem
que ser menor que a janela de retenção**, com folga para o tempo que leva até alguém notar o
resultado.

## Um cronograma que vale a pena ter

| quando | o quê |
|---|---|
| **toda semana, sem ninguém olhando** | o script desta lição, ou um equivalente, contra o backup mais recente |
| **depois de toda mudança nos backups** | uma configuração nova, um repositório novo, um upgrade do PostgreSQL ou da ferramenta |
| **todo trimestre, por uma pessoa** | um ensaio completo feito por alguém que não montou o esquema, seguindo o procedimento escrito (lições 23 e 24) |
| **quando os dados crescem** | um ensaio no banco maior, para medir o tempo de novo |

O ensaio semanal pega backups quebrados. O trimestral pega o que o script não consegue: um
procedimento que só funciona na cabeça de quem o escreveu, um passo que precisa de uma senha que
mais ninguém tem, um servidor de restauração que já não tem espaço para os dados.

Um ensaio custa um segundo servidor enquanto roda, e esse é o motivo que a maioria das equipes dá
para não rodar um. Neste laboratório o segundo servidor sai de graça. Num sistema de verdade, é uma
máquina temporária que vive por uma hora, o que é uma conta pequena perto da de descobrir no dia.
