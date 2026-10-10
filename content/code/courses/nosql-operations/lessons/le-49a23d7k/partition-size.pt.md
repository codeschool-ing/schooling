---
title: Uma partição que nunca para de crescer
version: 1
---

O método da última seção tem uma armadilha no segundo passo. "Visualizações de página de um cliente,
da mais nova para a mais antiga" faz de `customer` a chave de partição e de `viewed_at` a coluna de
clustering, e a tabela funciona no primeiro dia e no centésimo. **Mas a partição não tem fim.** Cada
visualização acrescenta uma linha, nada jamais remove uma, e uma partição mora inteira nos nós donos
do seu token. Um cliente que usa a loja há cinco anos é uma partição cada vez maior nos mesmos
poucos nós.

Uma partição grande custa em vários lugares ao mesmo tempo. Uma leitura que quer as vinte linhas
mais novas de uma partição enorme ainda precisa achá-las entre milhões. A compactação, assunto da
aula 18, reescreve a partição inteira toda vez que mexe nela, e o repair, da aula 19, a compara como
uma unidade. E os nós donos dela carregam o peso enquanto os vizinhos ficam ociosos. A orientação
habitual da comunidade do Cassandra é manter partições **abaixo de uns 100 MB e, mais importante,
limitadas**: uma partição cujo tamanho depende de quanto tempo um cliente fica é um problema com data
marcada.

## Noventa dias de um cliente, de dois jeitos

Para ver o tamanho, gere noventa dias de visualizações da Ana, uma a cada cinco minutos. Salve isto
como `views.py` e rode na VM, que tem Python 3:

```python
import csv, datetime

start = datetime.datetime(2026, 1, 1, tzinfo=datetime.timezone.utc)
pages = ["/", "/product/KB-101", "/product/MS-204", "/product/MN-330", "/basket"]

with open("views.csv", "w", newline="") as f:
    out = csv.writer(f)
    for i in range(90 * 24 * 12):  # one view every five minutes for 90 days
        t = start + datetime.timedelta(minutes=5 * i)
        out.writerow(["ana@example.com", t.strftime("%Y-%m"),
                      t.strftime("%Y-%m-%d %H:%M:%S+0000"), pages[i % len(pages)]])
```

Cada linha leva também o mês, `2026-01`, porque a segunda tabela abaixo precisa dele na chave; a
primeira o guarda como coluna comum. Depois, duas tabelas que só diferem na chave de partição, e um
arquivo carregado nas duas com o `COPY` do `cqlsh`:

```
ana@vm:~$ python3 views.py
ana@vm:~$ wc -l views.csv
25920 views.csv
ana@vm:~$ head -3 views.csv
ana@example.com,2026-01,2026-01-01 00:00:00+0000,/
ana@example.com,2026-01,2026-01-01 00:05:00+0000,/product/KB-101
ana@example.com,2026-01,2026-01-01 00:10:00+0000,/product/MS-204
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE TABLE shop.views_by_customer (customer text, month text, viewed_at timestamp, page text, PRIMARY KEY (customer, viewed_at));
cqlsh> CREATE TABLE shop.views_by_customer_month (customer text, month text, viewed_at timestamp, page text, PRIMARY KEY ((customer, month), viewed_at));
cqlsh> exit
ana@vm:~$ docker exec -i c1 cqlsh -e "COPY shop.views_by_customer (customer, month, viewed_at, page) FROM STDIN" < views.csv | tail -1
25920 rows imported from 1 files in 0 day, 0 hour, 0 minute, and 1.290 seconds (0 skipped).
ana@vm:~$ docker exec -i c1 cqlsh -e "COPY shop.views_by_customer_month (customer, month, viewed_at, page) FROM STDIN" < views.csv | tail -1
25920 rows imported from 1 files in 0 day, 0 hour, 0 minute, and 1.353 seconds (0 skipped).
```

`views_by_customer` tem uma partição por cliente. **`views_by_customer_month` tem uma por cliente por
mês**, porque sua chave de partição é o par `(customer, month)`: os parênteses internos em `PRIMARY
KEY ((customer, month), viewed_at)` são o que fazem das duas colunas a chave de partição. Isso é
**bucketing**, separar em baldes: um pedaço do tempo entra na chave de partição, para que a partição
pare de crescer quando o seu período termina.

## O que os nós mediram

`nodetool flush` grava em disco o que está em memória, porque os tamanhos de partição abaixo são
medidos nos arquivos. Depois, onde cada partição mora, e o que cada nó guarda:

```
ana@vm:~$ for n in c1 c2 c3; do docker exec $n nodetool flush shop; done
ana@vm:~$ docker exec c1 nodetool getendpoints shop views_by_customer ana@example.com
172.18.0.3
ana@vm:~$ for m in 2026-01 2026-02 2026-03; do docker exec c1 nodetool getendpoints shop views_by_customer_month ana@example.com:$m; done
172.18.0.4
172.18.0.2
172.18.0.3
ana@vm:~$ for n in c1 c2 c3; do echo "== $n"; docker exec $n nodetool tablestats shop.views_by_customer shop.views_by_customer_month | grep -E "Table:|Number of partitions|partition maximum bytes"; done
== c1
		Table: views_by_customer
		Number of partitions (estimate): 0
		Compacted partition maximum bytes: 0
		Table: views_by_customer_month
		Number of partitions (estimate): 1
		Compacted partition maximum bytes: 263210
== c2
		Table: views_by_customer
		Number of partitions (estimate): 1
		Compacted partition maximum bytes: 1131752
		Table: views_by_customer_month
		Number of partitions (estimate): 1
		Compacted partition maximum bytes: 263210
== c3
		Table: views_by_customer
		Number of partitions (estimate): 0
		Compacted partition maximum bytes: 0
		Table: views_by_customer_month
		Number of partitions (estimate): 1
		Compacted partition maximum bytes: 263210
```

`Compacted partition maximum bytes` é a maior partição que o nó gravou em disco, arredondada para
cima até um de um conjunto fixo de degraus, então leia como uma faixa de tamanho e não como uma
contagem exata. O quadro é claro:

| tabela | partições em 90 dias | maior partição | onde |
| --- | --- | --- | --- |
| `views_by_customer` | 1 | 1131752 bytes, cerca de 1,1 MB | toda no `c2`; `c1` e `c3` não guardam nada |
| `views_by_customer_month` | 3 | 263210 bytes, cerca de 0,26 MB cada | um mês em cada nó |

**A tabela sem baldes pôs todo o histórico da Ana num só nó**, e ele cresce cerca de 1,1 MB a cada
noventa dias, para sempre. A com baldes espalhou as mesmas linhas pelos três nós, e cada partição
parou de crescer no último dia do seu mês. Noventa dias é pouco; a conta é que importa. Nesse ritmo
um cliente passa de 40 MB em cerca de uma década, e um sensor gravando a cada segundo em vez de a
cada cinco minutos passaria disso em menos de um mês.

## O que os baldes custam

Uma consulta por "as visualizações da Ana, da mais nova para a mais antiga" agora nomeia um mês,
então a aplicação pede o mês corrente e, se precisar de mais linhas, o anterior, uma partição de cada
vez. É um laço na aplicação em vez de uma consulta só, e esse é o preço habitual. Escolha o balde
pelo ritmo dos dados: um mês para as visualizações de um cliente, um dia ou uma hora para um sensor,
o que mantiver uma partição bem abaixo da orientação e ainda responder à consulta comum com uma ou
duas partições.
