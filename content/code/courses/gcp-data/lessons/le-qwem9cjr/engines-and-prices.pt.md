---
title: Quatro produtos e o jeito como cada um é cobrado
version: 1
---

**O Memorystore é a máquina de outra pessoa rodando um servidor chave-valor em memória, e a parte que
o Google administra é a máquina, não as suas chaves.** Ele instala o servidor, aplica correções numa
janela de manutenção que você escolhe, troca um nó que morre e promove uma réplica quando uma
primária falha. O que entra no cache, por quanto tempo, e o que acontece quando ele enche continuam
sendo decisões do seu programa, e são a maior parte desta aula. A imagem errada é a de um banco de
dados mais rápido: um cache guarda cópias, tem o direito de esquecê-las, e um programa que não
sobrevive a um cache esvaziado durante a noite transformou o cache num banco sem as garantias de um.

## Redis, Redis Cluster, Valkey e Memcached

Memorystore são quatro produtos sob um nome só, e três deles falam o mesmo protocolo.

| produto | o que é | como cresce |
|---|---|---|
| Memorystore for Redis | uma instância Redis, nível Basic ou Standard, até 300 GB | uma capacidade maior, ou até cinco réplicas de leitura |
| Memorystore for Redis Cluster | Redis dividido em shards, cada um uma primária com réplicas | mais shards |
| Memorystore for Valkey | o mesmo formato para o Valkey, o fork do Redis feito pela Linux Foundation em 2024, quando o Redis deixou a licença de código aberto | mais shards |
| Memorystore for Memcached | um cache mais antigo e mais simples: só strings, sem replicação, sem persistência | mais nós |

**O Valkey fala o mesmo protocolo que o Redis**, responde aos mesmos comandos e é acessado pelas
mesmas bibliotecas de cliente, então um programa escrito contra um roda contra o outro. É por isso
que a prática desta aula usa o servidor Redis que o Ubuntu empacota: o que você aprende sobre `SET`,
`EXPIRE` e despejo vale sem mudança para os três. O Memcached é o produto a escolher só quando tudo
de que você precisa são strings com validade e muitas threads por nó; qualquer coisa que precise de
réplica, de um sorted set ou de um contador que sobreviva a um nó pertence a um dos outros.

**O primeiro produto é cobrado pelo gibibyte que você provisiona, os dois seguintes pelo nó, e o
Memcached pelo processador e pela memória.** É a diferença que vale levar desta seção, porque ela
decide quanto custa um cache ocioso, que é o preço inteiro em todos os casos: cada página de preços
diz que a cobrança começa quando a instância é criada, seja ela usada ou não.

## Os preços, lidos em 2026-10-30

São Paulo, `southamerica-east1`, em USD. **Memorystore for Redis**, de
cloud.google.com/memorystore/docs/redis/pricing, por GiB de capacidade provisionada por hora:

| nível de capacidade | Basic | Standard |
|---|---|---|
| M1, 1 a 4 GiB | US$ 0,087 | US$ 0,146 |
| M2, 5 a 10 GiB | US$ 0,054 | US$ 0,103 |
| M3, 11 a 35 GiB | US$ 0,042 | US$ 0,083 |
| M4, 36 a 100 GiB | US$ 0,035 | US$ 0,069 |
| M5, acima de 100 GiB | US$ 0,027 | US$ 0,054 |

**O preço por gibibyte cai conforme a instância cresce**, e o nível é decidido pela capacidade que
você provisiona, não pelo que as chaves usam. **Memorystore for Valkey**, de
cloud.google.com/memorystore/docs/valkey/pricing, por nó por hora, e a página do Memorystore for
Redis Cluster lista os mesmos preços para os mesmos tipos de nó:

| tipo de nó | capacidade | por nó-hora |
|---|---|---|
| shared-core-nano | 1,4 GB | US$ 0,0505 |
| standard-small | 6,5 GB | US$ 0,2263 |
| highmem-medium | 13 GB | US$ 0,3054 |
| standard-large | 26 GB | US$ 0,905982 |

