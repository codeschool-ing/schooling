---
title: O estado do Flink, checkpoints e savepoints
version: 1
---

As janelas abertas do job que você acabou de iniciar são estado, como as do Spark, e vivem na
memória do TaskManager. **O Flink as protege tirando um snapshot do job inteiro a cada poucos
segundos, sem pará-lo**, e esse snapshot se chama **checkpoint**. As duas linhas `SET` no topo do
`sales.sql` pediram um a cada dez segundos, gravado em `~/flink-checkpoints`.

A imagem errada é a de que cada operador salva o seu estado quando bem entende. Se a fonte salvasse
os offsets do Kafka num momento e o operador de janela salvasse as contagens um pouco depois, uma
restauração contaria algumas vendas duas vezes ou nenhuma. **O Flink torna o snapshot consistente
mandando uma marca, uma barreira, pelo stream junto com os registros.** Quando a fonte tira um
snapshot, ela salva os offsets e passa a barreira adiante; cada operador salva o seu estado quando a
barreira chega até ele, então toda contagem salva inclui exatamente as vendas anteriores à barreira e
nenhuma depois dela. Uma restauração devolve as contagens e faz a fonte ler de novo a partir dos
offsets salvos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Uma barreira de checkpoint viajando junto com os registros. Os registros vão da fonte Kafka ao operador de janela e ao sink. A fonte injeta uma barreira, marcada N, entre dois registros e salva os seus offsets nesse ponto. A barreira segue adiante atrás dos registros anteriores a ela; quando chega ao operador de janela, o operador salva as suas contagens. Os dois salvamentos vão para o checkpoint N, que portanto guarda os offsets e as contagens no mesmo ponto do stream. Os registros depois da barreira continuam passando e não estão nele.\" data-fig=\"l13-barrier\"><defs><marker id=\"l13-barrier-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-barrier-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">fonte Kafka</text><rect x=\"300\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">operador de janela</text><rect x=\"580\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sink</text><rect x=\"160\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"180\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"200\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"250\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"270\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><line x1=\"228\" y1=\"64\" x2=\"228\" y2=\"100\" stroke=\"var(--amber)\" stroke-width=\"3\"></line><text x=\"228\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">barreira N</text><rect x=\"430\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"470\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 490 82 L 576 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-barrier-ah-8343)\"></path><text x=\"220\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">os registros seguem</text><path d=\"M 230 150 L 290 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-barrier-ah-8343)\"></path><text x=\"222\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">depois dela: fora de N</text><text x=\"234\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">antes da barreira: em N</text><rect x=\"240\" y=\"180\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"340\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">checkpoint N</text><text x=\"340\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">offsets + contagens</text><path d=\"M 85 106 Q 90 190 236 198\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-barrier-ah-83)\"></path><path d=\"M 355 106 L 345 176\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-barrier-ah-83)\"></path><text x=\"110\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">offsets</text><text x=\"375\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">contagens</text></svg>", "caption": "Cada operador salva o seu estado quando a barreira chega até ele, então o snapshot é um momento consistente do job inteiro.", "same": ["sink", "checkpoint N", "offsets"]}
```

Para onde o snapshot vai é assunto do **state backend**. O padrão guarda o estado de trabalho como
objetos Java na memória do TaskManager e escreve o snapshot no diretório de checkpoint; o backend
RocksDB guarda o estado de trabalho em disco local, para estados maiores que a memória. Num cluster
de verdade o diretório é um armazenamento compartilhado que sobrevive a uma máquina, a mesma regra
do Spark.

O diretório do job dentro de `~/flink-checkpoints` tem o id dele como nome, e guarda o último
checkpoint concluído:

@@fence@@

## Um savepoint: parar de propósito

Um checkpoint é do Flink, tirado para se recuperar de uma queda e apagado quando outros mais novos
o substituem. Um **savepoint** é seu: o mesmo tipo de snapshot, tirado quando você pede, guardado
até você apagar, e usado para parar um job e iniciá-lo de novo depois, após uma atualização do
Flink, uma mudança no job ou uma mudança de cluster. O `flink stop` tira um e então para o job:

@@fence@@

Enquanto ele está parado, chegam mais duas vendas, a do Recife da lição 12 às 09:38 e uma de Natal
às 09:44, tardia o bastante para levar o watermark além de 09:40:

@@fence@@

Submeta o `sales.sql` de novo, desta vez dizendo ao cliente SQL, com `-D`, de onde restaurar o job.
O caminho é o que o `flink stop` imprimiu:

@@fence@@

@@fence@@

As seis primeiras linhas são do job antigo. **As duas últimas são do job novo, e só podiam vir do
savepoint**: 24 vendas na janela de 09:30 e 14 na de 09:35, as 13 contadas antes da parada mais a
venda do Recife. O job novo não leu o tópico desde o começo, embora a tabela diga `earliest-offset`:
o savepoint guardava os offsets da fonte e eles ganham, como o checkpoint do Spark ganhou do
`startingOffsets`. Iniciado sem `-D`, o mesmo arquivo teria lido o tópico desde o começo e escrito
cada janela uma segunda vez.

## Quanto custa, e parando

O cluster agora são três processos Java, o nó Kafka e os dois do Flink:

@@fence@@

@@fence@@

O TaskManager, que roda o job, e o JobManager, que o coordena, ocupam cerca de 400 MB cada, e o nó
Kafka mais ou menos o mesmo: **cerca de 1,2 GB para um broker e um pequeno cluster Flink**, dentro
dos 4 GB da máquina virtual com espaço para o sistema operacional. Pare o job e o cluster quando
terminar:

@@fence@@

Parar o cluster com o job ainda rodando cancela o job, e o próximo início dele começaria do
`earliest-offset` da tabela, a não ser que recebesse um savepoint ou um checkpoint de onde
restaurar. Esse é o hábito operacional a guardar: **pare um job do Flink com um savepoint, e
inicie-o a partir de um.**
