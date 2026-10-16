---
title: Alertas, e quem eles acordam
version: 1
---

Uma checagem que ninguém ouve é uma linha de log. **Um alerta é uma checagem com uma pessoa na
ponta**, e a parte difícil não é disparar o alerta, e sim decidir quais checagens merecem um.

**Um objetivo de nível de serviço, um SLO, é a promessa que um alerta defende.** Ele é escrito nos
termos das quatro perguntas, com um número e um período:

| pergunta | um objetivo para o serviço de afastamento | medido a partir de |
| --- | --- | --- |
| está respondendo? | 99,9% dos pedidos não respondidos com um 5xx, em 30 dias | `requests.log` |
| quão rápido? | 99% dos pedidos abaixo de 50 ms, na carga de uma tarde normal | `requests.log` |
| o que está dizendo? | o `watch.py` de toda noite sai com 0, ou alguém olhou antes das 9h | a execução noturna |
| acertou? | precisão média da noite mais recente com desfechos a até 0,05 da do teste | `report_card.py` |

Os números são decisões, tomadas com as pessoas que usam as notas, e são o mesmo tipo de julgamento
dos limites dentro do `watch.py`. **Apertados demais, e os alertas disparam com o ruído comum até
todo mundo aprender a ignorá-los; frouxos demais, e a noite em que o gasto chegou cem vezes maior
passa em silêncio.** Comece frouxo o bastante para que todo alerta do primeiro mês tenha valido a
leitura, e aperte a partir do que esses alertas ensinaram.

**Dois tipos de alerta, conforme a urgência de alguém agir.** Uma chamada acorda uma pessoa: o
serviço respondendo erros, ou o p99 muito acima do objetivo, porque os membros sentem isso agora. Um
chamado espera a manhã: um alarme do vigia antes de a lista de cupons sair, um boletim escorregando
para baixo. As decisões do modelo de afastamento são mensais, então quase nada nele merece acordar
alguém; as de um modelo de fraude são por pagamento, e quase tudo merece.

**As checagens noturnas são passos do pipeline.** O agendador que roda o lote roda o vigia depois
dele, e um status de saída diferente de zero para a cadeia antes de qualquer coisa ser publicada e
avisa quem o agendador avisa. Numa máquina só, o cron basta para mostrar o formato, uma linha no
`crontab -e`:

```conf
# every night at 02:30: tonight's snapshot, the scores, then the watch; the chain stops at a failure
30 2 * * * cd ~/ml && . ~/mlenv/bin/activate && night=$(date +\%F) && { python featurestore.py snapshot $night && python score_batch.py $night && python watch.py $night; } >> nightly.log 2>&1
```

O `\%F` tem barra porque o cron trata um `%` solto como quebra de linha. Na plataforma da Ponto
Final, os mesmos três passos seriam tarefas numa DAG do Airflow como as do curso de pipelines, com as
suas novas tentativas e as suas notificações; o curso não pede que você instale a linha do cron, que
só mostra onde as checagens ficam. **O que importa é a ordem: o vigia roda entre as notas serem
gravadas e alguém lê-las**, e uma noite de que ele não gosta é uma noite em que ninguém age até uma
pessoa ter olhado.
