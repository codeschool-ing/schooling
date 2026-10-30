---
title: O Beam escreve o pipeline, o Dataflow roda
version: 1
---

**O Dataflow não é algo que se programa. Você escreve o programa no Apache Beam, e o Dataflow é um
dos lugares onde um programa do Beam pode rodar.** O Beam é uma biblioteca de código aberto, para
Python, Java e Go, que descreve um cálculo sobre uma coleção de registros: ler, mudar, agrupar,
gravar. Um **runner** é o que executa essa descrição. O Dataflow é o runner do Google, um serviço
gerenciado que liga máquinas virtuais para fazer o trabalho e as tira depois. Outros rodam o mesmo
programa no Spark, no Flink, ou dentro do processo Python do seu laptop, que é onde esta aula o roda.

A imagem errada é que um job de streaming e um job em lote são dois programas. A Quitanda tem as
duas formas da mesma pergunta: a exportação noturna dos eventos de pedido do dia, um arquivo em
`quitanda-raw-prod`, e os mesmos eventos publicados um a um num tópico do Pub/Sub à medida que
acontecem, o assunto da aula 19. Feita a qualquer um dos dois, a pergunta é quantos pedidos cada
bairro fez, e de quanto. **O modelo do Beam é que um arquivo e um fluxo são ambos coleções, e uma
delas termina**, e que os passos entre ler e gravar não precisam saber qual.

## Quatro palavras

| palavra | o que é |
|---|---|
| **pipeline** | o cálculo inteiro, montado como um grafo e depois entregue a um runner |
| **PCollection** | uma coleção de elementos que passa entre dois passos; **limitada** se termina, como um arquivo, **ilimitada** se não termina, como uma assinatura |
| **PTransform** | um passo: `Map` e `Filter` pegam um elemento de cada vez, `FlatMap` devolve quantos quiser, `GroupByKey` e `CombinePerKey` juntam todos os elementos com a mesma chave |
| **runner** | o que executa o grafo: o DirectRunner aqui, o Dataflow no Google Cloud |

**Um programa do Beam monta o grafo primeiro e roda depois.** A linha
`lines | 'Parse' >> beam.FlatMap(parse)` não analisa nada quando o Python chega nela; ela
acrescenta ao grafo um passo chamado `Parse` e devolve uma PCollection que vai guardar a saída dele.
Só quando o pipeline roda é que o runner decide como executar os passos: num processo só, ou
espalhados por cem workers que pegam cada um uma fatia da entrada. Essa separação é o que deixa o
mesmo programa rodar num laptop e no Dataflow, e é também por isso que um erro no código de um
passo aparece quando o pipeline roda, não quando a linha é lida.

