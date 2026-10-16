---
title: Três nós, um anel
version: 1
---

A aula 2 pôs o Cassandra num nó só, onde toda partição mora no mesmo lugar e a chave de partição
parece um índice. **Com mais de um nó ela deixa de parecer um índice e vira um endereço.** A chave
de partição passa por um hash e vira um número, o número cai em algum ponto de um anel que os nós
dividem entre si, e esse ponto decide qual máquina guarda as linhas. Toda regra do resto desta aula
decorre desse fato.

## Três nós na sua máquina

As aulas 16 a 19 usam um cluster de três nós do Cassandra chamados `c1`, `c2` e `c3`, na rede
`nosql` que a aula 1 criou. Os três ocupam cerca de 1,5 GB de memória juntos, então pare antes o
que não estiver usando: `docker stop mongo redis cassandra` para os contêineres da aula 1, e o nó
único `cassandra` não faz parte do cluster.

```sh
for n in 1 2 3; do
  docker run -d --name c$n --network nosql \
    -e CASSANDRA_CLUSTER_NAME=lab -e CASSANDRA_SEEDS=c1 \
    -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch -e CASSANDRA_DC=dc1 -e CASSANDRA_RACK=rack1 \
    -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
  until [ "$(docker exec c$n nodetool status 2>/dev/null | grep -c '^UN')" = $n ]; do sleep 5; done
done
```

As opções `-e` são lidas pelo script de início da imagem e escritas na configuração do Cassandra:

| opção | o que faz aqui |
| --- | --- |
| `CASSANDRA_CLUSTER_NAME=lab` | o nome que todo nó confere antes de aceitar entrar; um nó com outro nome é recusado |
| `CASSANDRA_SEEDS=c1` | o nó a quem um nó novo pergunta primeiro quem mais está no cluster |
| `CASSANDRA_ENDPOINT_SNITCH`, `_DC`, `_RACK` | onde cada nó diz que está: data center `dc1`, rack `rack1`. A aula 17 precisa do nome do data center |
| `MAX_HEAP_SIZE`, `HEAP_NEWSIZE` | o heap pequeno da aula 1, sem o qual três nós não cabem numa VM de 4 GB |

**O laço inicia um nó e espera por ele antes do próximo.** Um nó que entra pega sua parte do anel
dos nós que já estão lá, e o Cassandra espera essas entradas uma de cada vez. A linha do `until`
pergunta ao `nodetool status` quantos nós estão `UN`, de pé e normais, e segue quando a contagem
chega ao nó recém-iniciado. Cada nó levou pouco mais de um minuto no laboratório, então o laço leva
três ou quatro.

Se o laço nunca termina, `docker logs c2` mostra o que o nó está fazendo, e a seção de falhas da
aula 1 trata de um nó morto por falta de memória. Se você parar o cluster entre as aulas, `docker
start c1 c2 c3` o traz de volta com os dados; o laço é só para um cluster que ainda não existe.

## Um keyspace com uma cópia, e oito pedidos

O keyspace decide quantas cópias de cada partição existem. Esta aula pede **uma**, para que cada
partição more em exatamente um nó e você possa ver em qual; a aula 17 sobe para três. Salve isto
como `orders.cql`:

```sql
CREATE KEYSPACE shop
  WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 1};

CREATE TABLE shop.orders_by_customer (
  customer   text,
  ordered_at timestamp,
  order_id   text,
  total      decimal,
  status     text,
  PRIMARY KEY (customer, ordered_at, order_id)
) WITH CLUSTERING ORDER BY (ordered_at DESC, order_id ASC);

INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('ana@example.com',   '2026-03-02 13:15:00+0000', 'A-1001',  349.90, 'delivered');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('bruno@example.com', '2026-03-02 15:40:00+0000', 'A-1002', 1499.00, 'delivered');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('carla@example.com', '2026-03-02 19:05:00+0000', 'A-1003',   39.90, 'delivered');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('ana@example.com',   '2026-03-20 00:02:00+0000', 'A-1004',  189.00, 'delivered');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('diego@example.com', '2026-03-20 11:20:00+0000', 'A-1005',  349.90, 'shipped');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('ana@example.com',   '2026-04-08 12:30:00+0000', 'A-1006', 1499.00, 'shipped');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('bruno@example.com', '2026-04-08 14:10:00+0000', 'A-1007',   39.90, 'shipped');
INSERT INTO shop.orders_by_customer (customer, ordered_at, order_id, total, status) VALUES ('elisa@example.com', '2026-04-09 09:45:00+0000', 'A-1008',  189.00, 'pending');
```

