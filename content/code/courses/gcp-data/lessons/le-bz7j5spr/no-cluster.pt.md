---
title: Um warehouse sem cluster para dimensionar
version: 1
---

**O BigQuery não é um servidor de banco de dados que você aluga.** Com o Cloud SQL, na aula 6, você
escolheu uma máquina, um disco e uma região, e pagou por essa máquina toda hora em que ela existiu.
O BigQuery não pede nada disso. Não há instância para criar, nem tipo de nó, nem número de máquinas,
nem nada para desligar à noite. O que ele tem no lugar são dois sistemas separados: um que guarda as
tabelas e outro que roda as consultas. Eles só se encontram enquanto uma consulta está rodando, e
**cada um manda a sua própria conta**.

Essa é a aula inteira numa frase, e o resto é o que decorre dela. Tudo nesta seção vem da
documentação do Google, principalmente da visão geral da arquitetura do BigQuery e da página de
preços em `cloud.google.com/bigquery/pricing`, que este curso leu em 2026-10-30. Nada disso rodou
aqui, por um motivo que a próxima seção explica por inteiro.

## O armazenamento, que você nunca vê

**Uma tabela do BigQuery é guardada pelo Google num formato colunar, no sistema de arquivos
distribuído do próprio Google**, e a documentação dá nome aos dois: o formato se chama Capacitor e
o sistema de arquivos, Colossus. Cada coluna de uma tabela é escrita separada das outras e
comprimida, e o dado é replicado entre as zonas da localização em que a tabela mora. Você nunca
mexe num arquivo, num bloco ou num disco. Não dá para escolher a compressão, ver os arquivos ou
acrescentar espaço: uma tabela cresce quando linhas são escritas nela, e é só isso.

**O que você paga é o que as tabelas guardam, por GiB e por mês.** A unidade é o gibibyte,
1.073.741.824 bytes, e o preço é proporcional ao segundo, então uma tabela que existe por meio mês
custa metade. Duas escolhas mudam a tarifa, ambas sobre o armazenamento e nenhuma sobre velocidade:
se a tabela foi modificada nos últimos 90 dias, e se a cobrança conta o tamanho antes ou depois da
compressão. A última seção desta aula são essas duas escolhas, com preço.

## A computação, que você aluga por slot

**Uma consulta roda em slots**, e a página de preços define um slot em duas palavras: uma CPU
virtual. O motor que roda as consultas, que os artigos do Google chamam de Dremel, transforma uma
consulta num plano de **estágios**. Um estágio que lê uma tabela é cortado em muitos pedaços de
trabalho, um por pedaço da tabela, e tantos slots quantos estiverem livres pegam esses pedaços ao
mesmo tempo. Entre um estágio e o seguinte, as linhas que cada slot produziu passam por um
**shuffle**: são mandadas, por uma camada de memória, para os slots do próximo estágio, agrupadas
pela chave de que esse estágio precisa, como a loja numa soma por loja.

**O número de slots não é algo que você define no modelo padrão.** Um projeto que paga por byte lido
tem, nas palavras da página de preços, "up to 2,000 concurrent slots, shared among all queries in a
single project", ou seja, até 2.000 slots simultâneos divididos entre todas as consultas do projeto,
e o BigQuery decide quantos deles cada consulta recebe. Uma consulta sobre uma tabela pequena ganha
poucos; uma sobre uma tabela grande ganha muitos e termina mais ou menos no mesmo tempo. É isso que
serverless quer dizer aqui: o tamanho da máquina acompanha o tamanho da pergunta, e ninguém a
dimensionou antes.

A outra forma de pagar é reservar slots e ser cobrado por eles por hora, leiam as consultas o que
lerem. Esse é o assunto da aula 14, e por ora basta saber que ela existe.

## A rede entre os dois

