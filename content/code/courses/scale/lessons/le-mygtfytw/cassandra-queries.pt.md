---
title: Cassandra, a consulta que ele recusa
version: 1
---

A aula 4 disse que uma tabela de coluna larga responde as consultas para as quais foi desenhada e
recusa as outras. Aqui está a recusa, depois um nível de consistência, depois quanto o nó custa:

```
ana@lab:~/tickets$ docker exec cassandra cqlsh -e "SELECT ticket FROM tickets.scans WHERE gate = 'B'"
<stdin>:1:InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
ana@lab:~/tickets$ docker exec cassandra cqlsh -e "CONSISTENCY QUORUM; SELECT count(*) FROM tickets.scans WHERE show_id = 'show-1'"
Consistency level set to QUORUM.

 count
-------
     5

(1 rows)
ana@lab:~/tickets$ docker stats --no-stream --format "{{.Name}} {{.MemUsage}}" cassandra
cassandra 802.7MiB / 1.5GiB
ana@lab:~/tickets$ docker rm -f cassandra
cassandra
```

**"Toda leitura no portão B" é recusada**, com uma mensagem que é uma lição de desenho numa frase: a
consulta "pode envolver filtragem de dados e por isso ter desempenho imprevisível". `gate` não faz
parte da chave, então responder significaria ler toda partição em todo nó. `ALLOW FILTERING` faria o
Cassandra ler mesmo assim. Em seis linhas isso é inofensivo; num cluster com um ano de leituras é uma
consulta que lê o cluster inteiro, e a recusa existe para que ninguém faça isso sem querer. A resposta
certa é a da aula 4: uma segunda tabela, com chave pelo portão, gravada junto com a primeira.

## Escolhendo a consistência de uma leitura

`CONSISTENCY QUORUM` define o nível para os comandos seguintes da sessão, e a contagem que vem depois é
lida nesse nível: de uma maioria das réplicas da partição. Com um nó e uma réplica, a maioria é um,
então nada muda aqui. Num cluster com três réplicas, isso é o W + R > N da aula 3 escolhido por
consulta: escrever e ler em `QUORUM` se sobrepõe em pelo menos uma réplica, e `ONE` de qualquer lado
troca essa garantia por velocidade e disponibilidade.

## Quanto custou

O `docker stats` mostra o nó usando **803 MB** com seis linhas dentro. O Cassandra é feito para muitas
máquinas com muita memória cada uma; a maior parte disso é o heap e os caches que ele reserva ao
subir, não dados. Num notebook ele é o mais pesado dos cinco, e é um dos motivos de esta aula rodá-los
um de cada vez. Remova-o antes da próxima seção; o último comando acima fez isso.
