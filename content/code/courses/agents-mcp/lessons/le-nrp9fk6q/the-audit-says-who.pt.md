---
title: A auditoria diz quem
version: 2
---

Toda decisão nas execuções desta aula escreveu uma linha. O teste do sinal escreveu no diretório dele, então o comando imprime a primeira resposta retida ali, e depois cada linha das outras execuções:

```
ana@lab:~/agents$ grep -h held canary/role-audit.jsonl | head -1 | cut -c1-215; cat role-audit.jsonl | cut -c1-215
{"run": "1ab4d49b", "actor": "agent:support", "held": "PINEAPPLE"}
{"run": "010192eb", "actor": "agent:support", "tool": "shop__get_order", "arguments": {"order_id": "M-1047"}, "approved": true, "is_error": false}
{"run": "6f747d07", "actor": "agent:support", "tool": "refunds__refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": false, "reason": "not offered"}
{"run": "b42bc648", "actor": "agent:refunds", "tool": "refunds__refund", "arguments": {"order_id": "M-1047", "cents": "0", "reason": "damaged item arrived"}, "approved": true, "is_error": true}
```

Cada linha nomeia o **ator**, `agent:support` ou `agent:refunds`, e a **execução** a que pertence, para as linhas de uma conversa poderem ser lidas juntas. A resposta retida está lá com o texto, `PINEAPPLE`. O reembolso recusado está lá com os argumentos e o motivo, `not offered`, da execução do dublê. O reembolso aprovado também está lá, do agente de reembolsos e não do de suporte, com `"is_error": true`: o registro de uma pessoa dizendo sim a 0 centavos, que é a linha que alguém revisando este hospedeiro mais ia querer achar.

É a regra do `internal/audit` aplicada a um agente: **uma ação é registrada com o ator que a tomou, e um registro sem ator não é escrito**. Aqui o hospedeiro é o único componente que vê toda decisão, então é ele quem escreve o registro, com as três propriedades que a aula 15 nomeou: inclui recusas, inclui argumentos, e é dado pessoal a ser guardado e apagado como qualquer outro.

Duas coisas que a auditoria da plataforma faz e este arquivo não, e que um agente em produção deveria fazer: ela é **só de acréscimo** (a tabela da plataforma recusa atualizações e exclusões por gatilho, então uma correção é um registro novo), e ela nomeia a **pessoa** por trás do agente quando há uma. Quando o agente de reembolsos reembolsa porque alguém da equipe aprovou, o registro deve levar os dois: o agente que agiu, e quem disse sim.
