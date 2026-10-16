---
title: Uma regra personalizada, à mão
version: 1
---

Quando nenhuma regra gerenciada diz o que a equipe quer dizer, uma **regra personalizada** diz: uma função
Lambda que o Config invoca com o item de configuração do recurso que mudou, que o julga e responde com
`PutEvaluations`. A regra da loja para buckets junta as duas da seção anterior com as próprias palavras:
**um bucket tem dono, e bloqueia todo tipo de acesso público**.

O laboratório não tem Lambda para invocar, então `evaluate.py` faz à mão o que uma função dessas faz,
sobre o mesmo inventário: lê o item de configuração mais recente de cada bucket no Config, o julga e
reporta as avaliações.

```python
# evaluate.py: what a custom Config rule does, run by hand over Config's own inventory
import datetime as dt
import json

import boto3

config = boto3.client("config")


def verdict(item):
    """The rule: a bucket has an owner tag and blocks every kind of public access."""
    if "owner" not in item.get("tags", {}):
        return "NON_COMPLIANT", "no owner tag"
    block = json.loads(item["supplementaryConfiguration"].get("PublicAccessBlockConfiguration", "{}"))
    if not all(block.get(k) for k in ("blockPublicAcls", "ignorePublicAcls",
                                      "blockPublicPolicy", "restrictPublicBuckets")):
        return "NON_COMPLIANT", "public access not fully blocked"
    return "COMPLIANT", ""


keys = config.list_discovered_resources(resourceType="AWS::S3::Bucket")["resourceIdentifiers"]
items = [config.get_resource_config_history(resourceType=k["resourceType"], resourceId=k["resourceId"],
                                            limit=1)["configurationItems"][0] for k in keys]

evaluations = []
for item in sorted(items, key=lambda i: i["resourceId"]):
    result, why = verdict(item)
    print(f'{item["resourceId"]:<28} {result:<14} {why}'.rstrip())
    evaluations.append({"ComplianceResourceType": item["resourceType"],
                        "ComplianceResourceId": item["resourceId"],
                        "ComplianceType": result, "Annotation": why or "ok",
                        "OrderingTimestamp": dt.datetime.now(dt.timezone.utc)})

# a real custom rule gets ResultToken from the event that invoked it; TestMode records nothing
answer = config.put_evaluations(Evaluations=evaluations, ResultToken="TESTMODE", TestMode=True)
print("rejected by Config:", len(answer["FailedEvaluations"]))
```

```
ana@laptop:~/aws/config$ python3 evaluate.py
shop-config-123456789012     COMPLIANT
shop-exports                 NON_COMPLIANT  public access not fully blocked
shop-orders                  COMPLIANT
tmp-test-ana                 NON_COMPLIANT  no owner tag
rejected by Config: 0
```

Dois buckets passam. `shop-exports` tem dono e não tem bloqueio de acesso público, e é o perigoso: nada
impede que alguém torne uma exportação pública com uma política. `tmp-test-ana` não tem dono, que é o
assunto da lição 24, o recurso de ninguém.

Leia `verdict` pelo que ela não faz. **Ela nunca chama o S3.** Tudo o que ela sabe veio do item de
configuração, das tags e da configuração suplementar que o Config gravou; é isso que torna o veredito de
uma regra reproduzível, já que o item diz exatamente o que foi julgado e quando. Uma função que
perguntasse ao S3 direto estaria julgando o bucket como ele está naquele momento, que pode não ser a
versão que a disparou.

A última linha é a parte honesta. Uma invocação real traz um `ResultToken`, e as avaliações ficam
registradas na regra; com `TestMode`, como aqui, o Config confere as avaliações e não registra nada. Zero
rejeitadas quer dizer que a forma está certa, que é o que um laboratório consegue provar.
