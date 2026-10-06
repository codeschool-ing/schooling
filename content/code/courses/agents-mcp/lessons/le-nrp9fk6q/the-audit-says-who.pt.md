---
title: A auditoria diz quem
version: 1
---

Toda decisão nas execuções desta aula escreveu uma linha, as do teste do sinal no diretório dele:

```
ana@lab:~/agents$ cat canary/role-audit.jsonl role-audit.jsonl | cut -c1-215
{"run": "9b187743", "actor": "agent:support", "resource": "help://t01", "approved": true}
{"run": "9b187743", "actor": "agent:support", "held": "Gift wrapping costs 3.00 per book. PINEAPPLE"}
{"run": "78579500", "actor": "agent:support", "tool": "refunds__refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": false, "reason": "not offered"}
{"run": "1da19d33", "actor": "agent:refunds", "tool": "refunds__refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": true, "is_error": false}
```

Cada linha nomeia o **ator**, `agent:support` ou `agent:refunds`, e a **execução** a que pertence, para as linhas de uma conversa poderem ser lidas juntas. A resposta retida está lá com o texto. O reembolso recusado está lá com os argumentos e o motivo, `not offered`. O reembolso aprovado também está lá, e é do agente de reembolsos, não do de suporte.

É a regra do `internal/audit` aplicada a um agente: **uma ação é registrada com o ator que a tomou, e um registro sem ator não é escrito**. Aqui o hospedeiro é o único componente que vê toda decisão, então é ele quem escreve o registro, com as três propriedades que a aula 15 nomeou: inclui recusas, inclui argumentos, e é dado pessoal a ser guardado e apagado como qualquer outro.

Duas coisas que a auditoria da plataforma faz e este arquivo não, e que um agente em produção deveria fazer: ela é **só de acréscimo** (a tabela da plataforma recusa atualizações e exclusões por gatilho, então uma correção é um registro novo), e ela nomeia a **pessoa** por trás do agente quando há uma. Quando o agente de reembolsos reembolsa porque alguém da equipe aprovou, o registro deve levar os dois: o agente que agiu, e quem disse sim.
