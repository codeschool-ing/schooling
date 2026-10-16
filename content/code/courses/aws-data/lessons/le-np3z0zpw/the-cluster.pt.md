---
title: Um cluster de máquinas suas, com o Spark já instalado
version: 1
---

**O EMR não é um serviço que roda o Spark por você, como o Glue.** É um conjunto de máquinas EC2 na
sua conta, ligadas a partir de uma imagem que já traz Hadoop, Spark e os vizinhos deles instalados
e configurados para se encontrarem. O Glue, na lição 17, esconde as máquinas: você pede um número de
workers e paga pelo tempo que eles rodaram. O EMR entrega as máquinas. Você escolhe o tipo e a
quantidade, elas são suas do minuto em que ligam ao minuto em que você as para, e você paga cada um
desses minutos duas vezes, uma ao EC2 pela máquina e outra ao EMR pelo software que roda nela.

Essa diferença explica quase toda esta lição. Como as máquinas são suas, você pode instalar qualquer
biblioteca nelas, mantê-las ligadas entre um job e outro, escolher um tipo de máquina mais barato e
entrar numa delas quando algo dá errado. Como as máquinas são suas, um cluster que ninguém lembrou
de parar custa o mesmo às quatro da manhã e às quatro da tarde.

## Três papéis, e por que eles são diferentes

**Toda máquina de um cluster tem um de três papéis, e o papel decide o que se perde quando aquela
máquina some.** A documentação do EMR chama essas máquinas de nós:

- o **nó primário** coordena. Ele roda o ResourceManager do YARN, que distribui memória e
  processadores entre os jobs, e o NameNode do HDFS, que sabe onde mora cada bloco do sistema de
  arquivos do próprio cluster. Há um, ou três num cluster que precisa sobreviver à perda de um. A API
  ainda escreve o papel como `MASTER`, o nome antigo, e todos os comandos desta lição também;
- um **nó core** trabalha e guarda. Ele roda um NodeManager, que executa as tarefas que o YARN lhe
  dá, e um DataNode, que guarda blocos do HDFS. Um cluster tem pelo menos um;
- um **nó de tarefa** só trabalha. Ele roda um NodeManager e não guarda nada. É opcional, e um
  cluster pode não ter nenhum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um cluster EMR desenhado como uma borda tracejada com três colunas de máquinas. O nó primário roda ResourceManager e NameNode; se ele cai o cluster acaba, e ele é sob demanda. Dois nós core rodam cada um DataNode e NodeManager; se um cai, blocos do HDFS vão junto, e eles são sob demanda. Dois nós de tarefa rodam só NodeManager; se um cai o custo é algum tempo, e eles são Spot. Fora do cluster, uma seta com o rótulo EMRFS aponta para s3://quitanda-raw-prod, onde os dados ficam.\" data-fig=\"l24-roles\"><defs><marker id=\"ah-l24-roles\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"480\" height=\"255\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um cluster EMR</text><rect x=\"40\" y=\"60\" width=\"135\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"107.5\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">primário</text><text x=\"107.5\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ResourceManager</text><text x=\"107.5\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NameNode</text><text x=\"107.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se cai: o cluster acaba</text><text x=\"107.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">sob demanda</text><rect x=\"195\" y=\"60\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"262.5\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">core</text><text x=\"262.5\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DataNode</text><text x=\"262.5\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><rect x=\"195\" y=\"135\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"262.5\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">core</text><text x=\"262.5\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DataNode</text><text x=\"262.5\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><text x=\"262.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se cai: blocos do HDFS</text><text x=\"262.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">sob demanda</text><rect x=\"350\" y=\"60\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"417.5\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">tarefa</text><text x=\"417.5\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><rect x=\"350\" y=\"135\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"417.5\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">tarefa</text><text x=\"417.5\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><text x=\"417.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se cai: algum tempo</text><text x=\"417.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Spot</text><rect x=\"555\" y=\"100\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">s3://quitanda-raw-prod</text><text x=\"630\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os dados ficam aqui</text><line x1=\"500\" y1=\"135\" x2=\"553\" y2=\"135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l24-roles)\"></line><text x=\"527\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">EMRFS</text></svg>", "caption": "O que um nó roda decide quanto custa perdê-lo, e esse custo decide quais nós podem ser Spot.", "same": ["Spot", "core"]}
```

**A diferença entre core e tarefa é o HDFS.** Tire um nó de tarefa e as tarefas que ele rodava vão
para outra máquina e rodam de novo: o job fica mais lento, e nada se perde. Tire um nó core e os
blocos que ele guardava vão junto. O HDFS mantém cópias de cada bloco em outros nós core, e é isso
que deixa um cluster sobreviver a uma perda dessas, mas encolher o grupo core exige mover esses
blocos antes, e um nó core que some sem aviso pode derrubar o job que o estava lendo. Um nó primário
que some acaba com o cluster. Essa ordem, de "custa algum tempo" a "custa tudo", é o que decide
quais máquinas podem ser as baratas que a AWS pode tomar de volta, e a próxima seção usa isso.

## Deixe os dados fora do cluster

**No EMR, os dados que um job lê e escreve ficam no S3, não no HDFS.** O Spark no EMR lê um caminho
`s3://` diretamente, por uma camada que o EMR chama de EMRFS, então os pedidos em
`s3://quitanda-raw-prod/raw/orders/` são lidos onde estão e o resultado é escrito em
`quitanda-curated-prod`. O HDFS dos nós core vira espaço de rascunho: arquivos de shuffle,
resultados intermediários, qualquer coisa que o job consiga refazer.

É isso que torna um cluster descartável. Um cluster cuja única cópia de alguma coisa está no HDFS
nunca pode ser parado, porque pará-lo apaga os dados. Um cluster que guarda tudo no S3 pode ser
criado para o job de uma noite e encerrado quando o job acaba, e o cluster da noite seguinte encontra
tudo onde o anterior deixou. O resto desta lição supõe o segundo tipo, e a seção sobre steps mostra
como ele é.

**Todo job no EMR roda na release que você escolhe**, um rótulo como `emr-7.9.0`, que fixa as
versões de Spark, Hadoop, Hive e do resto. Dois clusters no mesmo rótulo rodam o mesmo software. O
Glue também fixa as versões, em menos combinações e sem como acrescentar uma biblioteca à própria
máquina, e esse é um dos motivos pelos quais uma equipe leva um job do Glue para o EMR. A última
seção desta lição pesa esse motivo contra os outros.
