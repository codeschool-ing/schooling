---
title: A primeira sincronização
version: 1
---

A sincronização é um script de shell curto: o `psql` lê o modelo, o `curl` manda cada contato e o
`psql` anota o que aconteceu. Salve como `~/reverse/sync.sh`, de novo com o botão de copiar:

```schooling-example
{"language": "sh", "file": "sync.sh", "parts": [{"code": "#!/usr/bin/env bash\n# sync.sh: send what changed in activation.crm_contacts to the CRM, and remember it.\nset -u\nCRM=http://localhost:8000\ndb() { psql -qAtX -v ON_ERROR_STOP=1 lantern \"$@\"; }\nRUN=$(db -c \"SELECT coalesce(max(run_id), 0) + 1 FROM activation.sync_log\")\nsent=0; removed=0; failed=0; retried=0", "note": "`db` roda uma instrução em `lantern` e imprime o resultado cru. Cada execução ganha um número um acima do último do log, e quatro contadores."}, {"code": "send() {                        # send METHOD ID [PAYLOAD]; sets $code, retries a 429\n  for attempt in 1 2 3 4 5; do\n    code=$(curl -s -o /tmp/crm-reply -w '%{http_code}' -X \"$1\" \"$CRM/contacts/$2\" \\\n           -H 'Content-Type: application/json' ${3:+-d \"$3\"})\n    [ \"$code\" = 429 ] || return 0\n    retried=$((retried + 1)); sleep 1\n  done\n}", "note": "`send` faz uma requisição com `curl` e guarda o código de status em `code`. No `429`, espera um segundo e tenta de novo, até cinco vezes."}, {"code": "log() {                         # log ID ACTION\n  db -v run=\"$RUN\" -v id=\"$1\" -v action=\"$2\" -v code=\"$code\" <<'SQL'\nINSERT INTO activation.sync_log (run_id, external_id, action, http_status)\nVALUES (:run, :'id', :'action', :code);\nSQL\n}", "note": "Toda tentativa vai para `sync_log`: qual execução, qual contato, o que foi feito, o que o CRM respondeu. Os valores entram como variáveis do psql, `:'id'`, que os põem entre aspas com segurança."}, {"code": "while IFS=$'\\t' read -r id payload; do\n  send PUT \"$id\" \"$payload\"; log \"$id\" upsert\n  if [ \"$code\" = 200 ] || [ \"$code\" = 201 ]; then\n    db -v id=\"$id\" -v payload=\"$payload\" <<'SQL'\nINSERT INTO activation.last_sent VALUES (:'id', :'payload', now())\nON CONFLICT (external_id) DO UPDATE SET payload = EXCLUDED.payload, sent_at = now();\nSQL\n    sent=$((sent + 1))\n  else\n    failed=$((failed + 1)); echo \"$id: HTTP $code $(cat /tmp/crm-reply)\"\n  fi\ndone < <(db -F $'\\t' -c \"\n  SELECT m.external_id, row_to_json(m)\n  FROM activation.crm_contacts m LEFT JOIN activation.last_sent s USING (external_id)\n  WHERE s.payload IS DISTINCT FROM row_to_json(m)::jsonb\n  ORDER BY m.external_id\")", "note": "O primeiro laço lê os contatos cuja linha atual difere do que foi enviado por último — a diferença — e faz um PUT de cada um. Só depois de o CRM aceitar é que a linha fica guardada em `last_sent`; uma falha é impressa e fica para a próxima execução."}, {"code": "while read -r id; do\n  send DELETE \"$id\"; log \"$id\" delete\n  if [ \"$code\" = 200 ] || [ \"$code\" = 404 ]; then\n    db -v id=\"$id\" <<<\"DELETE FROM activation.last_sent WHERE external_id = :'id';\"\n    removed=$((removed + 1))\n  else\n    failed=$((failed + 1)); echo \"$id: HTTP $code $(cat /tmp/crm-reply)\"\n  fi\ndone < <(db -c \"\n  SELECT s.external_id FROM activation.last_sent s\n  WHERE NOT EXISTS (SELECT 1 FROM activation.crm_contacts m WHERE m.external_id = s.external_id)\n  ORDER BY 1\")", "note": "O segundo laço acha contatos que foram enviados antes e não estão mais no modelo, e os apaga do CRM. Um `404` conta como feito: ele já não estava lá."}, {"code": "echo \"run $RUN: sent $sent, removed $removed, failed $failed, retried after 429: $retried\"", "note": "Uma linha diz o que a execução fez."}]}
```

Rode. Na primeira vez todo contato é novo, então todo contato é enviado, uma requisição depois da outra
— 2.649 delas, alguns minutos de trabalho:

```
ana@vm:~/reverse$ bash sync.sh
run 1: sent 2649, removed 0, failed 0, retried after 429: 254
```

Tudo enviado e nada falhou. O último número é quantas requisições o CRM recusou por chegarem rápido
demais e o script repetiu depois de um segundo de pausa; ele depende da velocidade da sua máquina, então
o seu vai ser outro. O lado do CRM:

```
ana@vm:~/reverse$ curl -s -w '\n' localhost:8000/stats
{"requests": 2903, "refused": 254, "contacts": 2649}
```

E um contato, como o CRM o guarda agora:

```
ana@vm:~/reverse$ curl -s -w '\n' 'localhost:8000/contacts?external_id=lantern-1500'
[{"external_id": "lantern-1500", "segment": "home", "region": "Southeast", "orders": 6, "net_revenue": 553.22, "last_order": "2026-01-18", "health": "lapsed", "crm_id": 558}]
```

O cliente 1500 está no CRM com todos os campos do modelo, mais `crm_id`, o número que o próprio CRM dá
ao registro. Um vendedor que abre esse contato vê *lapsed*, seis pedidos e R$ 553,22, sem que ninguém
tenha exportado nada.
