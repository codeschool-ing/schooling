---
title: Cinco produtos e para que serve cada um
version: 1
---

O título da aula cita cinco produtos, e os anúncios de vaga citam do mesmo jeito, como se fossem
cinco marcas de uma coisa só. Não são. Cada um começou de um dos três sinais, ou de um jeito de
olhar para eles, e cresceu dali para fora; hoje os catálogos se sobrepõem tanto que o ponto de
partida é a melhor forma de lembrar para que serve cada um.

| produto | começou como | a pergunta que responde melhor | roda onde |
|---|---|---|---|
| **New Relic** | APM, monitoramento de desempenho de aplicação: um agente dentro da sua aplicação que cronometra cada transação | qual endpoint ficou lento, e qual chamada dentro dele | um serviço hospedado |
| **Datadog** | métricas de infraestrutura: um agente em cada host, coletando processadores, discos, contêineres | qual máquina, contêiner ou fila está com problema | um serviço hospedado |
| **Grafana** | painéis: gráficos desenhados sobre dados guardados em outro lugar, quase sempre o Prometheus | como os números se parecem, lado a lado, ao longo do tempo | o seu próprio servidor, ou o hospedado da Grafana Labs |
| **Kibana** | a tela de busca do Elasticsearch: logs indexados para que qualquer campo possa ser filtrado | quais linhas de log batem, e o que elas têm em comum | o seu próprio servidor, ou o hospedado da Elastic |
| **Sentry** | rastreamento de erros: cada exceção, com o seu stack trace, agrupada com as parecidas | qual erro é novo desde a última versão, e quantos usuários ele atingiu | um serviço hospedado, ou o seu próprio servidor |

**APM** é a mais antiga das categorias e a que mais se parece com o que você fez neste curso. Um
agente de APM é uma biblioteca carregada na aplicação. Ele embrulha cada requisição que chega e
cada chamada que sai — o banco, um cliente HTTP, uma fila — e assim consegue relatar um trace para
uma amostra das requisições e métricas RED para todas, sem você escrever uma linha. New Relic,
Datadog, Dynatrace e Elastic vendem um.

**O Grafana não guarda nada sozinho.** Ele desenha o que uma fonte de dados responde: Prometheus,
Loki para logs, Tempo para traces, um banco SQL, Elasticsearch. É por isso que ele fica ao lado do
Prometheus em tantas equipes: o Prometheus coleta e responde consultas, o Grafana desenha as
respostas. A empresa por trás dele, a Grafana Labs, também é dona do k6, e é por isso que o banner de
toda execução do k6 neste curso diz *Grafana*.

**O Sentry é o que um desenvolvedor abre primeiro**, porque responde na língua do código: esta
exceção, neste arquivo, nesta linha, introduzida nesta versão, vista por tantos usuários. As
métricas dizem que os erros subiram. O Sentry diz qual erro foi.

## O que esta aula roda no lugar deles

Os cinco são serviços em que você se cadastra ou servidores que você instala e alimenta, e nenhum
deles roda na máquina em que este curso foi gravado. **Nada nesta aula mostra uma captura de tela
de nenhum deles**, e nada cita a saída deles, porque nada disso foi executado aqui. As telas mudam a
cada poucos meses; para que serve cada um muda bem mais devagar.

O que a aula roda é o núcleo de código aberto em torno do qual dois deles foram construídos:

- **Prometheus** para métricas, o sistema que o Grafana mais desenha, instalado do repositório do
  Ubuntu. A linguagem de consulta dele, PromQL, é a que a aula 24 usa para escrever o alerta, e o
  serviço hospedado de métricas da própria Grafana também fala essa língua.
- **`jq` sobre um arquivo de linhas JSON** para logs. É o trabalho do Kibana no tamanho de uma
  máquina: filtrar por um campo, contar, achar uma requisição pelo id. O Kibana faz o mesmo sobre
  bilhões de linhas de centenas de máquinas, com um índice que o deixa rápido.

Rastreamento de erros e tracing você vai ver em miniatura: o campo de erro que a boxoffice escreve
no log quando uma requisição quebra, e o cabeçalho `Server-Timing` que ela já manda.

## Aprisionamento, e o OpenTelemetry

Cada um desses produtos começou com o seu próprio agente, o seu próprio formato de transmissão e a
sua própria linguagem de consulta: o New Relic tem a NRQL, o Datadog uma sintaxe de consulta
própria, o Prometheus a PromQL, o Kibana a KQL e a Lucene. **A instrumentação é a parte cara de
trocar**, porque ela mora dentro de cada serviço que a empresa roda, e os painéis e alertas escritos
na língua de um fornecedor não se mudam para a de outro. Uma equipe que instrumentou tudo com o
agente de um fornecedor em 2018 paga o preço desse fornecedor em 2028, ou reinstrumenta cada serviço.

O **OpenTelemetry** é a resposta do setor: um padrão aberto, sob a Cloud Native Computing
Foundation, para produzir os três sinais. Ele define as bibliotecas que uma aplicação usa para
emitir métricas, logs e traces, um protocolo de transmissão chamado OTLP, e um *coletor*, um
programa que recebe esses dados e os encaminha para o back-end que você escolher. Instrumente com
OpenTelemetry uma vez, e trocar de fornecedor passa a ser mudar para onde o coletor manda as coisas,
sem mexer na aplicação. Os cinco produtos acima publicam maneiras de receber dados do
OpenTelemetry, embora o quanto cada um cobre varie, e mude mais rápido do que este curso.

Ele não remove o aprisionamento da linguagem de consulta. **Um alerta escrito em PromQL continua
sendo um alerta escrito em PromQL**, e as regras da aula 24 precisariam ser reescritas para um
produto que não fala essa língua.
