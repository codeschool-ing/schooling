---
title: Um líder, nós de computação e slices
version: 1
---

**O Redshift não é um PostgreSQL grande.** Ele aceita um SQL que parece o do PostgreSQL, responde na
porta 5439 aos mesmos drivers, e por baixo é construído ao contrário. O PostgreSQL guarda as linhas
de uma tabela juntas numa máquina e é rápido para buscar uma linha pela chave. O Redshift espalha as
linhas de uma tabela por muitas máquinas, guarda cada coluna separada das outras, e é rápido para
ler milhões de linhas e somá-las. Uma consulta que pede um pedido pelo id é a pergunta errada para
ele, e a pergunta para a qual ele foi feito, vendas totais por loja por dia ao longo de um ano, é
lenta no PostgreSQL.

## As partes de um cluster

**Um cluster provisionado é um nó líder e um ou mais nós de computação.** O líder é a única parte com
que um cliente fala. Ele interpreta o SQL, planeja, compila o plano em código e manda esse código aos
nós de computação, depois junta o que eles devolvem e envia a resposta. Os nós de computação guardam
os dados e fazem o trabalho.

**Cada nó de computação se divide em slices**, e a slice é a unidade que de fato roda uma consulta.
Uma slice é dona de uma parte da memória do nó e dos dados da tabela, e cada slice trabalha na sua
parte ao mesmo tempo que as outras. Um nó `ra3.xlplus` tem duas slices, então o cluster de dois nós
cujo preço esta lição calcula tem quatro, e uma consulta nele são quatro pedaços de trabalho rodando
lado a lado. **Uma consulta termina quando a slice mais lenta termina**, e é por isso que a próxima
seção é sobre como as linhas são repartidas.

**O armazenamento é colunar.** Cada coluna de uma tabela é gravada separadamente, em blocos de 1 MB,
comprimida com uma codificação escolhida para os valores daquela coluna. Uma consulta que lê três
colunas de uma tabela de vinte lê os blocos de três colunas e deixa as outras dezessete no disco. A
lição 19 faz o mesmo argumento para arquivos Parquet no S3, e é a mesma ideia.

**Todo bloco tem um zone map**: o menor e o maior valor da sua coluna naquele bloco, mantidos em
memória. Um filtro como `dt = '2026-10-05'` compara a data com o mínimo e o máximo de cada bloco, e
nenhum bloco cuja faixa não possa contê-la é lido. Quanto isso economiza depende inteiramente da
ordem em que as linhas foram gravadas, que é a seção sobre sort keys.

