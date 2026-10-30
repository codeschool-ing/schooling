---
title: Um cluster de máquinas suas, com o Spark já instalado
version: 1
---

**O Dataproc não é um serviço que roda Spark por você, do jeito que o Dataflow roda Beam.** Um
cluster Dataproc é um conjunto de máquinas virtuais do Compute Engine no seu projeto, iniciadas a
partir de uma imagem que já traz Hadoop, Spark e os vizinhos instalados e configurados para se
encontrarem. O Dataflow, na aula 21, esconde as máquinas: você submete um pipeline, e o serviço
decide quantos workers ele ganha e cobra o tempo em que rodaram. O Dataproc entrega as máquinas.
Você escolhe o tipo e a quantidade, e elas existem do minuto em que ligam ao minuto em que você as
apaga. Você paga cada segundo disso duas vezes: uma ao Compute Engine pela máquina e outra ao
Dataproc pela taxa de gestão sobre os processadores dela.

**O nome está mudando, e os comandos não.** A página de preços do Google, lida em 2026-10-30, chama
o produto de *Managed Service for Apache Spark (formerly Dataproc)*. A linha de comando, a API e os
caminhos da documentação continuam dizendo `dataproc`, e o mesmo vale para todo comando desta aula,
porque é isso que você digita.

Essa única diferença em relação ao Dataflow explica a maior parte desta aula. Como as máquinas são
suas, você pode instalar qualquer biblioteca nelas, mantê-las ligadas entre um job e outro, escolher
um tipo de máquina mais barato e entrar numa delas quando algo dá errado. Como as máquinas são suas,
um cluster que ninguém lembrou de apagar custa o mesmo às quatro da manhã e às quatro da tarde.

## Três papéis, e por que são diferentes

**Toda máquina de um cluster tem um de três papéis, e o papel decide o que se perde quando aquela
máquina some.**

- o **master** coordena. Ele roda o ResourceManager do YARN, que distribui memória e processadores
  entre os jobs, e o NameNode do HDFS, que sabe onde está cada bloco do sistema de arquivos do
  próprio cluster. Um cluster padrão tem um; um cluster de alta disponibilidade tem três, para que
  perder um seja suportável;
- um **worker primário** trabalha e guarda. Ele roda um NodeManager, que executa as tarefas que o
  YARN lhe dá, e um DataNode, que guarda blocos do HDFS. Um cluster padrão tem pelo menos dois;
- um **worker secundário** só trabalha. Ele roda um NodeManager e não guarda bloco nenhum do HDFS.
  É opcional, um cluster pode não ter nenhum, e por padrão é uma máquina que o Google pode tomar de
  volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um cluster Dataproc desenhado como uma borda tracejada com três colunas de máquinas. O master roda ResourceManager e NameNode; se cai, o cluster acaba, e ele é uma VM padrão. Dois workers primários rodam DataNode e NodeManager; se um cai, leva blocos do HDFS junto, e eles são VMs padrão. Dois workers secundários rodam só NodeManager; se um cai, custa algum tempo, e eles são Spot ou preemptivos. Fora do cluster, uma seta com o rótulo conector aponta para gs://quitanda-raw-prod, onde ficam os dados.\" data-fig=\"l23-roles\"><defs><marker id=\"ah-l23-roles\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"480\" height=\"255\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um cluster Dataproc</text><rect x=\"40\" y=\"60\" width=\"135\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"107.5\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">master</text><text x=\"107.5\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ResourceManager</text><text x=\"107.5\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NameNode</text><text x=\"107.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se cai: o cluster acaba</text><text x=\"107.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">VM padrão</text><rect x=\"195\" y=\"60\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"262.5\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">worker primário</text><text x=\"262.5\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DataNode</text><text x=\"262.5\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><rect x=\"195\" y=\"135\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"262.5\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">worker primário</text><text x=\"262.5\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DataNode</text><text x=\"262.5\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><text x=\"262.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se cai: blocos do HDFS</text><text x=\"262.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">VM padrão</text><rect x=\"350\" y=\"60\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"417.5\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">secundário</text><text x=\"417.5\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><rect x=\"350\" y=\"135\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"417.5\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">secundário</text><text x=\"417.5\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><text x=\"417.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se cai: algum tempo</text><text x=\"417.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Spot ou preemptiva</text><rect x=\"555\" y=\"100\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">gs://quitanda-raw-prod</text><text x=\"630\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os dados ficam aqui</text><line x1=\"500\" y1=\"135\" x2=\"553\" y2=\"135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l23-roles)\"></line><text x=\"527\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">conector</text></svg>", "caption": "O que um nó roda decide quanto custa perdê-lo, e esse custo decide quais nós podem ser os que o Google pode tomar de volta.", "same": ["master"]}
