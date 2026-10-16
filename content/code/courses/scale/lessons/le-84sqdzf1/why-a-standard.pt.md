---
title: Por que a telemetria precisou de um padrão
version: 1
---

A aula 7 instrumentou a bilheteria com `prometheus_client`, uma biblioteca que fala um formato com
um sistema. Era assim que se instrumentava em todo lugar, e isso tem um custo que só aparece depois:
**o código que registra os sinais fica preso ao produto que os guarda.** Uma equipe que troca de
fornecedor de monitoramento reescreve a instrumentação de todo serviço. Uma biblioteca que quer
emitir rastros precisa escolher um fornecedor por todos os seus usuários. E um pedido que atravessa
dois serviços escritos por duas equipes, com bibliotecas de dois fornecedores, não pode ser seguido
de jeito nenhum, porque as duas não concordam em como passar um rastro de uma para a outra.

O **OpenTelemetry** é a resposta em que a indústria convergiu, sob a Cloud Native Computing
Foundation, a partir de dois projetos anteriores, o OpenTracing e o OpenCensus. Ele padroniza a parte
da observabilidade que mora no seu código, e deixa o armazenamento e as telas para quem você
escolher:

- **uma API** que o código chama para criar spans, registrar métricas e escrever logs, a mesma em
  toda linguagem;
- **um SDK** por linguagem que a implementa: amostragem, lotes e exportação;
- o **OTLP**, o protocolo do OpenTelemetry, o único formato que toda peça fala na rede;
- o **Collector**, um programa que recebe telemetria por OTLP e muitos outros formatos, a processa e
  a manda para um ou vários back ends;
- **convenções semânticas**, nomes combinados para atributos comuns, como `http.route` e
  `http.response.status_code`, para que todo serviço descreva um pedido HTTP do mesmo jeito.

O que ele não inclui é um banco de dados nem uma interface. Os rastros vão para o Jaeger, o Tempo, o
Zipkin ou um serviço hospedado; as métricas para o Prometheus ou um serviço hospedado; os logs para o
que guardar logs. **Trocar o back end é uma mudança na configuração do Collector, e não no código de
nenhum serviço.**

Esta aula acrescenta um segundo serviço à bilheteria, para que um pedido atravesse a fronteira entre
processos, rastreia os dois com o OpenTelemetry e lê o resultado no Jaeger.