**Os nós RA3 guardam os dados no armazenamento gerenciado, não no nó.** A tabela mora no Redshift
Managed Storage, que a AWS mantém no S3 por trás dos panos, e cada nó guarda num SSD local os blocos
que está usando. Então computação e armazenamento têm preços separados: nós por hora e armazenamento
por GB-mês, e acrescentar um nó muda a velocidade do cluster sem mudar o que ele guarda. As famílias
de nós mais antigas guardavam os dados nos discos do próprio nó, e o único jeito de guardar mais era
comprar mais nós.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um cluster provisionado do Redshift. Um cliente SQL fala só com o nó líder, na porta 5439. O líder planeja e compila a consulta e a manda para dois nós de computação ra3.xlplus, cada um com duas slices, as slices 0 a 3, cada uma com a sua parte das linhas. Abaixo de todos, o Redshift Managed Storage, em S3, guarda os dados e é cobrado por GB-mês.\" data-fig=\"l14-cluster-pt\"><defs><marker id=\"l14-cluster-pt-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-cluster-pt-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-cluster-pt-ah-2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><rect x=\"290\" y=\"12\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cliente SQL</text><polyline points=\"360,46 360,70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l14-cluster-pt-ah-0)\"></polyline><text x=\"372\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">:5439</text><rect x=\"220\" y=\"72\" width=\"280\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nó líder</text><text x=\"360\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">planeja, compila, junta as respostas</text><polyline points=\"360,122 360,136 200,136 200,152\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l14-cluster-pt-ah-1)\"></polyline><rect x=\"60\" y=\"154\" width=\"280\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nó de computação 1</text><text x=\"200\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ra3.xlplus</text><rect x=\"76\" y=\"198\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"136\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">slice 0</text><text x=\"136\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sua parte das linhas</text><rect x=\"204\" y=\"198\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"264\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">slice 1</text><text x=\"264\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sua parte das linhas</text><polyline points=\"200,258 200,282\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l14-cluster-pt-ah-2)\"></polyline><polyline points=\"360,122 360,136 520,136 520,152\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l14-cluster-pt-ah-1)\"></polyline><rect x=\"380\" y=\"154\" width=\"280\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nó de computação 2</text><text x=\"520\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ra3.xlplus</text><rect x=\"396\" y=\"198\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">slice 2</text><text x=\"456\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sua parte das linhas</text><rect x=\"524\" y=\"198\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"584\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">slice 3</text><text x=\"584\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sua parte das linhas</text><polyline points=\"520,258 520,282\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l14-cluster-pt-ah-2)\"></polyline><rect x=\"60\" y=\"284\" width=\"600\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Redshift Managed Storage, em S3: os dados, cobrados por GB-mês</text></svg>", "caption": "Quatro slices trabalham ao mesmo tempo, e a consulta termina quando a mais lenta termina. Os dados ficam no armazenamento gerenciado, e os nós guardam em SSD os blocos que estão usando.", "same": ["slice 0", "slice 1", "slice 2", "slice 3"]}
```

## O que o moto registra

Com o moto rodando no terminal dele e as quatro linhas de "Seu laboratório, em resumo" da lição 1
digitadas neste, crie o cluster de que esta lição trata:

```
ana@laptop:~/aws$ aws redshift create-cluster --cluster-identifier quitanda-dw --node-type ra3.xlplus --number-of-nodes 2 --master-username quitanda_admin --master-user-password Lab-only-0 --db-name quitanda --query "Cluster.[ClusterStatus,NodeType,NumberOfNodes]" --output text
creating	ra3.xlplus	2
ana@laptop:~/aws$ aws redshift describe-clusters --query "Clusters[].[ClusterIdentifier,ClusterStatus,Endpoint.Address]" --output text
quitanda-dw	available	quitanda-dw.2e9a0ac50a38.sa-east-1.redshift.amazonaws.com
ana@laptop:~/aws$ aws redshift create-cluster --cluster-identifier quitanda-typo --node-type ra3.xlpluss --number-of-nodes 2 --master-username quitanda_admin --master-user-password Lab-only-0 --query Cluster.ClusterStatus --output text
creating
```

**O cluster disse `creating` e estava `available` um comando depois.** Na AWS um cluster novo leva
vários minutos para subir. O tipo de nó `ra3.xlpluss`, com uma letra a mais, também foi aceito, o que
a AWS recusaria; o moto confere o formato da requisição e não se a máquina existe. Não há nós por
trás de nenhum dos dois clusters, e nada responde no endpoint que ele imprimiu.

O moto também implementa a Redshift Data API, o jeito de mandar SQL a um cluster por HTTPS sem driver
de banco de dados, e é ela que mostra o limite com mais clareza:

```
ana@laptop:~/aws$ aws redshift-data execute-statement --cluster-identifier quitanda-dw --database quitanda --sql "CREATE TABLE stores (store_id SMALLINT NOT NULL, name VARCHAR(64) NOT NULL) DISTSTYLE ALL" --query Id --output text
38da6ade-4ccd-44f6-88f2-a41d1646f771
ana@laptop:~/aws$ sleep 5; aws redshift-data describe-statement --id 38da6ade-4ccd-44f6-88f2-a41d1646f771 --query '[Status,HasResultSet,QueryString]' --output text
STARTED	False	CREATE TABLE stores (store_id SMALLINT NOT NULL, name VARCHAR(64) NOT NULL) DISTSTYLE ALL
ana@laptop:~/aws$ aws redshift-data execute-statement --cluster-identifier quitanda-dw --database quitanda --sql "SELECT dt, count(*) FROM orders GROUP BY dt" --query Id --output text
d8036238-69de-4810-b250-ab063a7ece79
ana@laptop:~/aws$ aws redshift-data get-statement-result --id d8036238-69de-4810-b250-ab063a7ece79 --query 'Records[*].[[0].longValue,[1].stringValue,[2].stringValue]' --output text
10	Alpha st	Vancouver
50	Beta st	Toronto
100	Gamma av	Seattle
```

**O SQL foi aceito, e cinco segundos depois ainda estava `STARTED`**: não há nada no moto que um dia o
termine. Depois um `SELECT` contra uma tabela que ninguém criou voltou com três linhas, um número, uma
rua e uma cidade, que são a resposta de exemplo do próprio moto a qualquer comando. Nada neste curso
roda o SQL do Redshift. O DDL das duas próximas seções foi escrito para ser lido, e o que ele faz é
ensinado a partir da documentação da AWS e de dois modelos pequenos, identificados como modelos.