**A computação lê o armazenamento pela rede do Google, e lê só as colunas que a consulta cita.** Uma
consulta que soma `total_cents` de um dia lê a coluna `total_cents` e a coluna que guarda o dia, e
deixa as outras colunas da tabela onde estão. É por isso que os dois sistemas podem ter preços
separados: pôr mais slots numa consulta não move nem copia a tabela, e uma tabela que dobra de
tamanho não precisa de máquina maior para caber.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O armazenamento e a computação do BigQuery, separados. À esquerda, o armazenamento: a tabela orders guardada como colunas separadas, order_id, customer_id, store_id, district, total_cents e dt, das quais total_cents e dt estão destacadas. Uma seta marcada só as colunas citadas leva essas duas para a direita, para a computação: um primeiro estágio de quatro slots que leem, um shuffle, e um segundo estágio de dois slots que somam por loja. Sob o armazenamento, a conta dele: por GiB-mês, para o projeto dono da tabela. Sob a computação, a conta dela: por TiB lido ou por slot-hora, para o projeto que roda a consulta.\" data-fig=\"l13-arch\"><defs><marker id=\"l13-arch-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-arch-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"12\" width=\"250\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">armazenamento</text><text x=\"145\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Colossus, cada coluna à parte</text><rect x=\"40\" y=\"62\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">order_id</text><rect x=\"40\" y=\"90\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">customer_id</text><rect x=\"40\" y=\"118\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">store_id</text><rect x=\"40\" y=\"146\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">district</text><rect x=\"40\" y=\"174\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">total_cents</text><rect x=\"40\" y=\"202\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dt</text><rect x=\"450\" y=\"12\" width=\"250\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">computação</text><text x=\"575\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">slots, em estágios</text><text x=\"575\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">estágio 1: ler</text><rect x=\"468\" y=\"82\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"491\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><rect x=\"524\" y=\"82\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"547\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><rect x=\"580\" y=\"82\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"603\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><rect x=\"636\" y=\"82\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"659\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><polyline points=\"575,108 575,146\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-arch-ah-0)\"></polyline><text x=\"585\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">shuffle</text><text x=\"575\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">estágio 2: somar por loja</text><rect x=\"520\" y=\"172\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"543\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><rect x=\"584\" y=\"172\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"607\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><polyline points=\"250,185 360,185 360,95 462,95\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l13-arch-ah-1)\"></polyline><text x=\"360\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">só as colunas citadas</text><rect x=\"20\" y=\"260\" width=\"250\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"145\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cobrado por GiB-mês</text><text x=\"145\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ao projeto dono da tabela</text><rect x=\"450\" y=\"260\" width=\"250\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"575\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cobrado por TiB lido, ou por slot-hora</text><text x=\"575\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ao projeto que roda a consulta</text></svg>", "caption": "O armazenamento guarda cada coluna à parte e a computação lê só as que a consulta cita, e é por isso que cada um pode ser cobrado nos seus próprios termos.", "same": ["slot", "shuffle"]}
```

## Projetos, datasets e tabelas

**Uma tabela mora num dataset, e um dataset mora num projeto.** O dataset é a unidade que tem
localização, fixada na criação: o da Quitanda seria `quitanda`, em `southamerica-east1`, no projeto
`planner-dev`, e o nome completo da tabela é `planner-dev.quitanda.orders`. Uma consulta só lê
tabelas de uma localização, então um dataset criado na região errada é um dataset que precisa ser
copiado antes de poder entrar num join com os outros. É a mesma lição da localização de um bucket na
aula 1, e se aprende do mesmo jeito.

**Uma consulta é um job, e um job pertence ao projeto que o roda.** Esse projeto paga a computação,
seja qual for o projeto dono das tabelas. A página de preços diz isso sem rodeio: "You are charged
for queries run against shared data. The data owner is not charged when their data is accessed."
Então o time dono de `quitanda.orders` paga para guardá-la, e as analistas que a consultam do
próprio projeto pagam por cada consulta que rodam. O armazenamento é cobrado do dono, a computação
de quem lê, e isso por si só já é motivo para as duas linhas serem separadas.

## Duas contas, em duas unidades

| | o que mede | unidade | southamerica-east1 |
|---|---|---|---|
| armazenamento | os bytes que as tabelas guardam | GiB-mês | de 0,016 a 0,07 USD, conforme o modelo |
| computação, sob demanda | os bytes que uma consulta lê | TiB | 11,25 USD, o primeiro TiB do mês grátis |
| computação, capacidade | os slots reservados | slot-hora | a partir de 0,062 USD, conforme a edição |

**Os preços são de `cloud.google.com/bigquery/pricing`, lidos em 2026-10-30, em USD, para
`southamerica-east1`.** A linha do armazenamento tem quatro preços, e a última seção os explica. Os
primeiros 10 GiB de armazenamento de cada mês são gratuitos, e o primeiro TiB de dados consultados
também. As duas linhas de computação são os dois modelos de preço da aula 14, e um projeto usa um ou
o outro numa dada consulta, nunca os dois.

**O que o BigQuery deixa de fora diz tanto quanto o que ele cobra.** Não há chave de distribuição
para escolher, porque nenhuma tabela mora numa máquina específica. Não há índice para construir nem
vacuum para agendar, porque o armazenamento é o Google que arruma. As duas decisões que sobram para
você e que mudam a conta são como uma tabela é **particionada** e como ela é **clusterizada**, que é
a aula 15, e elas funcionam pelo mesmo princípio de tudo acima: o byte mais barato é aquele que a
consulta nunca lê.