```

**A diferença entre um worker primário e um secundário é o HDFS.** Tire um secundário e as tarefas
que ele rodava vão para outra máquina e rodam de novo: o job fica mais lento, e nada se perde. Tire
um primário e os blocos que ele guardava vão junto. O HDFS mantém cópias de cada bloco em outros
workers primários, e é isso que deixa um cluster sobreviver a uma perda dessas, mas encolher o grupo
primário significa mover esses blocos antes. Um master que some encerra um cluster padrão. Essa
ordem, de "custa algum tempo" a "custa tudo", decide quais máquinas podem ser as baratas que o Google
pode retomar, e a próxima seção usa isso.

## Deixe os dados fora do cluster

**No Dataproc, os dados que um job lê e escreve ficam no Cloud Storage, não no HDFS.** Toda imagem
traz o **conector do Cloud Storage**, que deixa o Spark e o Hadoop lerem um caminho `gs://` como se
fosse um sistema de arquivos, então os pedidos em `gs://quitanda-raw-prod/raw/orders/` são lidos
onde estão e o resultado é escrito em `quitanda-curated-prod`. O HDFS dos workers primários vira
espaço de rascunho: arquivos de shuffle, resultados intermediários, tudo o que o job consegue
refazer.

É isso que torna um cluster descartável. Um cluster cuja única cópia de algo está no HDFS nunca pode
ser apagado, porque apagá-lo apaga os dados. Um cluster que guarda tudo no Cloud Storage pode ser
criado para o job de uma noite e apagado quando o job termina, e o cluster da noite seguinte encontra
tudo onde o anterior deixou. O resto desta aula supõe o segundo tipo.

## Do que um cluster é feito, como comando

Aqui está um cluster pequeno para o job noturno da Quitanda, como seria criado em São Paulo. **Ele
não foi rodado aqui**: nenhum emulador responde pelo Dataproc, e num projeto de verdade este comando
começa a cobrar quatro máquinas no momento em que retorna.

```sh
gcloud dataproc clusters create quitanda-spark \
  --region=southamerica-east1 \
  --image-version=2.2-debian12 \
  --master-machine-type=n2-standard-4 --master-boot-disk-size=100GB \
  --num-workers=2 --worker-machine-type=n2-standard-4 --worker-boot-disk-size=100GB
```

**Cada linha é uma decisão.** A região é onde as máquinas rodam, e deve ser a região dos buckets,
para que ler os pedidos não atravesse fronteira de região nem pague transferência por isso, o
assunto da aula 5. A **versão da imagem** fixa a versão de tudo nas máquinas: Debian, Java, Hadoop,
Spark, Hive e o resto. Dois clusters na mesma imagem rodam o mesmo software, e atualizar o Spark é
criar um cluster numa imagem mais nova, nunca atualizar um no lugar. O tipo de máquina,
`n2-standard-4`, tem 4 vCPU e 16 GiB de memória, e o disco de boot tem o tamanho escrito porque o
disco é cobrado por gibibyte enquanto a máquina existir.

**Um cluster também pode ser menor que isso.** `--single-node` cria um master que é o próprio
worker, uma máquina no total, o que basta para desenvolvimento e para um job pequeno o bastante para
uma máquina terminar. Ele não pode ter workers secundários e não sobrevive a perder a única máquina,
que são justamente os dois assuntos da próxima seção.