e entregue ao `cqlsh`, que lê comandos da entrada padrão. Silêncio quer dizer que todos deram certo:

```
ana@vm:~$ docker exec -i c1 cqlsh < orders.cql
```

Os horários estão em UTC, com `+0000`, porque é assim que o `cqlsh` os devolve.

## Para onde foram as partições

```
ana@vm:~$ docker exec c1 nodetool status shop
Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack 
UN  172.18.0.3  80.02 KiB   16      31.6%             c7136733-e3d8-40a4-b1b9-6068904ef7a9  rack1
UN  172.18.0.4  119.66 KiB  16      35.7%             f2c1f805-fbdd-42e2-9442-44d0414adabf  rack1
UN  172.18.0.2  95.9 KiB    16      32.7%             2b88e753-4987-4fbf-a0a4-6a1919f4a912  rack1

ana@vm:~$ docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' c1 c2 c3
/c1 172.18.0.2
/c2 172.18.0.3
/c3 172.18.0.4
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" c1 c2 c3
NAME      MEM USAGE / LIMIT
c1        557.1MiB / 15.72GiB
c2        467.8MiB / 15.72GiB
c3        503.1MiB / 15.72GiB
```

`Tokens 16` é o número de lugares do anel que cada nó possui, e `Owns (effective)` é a fatia do anel
que isso soma, para o keyspace `shop`. Três nós com 16 tokens cada dividem o anel mais ou menos em
terços, não exatamente. O Cassandra chama os nós pelo endereço, então a linha do `docker inspect` é a
chave para ler tudo o que vem depois: `c1` é `172.18.0.2`, `c2` é `.3`, `c3` é `.4`. Seus endereços
podem ser outros; leia os seus. A memória deu cerca de 1,5 GB para os três, como prometido.

A chave de partição passa pelo particionador **Murmur3** e vira um token, um número de 64 bits com
sinal, e `token()` o mostra:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT DISTINCT customer, token(customer) FROM shop.orders_by_customer;

 customer          | system.token(customer)
-------------------+------------------------
 carla@example.com |   -5911513789470835951
 bruno@example.com |   -3891430603489557805
 elisa@example.com |    6901144969670893120
   ana@example.com |    8413089589345688709
 diego@example.com |    8993384036030544940

(5 rows)
cqlsh> exit
ana@vm:~$ for c in ana bruno carla diego elisa; do echo "$c $(docker exec c1 nodetool getendpoints shop orders_by_customer $c@example.com)"; done
ana 172.18.0.3
bruno 172.18.0.4
carla 172.18.0.3
diego 172.18.0.2
elisa 172.18.0.3
```

**As linhas voltaram na ordem dos tokens, não em ordem alfabética** nem na ordem em que foram
gravadas: Carla, o token mais negativo, primeiro. Uma consulta sem chave de partição lê o anel de
uma ponta à outra, e é isso que essa ordem mostra. O `nodetool getendpoints` responde à pergunta que
o token levanta, qual nó guarda esta chave: Ana, Carla e Elisa estão no `c2`, Bruno no `c3` e Diego
no `c1`. Nada nos nomes decide isso. Dois endereços de e-mail vizinhos viram tokens nada próximos
um do outro, e é essa a ideia: **o hash espalha as chaves por igual, seja qual for a cara delas.**

## O próprio anel

O `nodetool ring` lista cada token e seu dono:

```
ana@vm:~$ docker exec c1 nodetool ring shop | head -12

Datacenter: dc1
==========
Address          Rack        Status State   Load            Owns                Token                                       
                                                                                9198835449366431173                         
