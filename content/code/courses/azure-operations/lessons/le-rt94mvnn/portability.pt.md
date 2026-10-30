---
title: Mudando para onde a telemetria vai, e mais nada
version: 1
---

**Tudo em `shop_trace.py` abaixo do bloco de preparação é neutro em relação a fornecedor**: spans, tipos, atributos,
status e exceções são do OpenTelemetry, e nenhuma linha deles menciona o Azure. Mandar os mesmos spans ao Application
Insights troca o bloco de preparação e mais nada. Com a distro, instalada como o pacote `azure-monitor-opentelemetry`, ele
vira:

```python
# the setup block, with Azure Monitor's distro instead of the console exporter
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace

configure_azure_monitor()   # reads APPLICATIONINSIGHTS_CONNECTION_STRING from the environment
tracer = trace.get_tracer("shop")
```

Isso **não foi executado** aqui. Precisa de uma connection string, que nomeia um recurso real do Application Insights e o
endpoint de ingestão dele, e o curso não tem recurso para nomear. A connection string não é um segredo no sentido da lição
2: ela deixa qualquer um que a tenha **enviar** telemetria ao recurso, não ler, e por isso a Microsoft a documenta como
segura para ficar na configuração. Ainda assim é melhor mantê-la fora do repositório, porque um estranho com ela consegue
encher o seu workspace, e a sua conta, de linhas.

Ir para o outro lado é a mesma edição. Apontada para um **OpenTelemetry Collector** com o exportador OTLP, a aplicação não
sabe nem se importa com qual backend está atrás; o collector pode mandar para o Azure Monitor, para outro fornecedor, ou
para os dois enquanto uma equipe compara. Configurado por variáveis de ambiente, como a especificação define:

```sh
export OTEL_SERVICE_NAME=shop-api
export OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.internal.example:4317
```

É a portabilidade que o título desta lição promete, e vale dizer o limite dela. **A instrumentação muda de lugar; as
consultas não.** O KQL das lições 10 a 12, escrito contra a `AppRequests`, não significa nada para outro backend. Uma
equipe que troca de fornecedor mantém os spans e reescreve alertas, painéis e os hábitos de quem os lê, que é a maior parte
do trabalho.
