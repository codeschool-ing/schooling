---
title: Em que agir primeiro
version: 1
---

Ordenar achados só por severidade põe um CVE crítico num utilitário de build que ninguém alcança acima de
um achado alto que diz que alguém está usando as credenciais da loja agora. Severidade é quão grave uma
coisa seria; a ordem de agir também pergunta **se ela está acontecendo** e **se o caminho de entrada está
aberto**. Três perguntas, nesta ordem:

1. **Alguém está dentro agora?** Um achado de ameaça, de severidade alta, do GuardDuty: credenciais usadas
   de outro lugar, uma instância conversando com um pool de mineração. Cada hora de espera é uma hora em
   que outra pessoa tem acesso.
2. **Existe um caminho de entrada conhecido e publicado?** Uma vulnerabilidade crítica ou alta com exploit
   disponível, em algo que roda. Atacantes usam exploits publicados poucos dias depois da publicação.
3. **É alto ou crítico?** Todo o resto dessa severidade, no dia de trabalho.

O resto é o backlog, lido toda semana. `triage.py` escreve a ordem:

```python
# triage.py: the findings in the order to act on them
import boto3

SEVERITY = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3, "INFORMATIONAL": 4}


def tier(f):
    kind = f["Types"][0]
    sev = f["Severity"]["Label"]
    if kind.startswith(("TTPs", "Effects", "Unusual Behaviors")) and sev in ("CRITICAL", "HIGH"):
        return 1  # somebody may be inside now
    exploit = any(v.get("ExploitAvailable") == "YES" for v in f.get("Vulnerabilities", []))
    if exploit and sev in ("CRITICAL", "HIGH"):
        return 2  # a known way in, published
    return 3 if sev in ("CRITICAL", "HIGH") else 4


hub = boto3.client("securityhub")
filters = {"RecordState": [{"Value": "ACTIVE", "Comparison": "EQUALS"}]}
found = hub.get_findings(Filters=filters, MaxResults=100)["Findings"]
for f in sorted(found, key=lambda f: (tier(f), SEVERITY[f["Severity"]["Label"]])):
    print(tier(f), f'{f["Severity"]["Label"]:<8}', f["Title"], "|", f["Resources"][0]["Id"])
```

```
ana@laptop:~/aws/findings$ python3 triage.py
1 HIGH     Instance credentials used from outside AWS | shop-api-task
2 CRITICAL CVE in a library of the api image | shop/api:9f1c2ab34de5
3 CRITICAL CVE in a build tool of the worker image | shop/worker:77ad01
3 HIGH     S3 bucket allows public read | shop-exports
4 MEDIUM   CloudTrail log file validation is off | shop-trail
4 LOW      Port 22 probed on an instance | i-0lab1
```

O achado das credenciais vem primeiro mesmo sendo só alto: é o que está acontecendo. O CVE com exploit vem
em segundo; o outro CVE crítico, num utilitário de build de uma imagem cujo exploit ninguém publicou, vem
em terceiro, ao lado do bucket público.

**O programa não sabe o que uma pessoa sabe.** `shop-exports` está no terceiro nível porque nada no achado
diz o que o bucket guarda. Se guarda exportações de clientes, é um vazamento em andamento e vai para o
topo; se guarda o catálogo público de produtos, é esperado e o achado é suprimido com esse motivo. Uma
ordem de triagem é um ponto de partida para quem a lê, não um substituto.

## Prazos por nível

Uma equipe escreve quanto tempo cada nível pode esperar, e reporta contra isso. Uma forma comum:

| nível | tratado em | como chega às pessoas |
|---|---|---|
| 1, alguém pode estar dentro | uma hora, dia ou noite | um chamado, o `shop-page` da lição 14 |
| 2, um caminho publicado | dois dias | um ticket, trabalhado primeiro |
| 3, alto ou crítico | duas semanas | um ticket |
| 4, o resto | a revisão semanal | a fila |

## Mandando o primeiro nível para um chamado

O GuardDuty manda cada achado ao EventBridge como um evento, e uma regra com um padrão escolhe os que
chamam alguém. `guardduty-high.json`:

```json
{
  "source": ["aws.guardduty"],
  "detail-type": ["GuardDuty Finding"],
  "detail": { "severity": [{ "numeric": [">=", 7] }] }
}
```

```
ana@laptop:~/aws/findings$ aws events put-rule --name guardduty-high --event-pattern file://guardduty-high.json --query RuleArn --output text
arn:aws:events:sa-east-1:123456789012:rule/guardduty-high
ana@laptop:~/aws/findings$ aws sns create-topic --name shop-page --query TopicArn --output text
arn:aws:sns:sa-east-1:123456789012:shop-page
ana@laptop:~/aws/findings$ aws events put-targets --rule guardduty-high --targets Id=page,Arn=arn:aws:sns:sa-east-1:123456789012:shop-page --query FailedEntryCount
0
```

A regra casa achados do GuardDuty de severidade 7 ou mais e os manda ao tópico de chamados. No laboratório
nada vai casar nunca, já que o GuardDuty do moto não levanta achados; na AWS, `create-sample-findings`
seguido de uma olhada no telefone é o teste. Um achado de severidade 7 nem sempre é nível 1, então o
primeiro trabalho do chamado, para quem o recebe, é a triagem acima.