172.18.0.4       rack1       Up     Normal  119.66 KiB      35.71%              -8883060869248345148                        
172.18.0.3       rack1       Up     Normal  80.02 KiB       31.64%              -8649444933386381616                        
172.18.0.2       rack1       Up     Normal  95.9 KiB        32.65%              -8269763171827006366                        
172.18.0.4       rack1       Up     Normal  119.66 KiB      35.71%              -7905170012854856482                        
172.18.0.3       rack1       Up     Normal  80.02 KiB       31.64%              -7615144286710977248                        
172.18.0.3       rack1       Up     Normal  80.02 KiB       31.64%              -7188857785429847858                        
172.18.0.4       rack1       Up     Normal  119.66 KiB      35.71%              -6757846304499179774                        
ana@vm:~$ docker exec c1 nodetool ring shop | grep -c Normal
48
```

Cada linha é um token, em ordem. **Um nó é dono do intervalo que termina no seu token**, começando
logo depois do token da linha de cima. O número solitário acima da primeira linha é o maior token,
repetido do fim da lista: o primeiro intervalo começa logo depois dele, dando a volta do topo do
anel até o começo. Quarenta e oito linhas, dezesseis por nó, intercaladas. Desenhado como um
círculo, com os tokens desta execução:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 380\" role=\"img\" aria-label=\"Um anel de tokens, do menor valor possível no topo, em sentido horário até o maior. Três nós, c1, c2 e c3, são donos de dezesseis arcos cada, intercalados ao redor do anel. As chaves de partição de cinco clientes estão marcadas onde seus tokens caem: carla, bruno, elisa, ana e diego. Cada uma fica no nó dono do arco em que cai: ana, carla e elisa no c2, bruno no c3, diego no c1.\"><path d=\"M209.0 70.0 A120 120 0 0 1 223.9 70.8\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M223.9 70.8 A120 120 0 0 1 233.3 72.3\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M233.3 72.3 A120 120 0 0 1 248.3 76.3\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M248.3 76.3 A120 120 0 0 1 262.1 81.9\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M262.1 81.9 A120 120 0 0 1 272.5 87.6\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M272.5 87.6 A120 120 0 0 1 286.7 97.7\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M286.7 97.7 A120 120 0 0 1 299.3 109.9\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M299.3 109.9 A120 120 0 0 1 306.2 118.3\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M306.2 118.3 A120 120 0 0 1 315.1 132.1\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M315.1 132.1 A120 120 0 0 1 319.7 141.3\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M319.7 141.3 A120 120 0 0 1 325.8 158.4\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M325.8 158.4 A120 120 0 0 1 328.8 172.8\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M328.8 172.8 A120 120 0 0 1 329.8 183.1\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M329.8 183.1 A120 120 0 0 1 329.3 202.6\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M329.3 202.6 A120 120 0 0 1 325.3 223.1\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M325.3 223.1 A120 120 0 0 1 320.9 235.9\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M320.9 235.9 A120 120 0 0 1 311.6 253.9\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M311.6 253.9 A120 120 0 0 1 304.4 264.0\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M304.4 264.0 A120 120 0 0 1 294.7 275.0\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M294.7 275.0 A120 120 0 0 1 286.2 282.7\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M286.2 282.7 A120 120 0 0 1 273.5 291.8\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M273.5 291.8 A120 120 0 0 1 265.1 296.6\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M265.1 296.6 A120 120 0 0 1 248.1 303.8\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M248.1 303.8 A120 120 0 0 1 233.4 307.7\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M233.4 307.7 A120 120 0 0 1 223.7 309.2\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M223.7 309.2 A120 120 0 0 1 207.1 310.0\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M207.1 310.0 A120 120 0 0 1 187.1 307.8\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M187.1 307.8 A120 120 0 0 1 174.3 304.6\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M174.3 304.6 A120 120 0 0 1 151.9 295.0\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M151.9 295.0 A120 120 0 0 1 135.6 284.1\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M135.6 284.1 A120 120 0 0 1 122.6 272.2\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M122.6 272.2 A120 120 0 0 1 114.6 262.7\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M114.6 262.7 A120 120 0 0 1 105.4 248.8\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M105.4 248.8 A120 120 0 0 1 100.7 239.6\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M100.7 239.6 A120 120 0 0 1 94.8 223.6\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M94.8 223.6 A120 120 0 0 1 91.0 205.7\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M91.0 205.7 A120 120 0 0 1 90.0 193.4\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M90.0 193.4 A120 120 0 0 1 91.2 173.3\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M91.2 173.3 A120 120 0 0 1 96.4 151.2\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M96.4 151.2 A120 120 0 0 1 103.0 135.7\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M103.0 135.7 A120 120 0 0 1 114.3 117.6\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M114.3 117.6 A120 120 0 0 1 125.5 104.8\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M125.5 104.8 A120 120 0 0 1 136.8 94.9\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M136.8 94.9 A120 120 0 0 1 146.3 88.3\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M146.3 88.3 A120 120 0 0 1 166.8 78.1\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M166.8 78.1 A120 120 0 0 1 182.3 73.2\" stroke=\"var(--amber)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M182.3 73.2 A120 120 0 0 1 198.1 70.6\" stroke=\"var(--paper-dim)\" stroke-width=\"12\" fill=\"none\"></path><path d=\"M198.1 70.6 A120 120 0 0 1 209.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"12\" fill=\"none\"></path><line x1=\"223.0\" y1=\"78.8\" x2=\"224.8\" y2=\"62.9\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"231.8\" y1=\"80.1\" x2=\"234.9\" y2=\"64.4\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"245.7\" y1=\"83.9\" x2=\"250.8\" y2=\"68.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"258.6\" y1=\"89.1\" x2=\"265.6\" y2=\"74.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"268.3\" y1=\"94.4\" x2=\"276.7\" y2=\"80.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"281.5\" y1=\"103.8\" x2=\"291.8\" y2=\"91.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"293.4\" y1=\"115.2\" x2=\"305.3\" y2=\"104.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"299.8\" y1=\"123.1\" x2=\"312.7\" y2=\"113.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"308.1\" y1=\"135.9\" x2=\"322.1\" y2=\"128.2\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"312.4\" y1=\"144.5\" x2=\"327.0\" y2=\"138.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"318.0\" y1=\"160.5\" x2=\"333.5\" y2=\"156.2\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"320.8\" y1=\"174.0\" x2=\"336.7\" y2=\"171.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"321.8\" y1=\"183.5\" x2=\"337.8\" y2=\"182.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"321.4\" y1=\"201.7\" x2=\"337.3\" y2=\"203.4\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"317.7\" y1=\"220.9\" x2=\"333.0\" y2=\"225.3\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"313.5\" y1=\"232.8\" x2=\"328.3\" y2=\"239.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"304.8\" y1=\"249.6\" x2=\"318.4\" y2=\"258.1\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"298.1\" y1=\"259.1\" x2=\"310.7\" y2=\"269.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"289.0\" y1=\"269.4\" x2=\"300.3\" y2=\"280.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"281.1\" y1=\"276.5\" x2=\"291.3\" y2=\"288.9\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"269.3\" y1=\"285.0\" x2=\"277.7\" y2=\"298.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"261.4\" y1=\"289.5\" x2=\"268.8\" y2=\"303.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"245.5\" y1=\"296.2\" x2=\"250.6\" y2=\"311.4\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"231.8\" y1=\"299.9\" x2=\"234.9\" y2=\"315.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"222.8\" y1=\"301.3\" x2=\"224.7\" y2=\"317.2\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"207.3\" y1=\"302.0\" x2=\"206.9\" y2=\"318.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"188.7\" y1=\"299.9\" x2=\"185.6\" y2=\"315.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"176.6\" y1=\"296.9\" x2=\"171.9\" y2=\"312.2\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"155.8\" y1=\"288.0\" x2=\"148.1\" y2=\"302.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"140.6\" y1=\"277.9\" x2=\"130.6\" y2=\"290.4\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"128.4\" y1=\"266.8\" x2=\"116.8\" y2=\"277.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"120.9\" y1=\"257.9\" x2=\"108.2\" y2=\"267.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"112.3\" y1=\"244.8\" x2=\"98.4\" y2=\"252.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"108.0\" y1=\"236.3\" x2=\"93.5\" y2=\"242.9\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"102.5\" y1=\"221.3\" x2=\"87.1\" y2=\"225.8\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"99.0\" y1=\"204.7\" x2=\"83.1\" y2=\"206.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"98.0\" y1=\"193.1\" x2=\"82.1\" y2=\"193.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"99.1\" y1=\"174.4\" x2=\"83.3\" y2=\"172.2\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"104.0\" y1=\"153.8\" x2=\"88.9\" y2=\"148.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"110.1\" y1=\"139.3\" x2=\"95.8\" y2=\"132.1\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"120.7\" y1=\"122.4\" x2=\"107.9\" y2=\"112.7\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"131.1\" y1=\"110.5\" x2=\"119.9\" y2=\"99.1\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"141.7\" y1=\"101.2\" x2=\"132.0\" y2=\"88.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"150.5\" y1=\"95.1\" x2=\"142.0\" y2=\"81.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"169.7\" y1=\"85.5\" x2=\"163.9\" y2=\"70.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"184.1\" y1=\"81.0\" x2=\"180.4\" y2=\"65.5\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"198.9\" y1=\"78.6\" x2=\"197.3\" y2=\"62.6\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><line x1=\"209.1\" y1=\"78.0\" x2=\"208.9\" y2=\"62.0\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></line><circle cx=\"300.4\" cy=\"147.2\" r=\"4\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"276.9\" y=\"158.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">carla</text><circle cx=\"307.0\" cy=\"214.3\" r=\"4\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"281.8\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bruno</text><circle cx=\"138.9\" cy=\"119.7\" r=\"4\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"157.4\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">elisa</text><circle cx=\"182.7\" cy=\"93.8\" r=\"4\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"195.3\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ana</text><circle cx=\"202.2\" cy=\"90.3\" r=\"4\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"203.7\" y=\"110.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">diego</text><text x=\"210\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">anel de tokens</text><text x=\"210\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-2^63 … 2^63</text><text x=\"210.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">menor token, depois sentido horário</text><text x=\"420\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">nó, endereço, fatia do anel</text><rect x=\"420\" y=\"85\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"454\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c1</text><text x=\"482\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">172.18.0.2</text><text x=\"580\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32.7%</text><rect x=\"420\" y=\"115\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"454\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c2</text><text x=\"482\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">172.18.0.3</text><text x=\"580\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31.6%</text><rect x=\"420\" y=\"145\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"454\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c3</text><text x=\"482\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">172.18.0.4</text><text x=\"580\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">35.7%</text><text x=\"420\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">chave de partição → token → dono</text><text x=\"420\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">carla</text><text x=\"468\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-5911513789470835951</text><text x=\"652\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">c2</text><text x=\"420\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bruno</text><text x=\"468\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-3891430603489557805</text><text x=\"652\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">c3</text><text x=\"420\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">elisa</text><text x=\"468\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6901144969670893120</text><text x=\"652\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">c2</text><text x=\"420\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ana</text><text x=\"468\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8413089589345688709</text><text x=\"652\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">c2</text><text x=\"420\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">diego</text><text x=\"468\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8993384036030544940</text><text x=\"652\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">c1</text></svg>", "caption": "O anel do cluster deste laboratório, desenhado a partir do próprio nodetool ring: 48 tokens, 16 por nó. A chave de partição vira um token por hash, e o nó dono do arco em que o token cai guarda a partição."}
```

O token da Ana, `8413089589345688709`, cai depois de `8141555572029014120` e até
`8538878424377726911`, um intervalo cujo token pertence a `172.18.0.3`. Esse é o `c2`, que é o que o
`getendpoints` disse.

**Muitos intervalos pequenos em vez de um grande por nó** é o que os 16 compram. Quando um quarto nó
entra, ele pega pedaços pequenos dos três, em vez de metade do intervalo de um vizinho, e quando um
nó morre a carga dele se espalha por todos os sobreviventes em vez de cair num só. Clusters mais
antigos usavam 256 tokens por nó; 16 é o padrão do Cassandra 4.0 em diante.

O que isso entrega é um fato em torno do qual projetar: **todas as linhas de uma partição moram
juntas, nos nós donos do seu token, e uma consulta que nomeia a chave de partição vai direto lá.** A
próxima seção trata do que acontece dentro de uma partição, e a seguinte das consultas que não
nomeiam nenhuma.
