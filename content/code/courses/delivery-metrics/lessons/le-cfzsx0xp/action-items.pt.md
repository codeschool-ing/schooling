---
title: Itens de ação, e por que eles não são feitos
version: 1
---

O valor de um postmortem está no que muda depois, e o que muda é decidido pelos seus itens de ação. A falha mais comum dos postmortems não é uma análise ruim; são bons itens de ação que nunca são feitos.

## Como é um bom item de ação

- **Específico.** "Acrescentar uma chave de idempotência a toda nova tentativa no cartão", não "melhorar a confiabilidade dos pagamentos".
- **Com uma pessoa como dona.** Não "o time"; um nome, que pode delegar o trabalho e ainda responde por ele.
- **Com data.** Um prazo, curto o bastante para que as pessoas que estavam no incidente ainda se importem.
- **Poucos.** De três a cinco por postmortem. Doze itens de ação são uma lista que ninguém termina, e ela esconde os dois que importam.
- **Do tipo certo.** Uma mistura dos quatro: **prevenir** a causa, **detectar** mais cedo, **mitigar** mais rápido, **melhorar o processo** que a deixou passar.

## Medindo se eles são feitos

O time de Billing fez quatro postmortems desde junho, um para cada deploy com falha. **Salve o programa abaixo como `actions.py`.** Ele lê os itens de ação do time, na data do postmortem mais recente, e informa o que aconteceu com eles.

```schooling-example
{
  "language": "python",
  "file": "actions.py",
  "parts": [
    {
      "code": "\"\"\"actions.py: which postmortem action items got done, and which are still waiting.\"\"\"\nfrom datetime import date\n\nTODAY = date(2026, 10, 2)\n\n# One row per action item: the incident it came from, what it is, when it was due,\n# and when it was done (None if it is still open).\nACTIONS = [\n    (\"D004\", \"alert on the card payment error rate\", \"2026-07-10\", \"2026-07-22\"),\n    (\"D004\", \"write a runbook for rolling back a release\", \"2026-07-03\", None),\n    (\"D004\", \"deploy smaller releases\", \"2026-07-15\", \"2026-08-03\"),\n    (\"D008\", \"integration test for the statement export\", \"2026-08-07\", \"2026-08-05\"),\n    (\"D008\", \"release to 5% of shops before the rest\", \"2026-08-15\", None),\n    (\"D008\", \"document the month-end load on the card provider\", \"2026-08-01\", None),\n    (\"D027\", \"fix the flaky refund test\", \"2026-09-07\", \"2026-09-04\"),\n    (\"D027\", \"alert when charges per minute double after a deploy\", \"2026-09-14\", None),\n    (\"D047\", \"idempotency key on every card retry\", \"2026-10-09\", None),\n    (\"D047\", \"alert on duplicate charges for the same invoice\", \"2026-10-09\", None),\n]\n\n",
      "note": "**O controle é uma lista**, escrita no programa para o curso: todo item de ação dos quatro postmortems do time de Billing desde junho, com o nome do deploy que falhou. Num time de verdade ele é uma etiqueta na ferramenta de chamados, e o programa leria uma exportação dela."
    },
    {
      "code": "due = [a for a in ACTIONS if date.fromisoformat(a[2]) <= TODAY]\ndone = [a for a in due if a[3] and date.fromisoformat(a[3]) <= TODAY]\nprint(f\"{len(ACTIONS)} action items, {len(due)} already due, {len(done)} of those done\")\nfor incident, what, by, finished in ACTIONS:\n    late = (TODAY - date.fromisoformat(by)).days\n    if not finished and late > 0:\n        print(f\"  {incident}  {late:3} days overdue  {what}\")\n",
      "note": "**Dois números e uma lista.** Quantos itens já venceram e quantos desses estão feitos, e todo item aberto que passou da data, com quanto está atrasado."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 actions.py
10 action items, 8 already due, 4 of those done
  D004   91 days overdue  write a runbook for rolling back a release
  D008   48 days overdue  release to 5% of shops before the rest
  D008   62 days overdue  document the month-end load on the card provider
  D027   18 days overdue  alert when charges per minute double after a deploy
```

**Metade dos itens de ação vencidos foi feita.** A taxa importa menos do que qual metade. Leia os itens abertos à luz do incidente de 30 de setembro:

- **"Release to 5% of shops before the rest"**, de julho. Feito, teria limitado as cobranças em dobro a algumas dezenas de lojas.
- **"Document the month-end load on the card provider"**, de julho. Feito, teria avisado que a tarde do dia 30 era um mau momento para fazer deploy de uma mudança nas cobranças no cartão.
- **"Alert when charges per minute double after a deploy"**, de agosto. Feito, muito provavelmente teria disparado poucos minutos depois das 17:20, em vez da ligação de um cliente às 17:38.

**O incidente de setembro foi agravado por três itens de ação que o time já tinha combinado e não tinha feito.** Esse é o argumento mais forte que existe para acompanhá-los.

## Por que eles não são feitos

- **Eles competem com o trabalho planejado e perdem.** Os itens de ação chegam depois que o plano foi feito, sem lugar nele. A folga da aula 12 é onde eles cabem.
- **Ninguém é dono deles depois que o incidente acaba.** A urgência some em uma semana.
- **Eles são grandes demais.** "Liberar para 5% das lojas primeiro" é um projeto, não uma tarefa, e fica parado porque ninguém consegue começá-lo numa terça à tarde.

## O que faz eles serem feitos

- **Acompanhe-os como qualquer outro trabalho**, no quadro, com uma etiqueta, para que envelheçam onde todo mundo consegue ver, aula 3.
- **Informe a taxa de conclusão**, todo mês, ao lado da contagem de incidentes. É o único número que diz se os postmortems valem o tempo gasto.
- **Divida os grandes.** O primeiro passo de uma liberação canário é uma decisão sobre como direcionar 5% das lojas, o que cabe num dia.
- **Revise os itens abertos a cada novo postmortem**, como esta seção acabou de fazer. Um item vencido que teria evitado o incidente em análise é uma conversa que o time deveria ter, e normalmente ela faz o item ser feito.
