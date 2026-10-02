---
title: Escolhendo entre eles
version: 1
---

Os três guardaram as mesmas linhas e responderam às mesmas perguntas, então a escolha não é sobre o
que conseguem achar. **É sobre onde cada um paga**, e isso decorre de como ele indexa:

| | Loki | Elasticsearch | Graylog |
|---|---|---|---|
| indexa | os labels de cada stream | todo campo de toda linha | todo campo, no OpenSearch por baixo |
| linguagem de consulta | LogQL, parecida com PromQL | a query DSL dele, e outras por cima | uma sintaxe de busca própria |
| barato | escrever e guardar; ele comprime chunks e os mantém em armazenamento de objetos | buscar muitos campos de uma vez, e agregar | o mesmo que o Elasticsearch |
| caro | uma busca em muitos streams só com filtro de linha | memória, disco e o índice a cada escrita | o mesmo, mais o MongoDB e o próprio Graylog |
| vem com | Grafana, para ler | Kibana, que este laboratório não roda | interface própria, streams e alertas |
| lar típico | equipes que já usam Prometheus e Grafana | equipes que buscam em logs como dados, segurança e análise | equipes que querem um produto só para logs, com papéis e alertas |

**Dois avisos que valem qualquer que seja a escolha.** O custo de um armazenamento de logs é dado
pelo volume que ele recebe, e é por isso que o conselho da aula 8 vem antes de qualquer um destes e
a retenção da aula 10 vem logo depois. E labels no Loki carregam o mesmo perigo que labels no
Prometheus: um label por requisição, usuário ou id de rastro é um stream por valor, e o índice pequeno
que torna o Loki barato deixa de ser pequeno. Valores assim vão na linha, onde `| json` e um filtro os
acham.

As outras partes do Elastic Stack, o **Logstash** ou os **Beats** para transportar e o **Kibana** para
ler, ficam de fora deste laboratório de propósito: o Collector já transporta, e as telas do Kibana são
um produto que muda mais rápido que este curso. O que o laboratório mostra é a parte que decide o
custo, o índice, e a consulta que chega a ele.
