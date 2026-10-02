---
title: Retenção: uma data de validade para cada linha
version: 1
---

Todo armazenamento guarda as linhas até algo apagá-las, e o padrão muitas vezes é *para sempre*.
**Um período de retenção é uma decisão sobre até onde uma investigação consegue olhar para trás**,
pesada contra o custo e contra o risco de guardar dados por mais tempo do que o necessário. A LGPD
conta isso como um risco em si.

O do Loki é uma linha na configuração, aplicada pelo compactor dele, que apaga os chunks mais velhos
que o período:

```
ana@obs:~/shop$ grep -A3 limits_config loki/loki.yaml
limits_config:
  allow_structured_metadata: true
  retention_period: 168h

```

Sete dias no laboratório. O Elasticsearch faz isso com uma **política de ciclo de vida de índice**
(ILM): um data stream passa a escrita para um índice novo num ritmo fixo, e cada índice passa por
fases até a última o apagar. Uma política que troca de índice por dia e apaga depois de uma semana:

```
ana@obs:~/shop$ curl -s -X PUT localhost:9200/_ilm/policy/shop-logs -H 'Content-Type: application/json' -d '{"policy": {"phases": {"hot": {"actions": {"rollover": {"max_age": "1d"}}}, "delete": {"min_age": "7d", "actions": {"delete": {}}}}}}'; echo
{"acknowledged":true}
ana@obs:~/shop$ curl -s localhost:9200/_ilm/policy/shop-logs | jq -c '."shop-logs".policy.phases | map_values(.min_age)'
{"hot":"0ms","delete":"7d"}
```

`hot` a partir do momento em que um índice é criado, `delete` sete dias depois. Numa instalação real a
política é presa ao template de índice do data stream, e fases intermediárias, `warm` e `cold`, levam
índices mais velhos para discos mais baratos antes de saírem.

**Quanto tempo é o certo não é uma pergunta técnica**, e três fatos costumam decidir:

- o máximo que um incidente leva para ser notado e investigado: uma semana muitas vezes basta para
  logs operacionais;
- o que uma lei ou um contrato exige que se guarde, que geralmente são dados de *auditoria*, um fluxo
  separado com armazenamento e regras de acesso próprios, e não as linhas de depuração de um serviço
  web;
- o custo por dia guardado, da seção anterior, multiplicado.

Logs diferentes podem e devem ter períodos diferentes. As linhas `INFO` de uma aplicação por sete
dias, os erros dela por trinta, e a trilha de auditoria pelo tempo que a lei disser, são três
políticas, não uma.