**Cada elemento também carrega um timestamp e uma janela.** Uma linha lida de um arquivo não recebe
horário com significado e vai para a **janela global**, que guarda tudo. Um elemento de um fluxo
carrega um horário, e um fluxo que é agrupado precisa ser cortado em janelas antes, por um motivo
que a quarta seção mostra com um erro. A aula 22 trata só de janelas; esta usa a mais simples, uma
janela fixa de um minuto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um pipeline do Beam desenhado com dois pares de pontas. Em lote ele lê um arquivo com ReadFromText e grava arquivos com WriteToText. Em fluxo ele lê o Pub/Sub com ReadFromPubSub, corta as mensagens em janelas de 60 segundos e grava no Pub/Sub com WriteToPubSub. Entre as pontas fica PlacedTotals, os mesmos cinco passos nos dois: Parse, Placed, Key, Add e Format, em que Add é a combinação. Cada ponta recebe os totais e as linhas ilegíveis.\" data-fig=\"gcp21-pipeline\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lote: um arquivo, uma coleção que termina</text><rect x=\"20\" y=\"32\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ReadFromText</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fluxo: Pub/Sub, uma coleção que não termina</text><rect x=\"20\" y=\"162\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ReadFromPubSub</text><rect x=\"20\" y=\"204\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">WindowInto(60 s)</text><line x1=\"105\" y1=\"192\" x2=\"105.0\" y2=\"203.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"105.0,203.0 102.4,197.6 107.6,197.6\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"240\" y=\"70\" width=\"250\" height=\"120\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"365\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PlacedTotals, igual nos dois</text><rect x=\"252\" y=\"112\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Parse</text><rect x=\"299\" y=\"112\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"319\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Placed</text><line x1=\"292\" y1=\"125\" x2=\"298.0\" y2=\"125.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,125.0 292.6,127.6 292.6,122.4\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"346\" y=\"112\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"366\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Key</text><line x1=\"339\" y1=\"125\" x2=\"345.0\" y2=\"125.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"345.0,125.0 339.6,127.6 339.6,122.4\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"393\" y=\"112\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"413\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Add</text><line x1=\"386\" y1=\"125\" x2=\"392.0\" y2=\"125.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"392.0,125.0 386.6,127.6 386.6,122.4\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"440\" y=\"112\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Format</text><line x1=\"433\" y1=\"125\" x2=\"439.0\" y2=\"125.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"439.0,125.0 433.6,127.6 433.6,122.4\" fill=\"var(--wire)\" stroke=\"none\"></polygon><line x1=\"190\" y1=\"47\" x2=\"251.0\" y2=\"118.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"251.0,118.0 245.5,115.6 249.5,112.2\" fill=\"var(--wire)\" stroke=\"none\"></polygon><line x1=\"190\" y1=\"219\" x2=\"251.0\" y2=\"132.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"251.0,132.0 250.0,137.9 245.8,134.9\" fill=\"var(--wire)\" stroke=\"none\"></polygon><text x=\"413\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">Combine</text><rect x=\"540\" y=\"32\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">WriteToText</text><rect x=\"540\" y=\"162\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">WriteToPubSub</text><line x1=\"491\" y1=\"118\" x2=\"539.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"539.0,50.0 538.0,55.9 533.8,52.9\" fill=\"var(--wire)\" stroke=\"none\"></polygon><line x1=\"491\" y1=\"132\" x2=\"539.0\" y2=\"174.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"539.0,174.0 533.2,172.4 536.7,168.5\" fill=\"var(--wire)\" stroke=\"none\"></polygon><text x=\"540\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">totais + linhas ilegíveis</text><text x=\"540\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">totais + linhas ilegíveis</text></svg>", "caption": "O pipeline desta aula. O meio é uma transformação composta, escrita uma vez; o fluxo acrescenta uma janela na entrada, o único passo de que o lote não precisa."}
```

## Instalando o Beam

O terminal é o da aula 1, depois de "Every time you open a terminal", com o ambiente virtual ativo.
O pacote Python do Beam, numa versão fixada como o resto do laboratório:

```sh
pip install -q apache-beam==2.76.0
```

```
ana@laptop:~/gcp$ pip install -q apache-beam==2.76.0
ana@laptop:~/gcp$ python3 -c "import apache_beam; print(apache_beam.__version__)"
2.76.0
ana@laptop:~/gcp$ pip list 2>/dev/null | grep -E '^protobuf '
protobuf                           6.33.6
```

**O pacote simples, sem extras, basta para esta aula.** Ler e gravar no Pub/Sub precisa da
biblioteca do Pub/Sub do Google, que a aula 1 já pôs no ambiente. O que falta ao pacote simples é o
cliente do próprio DataflowRunner, que vem com `apache-beam[gcp]`; a quinta seção mostra o comando
que precisaria dele, e este laboratório nunca o roda. O pip também troca o `protobuf` do ambiente,
que a aula 1 instalou na 7.36.2, pela versão mais antiga da última linha, a mais nova que o Beam
2.76.0 aceita. Ele não diz nada, porque `-q` pede silêncio, e as bibliotecas do Google da aula 1
funcionam com essa versão também, como as execuções com Pub/Sub mais adiante mostram.

## O DirectRunner, e o runner que ele tenta primeiro

**O `DirectRunner` do Beam 2.76.0 é uma chave, não um runner só.** Quando pedem que rode um
pipeline, ele tenta primeiro o **Prism**, um runner local mais novo escrito em Go, que ele baixa do
GitHub na primeira vez. Só se o Prism não conseguir rodar o pipeline é que ele volta para os runners
de dentro do Python. Um pipeline de uma linha com o log do próprio Beam ligado mostra a troca, num
laptop sem caminho para o GitHub:

```
ana@laptop:~/gcp$ python3 -c "import logging,apache_beam as beam; logging.basicConfig(level=logging.INFO); p=beam.Pipeline(); p|beam.Create([1])|beam.Map(print); p.run().wait_until_finish()" 2>&1 | head -20
INFO:root:Missing pipeline option (runner). Executing pipeline using the default runner: DirectRunner.
INFO:apache_beam.runners.direct.direct_runner:Running pipeline with PrismRunner.
INFO:apache_beam.runners.worker.worker_pool_main:Listening for workers at localhost:38895
INFO:apache_beam.runners.portability.prism_runner:Downloading prism from https://github.com/apache/beam/releases/download/v2.76.0/apache_beam-v2.76.0-prism-linux-amd64.zip
INFO:apache_beam.runners.direct.direct_runner:Exception with PrismRunner:
 Unable to fetch remote prism binary at https://github.com/apache/beam/releases/download/v2.76.0/apache_beam-v2.76.0-prism-linux-amd64.zip: <urlopen error [Errno -3] Temporary failure in name resolution>

INFO:apache_beam.runners.direct.direct_runner:Falling back to DirectRunner
INFO:apache_beam.runners.worker.statecache:Creating state cache with size 104857600
1
```

**Essa volta depende da rede**, e isso a torna uma base ruim para uma aula: num laptop que alcança
o GitHub, o mesmo comando baixa o Prism e roda nele, e o comportamento do Prism não é o que estas
transcrições registraram. Por isso o programa da próxima seção nomeia o runner,
`BundleBasedDirectRunner`, o DirectRunner que roda dentro do Python e aceita streaming, e toda
execução desta aula e da próxima usa ele. **É um runner para testar, não para volume**: um
processo, poucas threads, tudo na memória. É o lugar certo para descobrir se um pipeline está
correto, e o lugar errado para descobrir se ele é rápido.
