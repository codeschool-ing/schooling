---
title: O arranjo, com preço
version: 1
---

**A conta de um lago tem três linhas que o arranjo dos arquivos define**: os bytes que cada pergunta
lê, os arquivos que cada pergunta abre e os bytes guardados no disco para versões que ninguém lê.
Esta seção põe as medidas da lição em cada linha. Nada aqui foi cobrado nem executado no Azure: as
contagens são desta lição, e os preços são **ilustrativos**, números redondos para fazer a soma, que a
tabela de preços da lição 1 substitui pelos reais.

## Bytes: o que a partição e as estatísticas economizam

A pergunta sobre um dia é a que um painel faz, e o da Quitanda a faz a cada dez minutos, 4.464 vezes
em outubro. Num lago mil vezes maior que este, cada leitura cresce mil vezes, e a **um preço
ilustrativo de 5 USD por terabyte processado**, o formato da conta serverless do Synapse da lição 16:

| arranjo | lido aqui | uma pergunta ×1.000 | um mês de perguntas | USD por mês |
|---|---:|---:|---:|---:|
| `one`: um arquivo, sem partições | 372.157 bytes | 372,2 MB | 1.661,3 GB | 8,31 |
| `by_day`: particionado por dia | 73.813 bytes | 73,8 MB | 329,5 GB | 1,65 |
| `daily`: um arquivo por dia, sem partições | 74.167 bytes | 74,2 MB | 331,1 GB | 1,66 |

**A partição e as estatísticas cortam a conta para um quinto cada uma, e cortam o mesmo tanto.** O que
as duas compram é um leitor que sabe, antes de abrir qualquer coisa, qual arquivo guarda o dia 15. A
pergunta do mês não ganha nada de nenhuma das duas, porque precisa de todos os dias; o que a ajuda é o
formato de colunas, que leu 396.833 dos 1.205.188 bytes do arquivo único.

## Arquivos: uma contagem que não cresce com os dados

**O número de arquivos é definido por quantas vezes a tabela é escrita, não por quanto há nela.** Com
mil vezes os pedidos, uma carga horária continua escrevendo 17 arquivos por dia; eles são maiores, e
são tantos quanto antes. Então o custo dos arquivos pequenos se conta melhor em arquivos abertos. Cada
um é pelo menos duas requisições de leitura à conta de armazenamento, uma para o rodapé e uma para as
colunas:

| pergunta | arranjo | arquivos abertos | requisições de leitura por mês, a 4.464 perguntas |
|---|---|---:|---:|
| um dia | `by_day` | 1 | 8.928 |
| um dia | `hourly` | 17 | 151.776 |
| o mês | `by_day` | 31 | 276.768 |
| o mês | `hourly`, antes da compactação | 527 | 4.705.056 |

A **um preço ilustrativo de 0,005 USD por 10.000 operações de leitura**, a última linha dá 2,35 USD por
mês e a de cima 0,14: pouco dinheiro para uma tabela e um painel, e dezessete vezes mais pelas mesmas
respostas. Isso cresce com cada tabela escrita assim e cada pergunta feita a ela, e não é o único
custo. No Fabric cada arquivo aberto também é tempo de capacidade, e o Direct Lake da lição 17 conta
arquivos contra os guardrails dele. Um escritor que faz commit a cada minuto deixa 1.440 arquivos por
dia em cada partição em que toca, e é aí que um lago fica lento sem ficar grande.

## Versões: o armazenamento que ninguém lê

**Antes do vacuum, a tabela `hourly` guardava 4.099.190 bytes no disco para uma tabela de
1.058.322**, quase quatro vezes o tamanho dela, tudo passado: os 527 arquivos pequenos que a
compactação substituiu. Cada reescrita deixa os arquivos antigos para trás até a retenção acabar:

- uma compactação noturna reescreve o dia que compacta, então sete dias de retenção guardam mais ou
  menos uma semana dessas reescritas;
- um delete reescreve todo arquivo que tinha uma linha apagada, o que é a tabela inteira quando há um
  arquivo e um dia quando a tabela é dividida por dia, 98.726 linhas copiadas contra 2.998 nesta lição;
- um apagamento por privacidade, a remoção dos pedidos de um cliente, toca cada dia em que o cliente
  comprou, e os arquivos antigos continuam guardando as linhas dele até o vacuum removê-los.

Esse último ponto é o que não é sobre dinheiro. **Uma linha apagada some da tabela na hora e do disco
só depois do vacuum.** Uma empresa que precisa apagar os dados de uma pessoa dentro de um prazo tem de
rodar o vacuum dentro dele, e uma retenção de sete dias são sete dias em que os arquivos antigos podem
ser lidos por qualquer um que leia a pasta ou volte no tempo.

## Como deve ser o lago da Quitanda

As medidas dão uma resposta para a tabela de pedidos:

- **um arquivo por dia, escrito em ordem**, particionado por `dt` ou acrescentado um dia de cada vez;
  no tamanho da Quitanda as estatísticas pulam tão bem quanto as pastas, e uma coluna de partição vale
  a pena quando uma ferramenta que lê só pastas, e não o log, vai ler a tabela;
- **compactação de cada dia depois da última carga dele**, para que escritas horárias ou em streaming
  nunca cheguem aos leitores como centenas de arquivos;
- **vacuum toda noite com o padrão de sete dias**, o que guarda uma semana de viagem no tempo e limita
  tanto o armazenamento quanto o tempo que uma linha apagada sobrevive;
- **nada lido da pasta por uma ferramenta que não lê o log**, porque essa ferramenta conta todas as
  versões ao mesmo tempo.

Cada uma dessas coisas é decidida quando a tabela é escrita e paga toda vez que ela é lida, e é por
isso que as próximas três lições, sobre os jobs que escrevem o lago, voltam a elas o tempo todo.
