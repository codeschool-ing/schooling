---
title: Os cinco, lado a lado
version: 1
---

Cinco bancos numa aula são demais para guardar na cabeça como produtos. Guardados como respostas às
perguntas da aula 4, eles se reduzem a uma tabela, e toda linha dela é algo que você viu nesta aula:

| | a unidade | onde uma linha mora | a pergunta rápida | a recusada ou cara | visto aqui |
|---|---|---|---|---|---|
| **MongoDB** | um documento | um shard, por uma chave de shard, quando há sharding | um documento, ou um filtro num campo indexado | o mesmo filtro sem índice; um fato copiado em muitos documentos | `COLLSCAN` de 100 para 34; 33 documentos reescritos por uma mudança de nome |
| **DynamoDB** | um item | uma partição, pelo hash da chave de partição | uma chave de partição, uma faixa da chave de ordenação | qualquer coisa sem a chave de partição | uma consulta pela chave de ordenação recusada; uma varredura lendo 5 para devolver 3 |
| **Cassandra** | uma linha numa partição | um nó, pelo token da chave de partição | uma partição, na ordem de agrupamento | um filtro numa coluna fora da chave | `ALLOW FILTERING` exigido; 803 MB para seis linhas |
| **Neo4j** | um nó e as suas relações | um primário | uma caminhada a partir de um nó conhecido | somas sobre conjuntos grandes; sharding | 182 acessos para uma caminhada de dois passos |
| **InfluxDB** | um ponto numa série | um shard por faixa de tempo | uma faixa de tempo, agregada | uma tag com milhões de valores | três horas de minutos somadas por hora; 30 dias de retenção |

Três coisas valem para os cinco, e são o motivo de este curso ter gasto três aulas com partições,
réplicas e consistência antes de chegar a eles:

- **A chave é o desenho.** Cada um é rápido exatamente onde a chave o deixa ir direto aos dados, e
  cada um recusa ou cobra caro em todo o resto.
- **Cada um faz a troca da aula 3 em algum lugar.** As leituras do DynamoDB são eventualmente
  consistentes a menos que você pague pelas fortes; o Cassandra deixa cada consulta nomear o seu
  quórum; o MongoDB deixa cada leitura e escrita escolher; o Neo4j mantém as escritas num primário, e
  o servidor de código aberto do InfluxDB é um nó só.
- **Nenhum deles é motivo para deixar o PostgreSQL sozinho.** Cada um ganhou o lugar nesta aula
  respondendo uma pergunta melhor, e a seção 10 da aula 4 é o teste para saber se essa pergunta vale
  um segundo banco num sistema seu.

## Arrumando

Todo contêiner foi removido no fim da sua seção. As imagens continuam no disco; `docker image ls` as
lista com os tamanhos, e `docker image rm` seguido de um nome remove uma. A aula 6 volta à bilheteria
e ao PostgreSQL dela.
