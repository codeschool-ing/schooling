---
title: Triagem, sobre uma lista de achados
version: 1
---

**O Security Command Center não roda no seu computador, mas os achados que ele produz são dados, e triagem é o que se
faz com dados.** A lista abaixo foi **escrita por este curso, não pelo Security Command Center**: oito achados para o
projeto da loja, usando os nomes de campo e os valores que a documentação do Google dá para um achado (`category`,
`severity`, `state`, `mute`, `findingClass`, `resourceName`, `eventTime`), e nenhum outro. Uma exportação real tem
muitos campos a mais; estes são os que a triagem lê. Salve-a como `~/gcp/findings.jsonl`, um achado por linha,
exatamente como aqui, `findings.jsonl`:

```
{"category": "PUBLIC_BUCKET_ACL", "severity": "HIGH", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "MISCONFIGURATION", "resourceName": "//storage.googleapis.com/planner-dev-shop-assets", "eventTime": "2026-10-28T09:12:00Z"}
{"category": "OPEN_FIREWALL", "severity": "HIGH", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "MISCONFIGURATION", "resourceName": "//compute.googleapis.com/projects/planner-dev/global/firewalls/allow-ssh-anywhere", "eventTime": "2026-10-27T17:40:00Z"}
{"category": "SERVICE_ACCOUNT_KEY_NOT_ROTATED", "severity": "MEDIUM", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "MISCONFIGURATION", "resourceName": "//iam.googleapis.com/projects/planner-dev/serviceAccounts/legacy-batch@planner-dev.iam.gserviceaccount.com", "eventTime": "2026-10-20T08:00:00Z"}
{"category": "OS_VULNERABILITY", "severity": "CRITICAL", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "VULNERABILITY", "resourceName": "//compute.googleapis.com/projects/planner-dev/zones/southamerica-east1-a/instances/batch-1", "eventTime": "2026-10-29T03:15:00Z"}
{"category": "OS_VULNERABILITY", "severity": "CRITICAL", "state": "ACTIVE", "mute": "MUTED", "findingClass": "VULNERABILITY", "resourceName": "//compute.googleapis.com/projects/planner-dev/zones/southamerica-east1-a/instances/sandbox-ana", "eventTime": "2026-10-29T03:15:00Z"}
{"category": "MFA_NOT_ENFORCED", "severity": "HIGH", "state": "INACTIVE", "mute": "UNMUTED", "findingClass": "MISCONFIGURATION", "resourceName": "//cloudresourcemanager.googleapis.com/organizations/123456789012", "eventTime": "2026-10-02T11:00:00Z"}
{"category": "AUDIT_LOGGING_DISABLED", "severity": "LOW", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "MISCONFIGURATION", "resourceName": "//cloudresourcemanager.googleapis.com/projects/planner-dev", "eventTime": "2026-10-15T10:30:00Z"}
{"category": "Persistence: IAM Anomalous Grant", "severity": "HIGH", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "THREAT", "resourceName": "//cloudresourcemanager.googleapis.com/projects/planner-dev", "eventTime": "2026-10-30T02:47:00Z"}
```

## Quanto, e quão grave

```
ana@laptop:~/gcp$ wc -l findings.jsonl
8 findings.jsonl
ana@laptop:~/gcp$ jq -s -c 'group_by(.severity) | map({severity: .[0].severity, count: length})' findings.jsonl
[{"severity":"CRITICAL","count":2},{"severity":"HIGH","count":4},{"severity":"LOW","count":1},{"severity":"MEDIUM","count":1}]
```

Dois críticos e quatro altos, de oito. **Uma contagem por severidade é onde a triagem começa e nunca onde termina**: um
dos críticos está silenciado, um dos altos não está mais ativo. Fique só com o que está aberto:

```
ana@laptop:~/gcp$ jq -c 'select(.state == "ACTIVE" and .mute == "UNMUTED")' findings.jsonl | wc -l
6
ana@laptop:~/gcp$ jq -r 'select(.state == "ACTIVE" and .mute == "UNMUTED" and (.severity == "CRITICAL" or .severity == "HIGH")) | [.findingClass, .severity, .category] | @tsv' findings.jsonl
MISCONFIGURATION	HIGH	PUBLIC_BUCKET_ACL
MISCONFIGURATION	HIGH	OPEN_FIREWALL
VULNERABILITY	CRITICAL	OS_VULNERABILITY
THREAT	HIGH	Persistence: IAM Anomalous Grant
```

Seis abertos, quatro deles altos ou críticos. Agora a ordem.

## Em que agir primeiro

A severidade sozinha poria a vulnerabilidade crítica primeiro. A ordem da loja põe a **ameaça** primeiro, seja qual for
a severidade, porque é o único achado que diz que algo pode estar acontecendo agora em vez de poder acontecer:

```
ana@laptop:~/gcp$ jq -r 'select(.findingClass == "THREAT") | [.eventTime, .category, .resourceName] | @tsv' findings.jsonl
2026-10-30T02:47:00Z	Persistence: IAM Anomalous Grant	//cloudresourcemanager.googleapis.com/projects/planner-dev
```

Uma concessão de permissão anômala no projeto, às 02:47 de hoje. Isso é o começo de um incidente (lição 15), não um
chamado na fila: descubra quem fez a concessão no log de auditoria, se era esperada, e remova-a se não era. Depois:

1. **`PUBLIC_BUCKET_ACL` em `planner-dev-shop-assets`.** Uma configuração errada que expõe dados a qualquer um,
   corrigida em minutos. Confira o que o bucket guarda: se é a lista de preços, que é pública de qualquer jeito, a
   correção ainda importa, porque o próximo objeto que alguém puser nele também seria público.
2. **`OS_VULNERABILITY` na `batch-1`.** Crítica, numa máquina que roda. A correção é a que a lição 2 descreveu: uma
   imagem corrigida, reconstruída e com novo deploy.
3. **`OPEN_FIREWALL`, `allow-ssh-anywhere`.** SSH aberto para a internet num projeto cujos serviços são Cloud Run.
   Ninguém deveria precisar; apague a regra.
4. **`SERVICE_ACCOUNT_KEY_NOT_ROTATED`** e **`AUDIT_LOGGING_DISABLED`**: chamados para a semana. A chave fica melhor
   apagada do que girada (lição 8 de `gcp-foundations`), e a lacuna de log é o que teria tornado impossível investigar o
   achado de ameaça.

A vulnerabilidade crítica silenciada está na `sandbox-ana`. O silenciamento só é aceitável se a sandbox não guarda nada
e não alcança nada; **um achado silenciado é revisado como uma política**, num calendário, porque a sandbox que não
guardava nada em março guarda uma cópia dos dados de produção em junho.