**Memorystore for Memcached**, de cloud.google.com/memorystore/docs/memcached/pricing: US$ 0,0795 por
vCPU-hora, mais US$ 0,007 por GiB-hora para um nó de até 4 GiB e US$ 0,0142 por GiB-hora acima disso.
A aritmética, a 730 horas por mês:

```
ana@laptop:~/gcp$ python3 -c 'print(round(5 * 0.054 * 730, 2), round(5 * 0.103 * 730, 2), round(4 * 0.087 * 730, 2), round(4 * 0.146 * 730, 2))'
197.1 375.95 254.04 426.32
ana@laptop:~/gcp$ python3 -c 'print(round(2 * 0.3054 * 730, 2), round(6 * 0.3054 * 730, 2), round((0.0795 + 4 * 0.007) * 730, 2))'
445.88 1337.65 78.47
ana@laptop:~/gcp$ python3 -c 'print(round(13 * 0.00087008 * 730, 2))'
8.26
```

**Uma instância Redis de 5 GiB sai 197,10 dólares por mês no Basic e 375,95 no Standard.** Standard é
o nível com uma réplica em outra zona e failover automático, e custa quase o dobro, que é o preço de
uma segunda cópia da memória. Abaixo de 5 GiB a diferença tem a mesma forma e o preço por gibibyte é
maior: 4 GiB saem 254,04 no Basic e 426,32 no Standard, porque 4 GiB caem no M1 e 5 GiB no M2. **Um
GiB a mais pode custar menos**, e é a primeira coisa a conferir quando se escolhe a capacidade de uma
instância.

**Um shard do Valkey com dois nós `highmem-medium`, uma primária e uma réplica, sai 445,88 dólares por
mês, e três desses shards 1.337,65.** O exemplo da própria página diz o mesmo em palavras: o custo por
hora é o número de shards mais o número de nós de réplica, multiplicado pelo preço por nó. Um nó do
Memcached com uma vCPU e 4 GiB sai 78,47 dólares por mês. O terceiro comando pertence à próxima parte
desta seção.

## O que mais está na conta

**A persistência é opcional, e no Valkey tem preço próprio.** Um cache do Memorystore guarda as chaves
em memória, e também pode gravá-las, em snapshots periódicos (RDB) ou, no Redis Cluster e no Valkey,
num log só de acréscimos com cada escrita (AOF), para que um nó reiniciado volte com as chaves. A
página do Valkey cobra o AOF a US$ 0,00087008 por GB-hora do tamanho da instância, o que para um nó de
13 GB dá os 8,26 dólares por mês do terceiro comando, e os backups a US$ 0,00019444 por GB-hora, com
mínimo de 24 horas por backup. **Um cache que precisa de persistência é um sinal de que o dado nele não
é cópia**, e as seções sobre despejo e sobre failover voltam ao que isso quer dizer.

**A rede dentro de uma região é grátis na página do Redis, e quase grátis na do Valkey.** O Memorystore
for Redis não cobra nada pelo tráfego com um cliente na mesma região, embora o cliente possa pagar a
própria cobrança entre zonas; a página do Valkey cobra US$ 0,01 por GiB processado para clientes numa
zona diferente da instância. Um cliente em outra região paga cada gibibyte, e é por isso que o cache
fica ao lado do programa que o lê.

**A manutenção é do Google, numa janela semanal que você escolhe.** O Google aplica correções no
servidor nessa janela. Uma instância do nível Standard faz failover para a réplica, e a documentação
avisa que uma instância do nível Basic é esvaziada, perdendo todas as chaves, na manutenção e quando a
capacidade dela muda. Para um cache de cópias, é uma hora lenta depois de uma noite de manutenção;
para qualquer outra coisa, é o motivo de o Basic ser o nível errado.

**Nada neste curso cria nenhum deles.** Não
há emulador do Memorystore, o Google não publica nenhum, e o plano de controle que criaria uma
instância não está neste laptop. O cache que o resto da aula usa é de verdade e roda na sua própria
máquina; a metade administrada é ensinada a partir da documentação e marcada como tal.
