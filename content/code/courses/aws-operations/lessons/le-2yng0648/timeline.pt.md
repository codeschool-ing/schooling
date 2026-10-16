---
title: A linha do tempo, montada com o que os sistemas registraram
version: 1
---

Toda revisão começa com uma linha do tempo: o que aconteceu, em ordem, com horários. Escrita de memória
no dia seguinte, ela erra nos lugares que importam, os intervalos entre uma causa e o primeiro sinal
dela. **Os sistemas já registraram a linha do tempo**, cada um no seu lugar: a hora de criação do deploy,
as linhas de log, a mudança de estado do alarme. Juntá-los é um programa curto.

O laboratório encena um incidente pequeno, comprimido em meio minuto: um deploy, depois linhas de erro
no grupo de logs da API, depois o alarme entrando em `ALARM` (definido à mão, já que o moto não avalia
alarme nenhum). Aí o programa lê as três fontes de volta, cada uma com sua API, e as junta:

```python
# timeline.py: one incident's events, from three sources, in time order
import datetime as dt

import boto3

events = []
deploy = boto3.client("codedeploy")
for d in deploy.list_deployments(applicationName="shop-api", deploymentGroupName="prod")["deployments"]:
    info = deploy.get_deployment(deploymentId=d)["deploymentInfo"]
    events.append((info["createTime"], "deploy", f"deployment {d[:8]} created"))

logs = boto3.client("logs")
for e in logs.filter_log_events(logGroupName="/shop/api", filterPattern="503")["events"]:
    t = dt.datetime.fromtimestamp(e["timestamp"] / 1000, dt.timezone.utc)
    events.append((t, "logs", e["message"]))

cloudwatch = boto3.client("cloudwatch")
for a in cloudwatch.describe_alarms(AlarmNames=["api-errors"])["MetricAlarms"]:
    events.append((a["StateUpdatedTimestamp"], "alarm", f'{a["AlarmName"]} {a["StateValue"]}'))

for t, source, what in sorted(events):
    print(f"{t.astimezone(dt.timezone.utc):%H:%M:%S}  {source:<6}  {what}")
```

```
ana@laptop:~/aws/incident$ python3 timeline.py
16:58:53  deploy  deployment 7fe87a08 created
16:59:01  logs    {"status":503,"path":"/checkout"}
16:59:05  logs    {"status":503,"path":"/checkout"}
16:59:08  logs    {"status":503,"path":"/cart"}
16:59:18  alarm   api-errors ALARM
```

Leia como um revisor leria. Um deploy às 16:58:53; **oito segundos depois**, o primeiro 503 em
`/checkout`; o alarme às 16:59:18, dezessete segundos depois do primeiro erro. Comprimida como está, a
forma é a que incidentes reais têm: a mudança vem primeiro, o sintoma depois, e o alarme por último,
porque ele espera um padrão (lição 10). Ninguém precisou lembrar de nada.

Três hábitos deixam uma linha do tempo real assim fácil:

- **todas as fontes num fuso só**, UTC nas ferramentas e o horário local acrescentado para as pessoas,
  nunca misturados;
- **um registro de deploy para cada mudança**, inclusive as feitas à mão numa emergência, para a
  pergunta "o que mudou?" ter uma resposta a ler em vez de a reconstruir;
- **as mensagens do próprio canal são uma fonte**: quando o comandante decidiu reverter, e quando o
  gráfico virou, também são horários, e o trabalho do escriba é deixá-los exatos.

O resto da linha do tempo, quem fez o quê e por quê, vem das pessoas, na revisão, que é o assunto da
próxima seção.
