---
title: O script: todo passo, toda vez
version: 1
---

O `nightly.sh` da Ana, da lição 7, é a versão imperativa, e uma boa do seu tipo:

```
#!/bin/sh
# One night: copy the shop into raw, rebuild staging, then load the marts.
set -e
day=${1:?usage: nightly.sh YYYY-MM-DD}
export PGOPTIONS="-c client_min_messages=warning"
python load_raw.py >/dev/null
sh run_sql.sh >/dev/null
psql -q -v ON_ERROR_STOP=1 -d wh -f load/dim_customer.sql
psql -q -v ON_ERROR_STOP=1 -d wh -At -f load/dim_book.sql | sort | uniq -c | sed 's/t$/inserted/; s/f$/updated/'
psql -q -v ON_ERROR_STOP=1 -d wh -v day="$day" -f load/fact_sales.sql
psql -d wh -At -c "SELECT '$day: ' || count(*) || ' fact rows' FROM marts.fact_sales WHERE order_date = '$day'"
```

Ele é curto, lê-se de cima a baixo, e o `set -e` o para no primeiro comando que falhar. Qualquer um
consegue dizer o que ele faz. O que ele não consegue fazer vem da mesma simplicidade:

- **Rode duas vezes e ele faz tudo duas vezes.** Nada nele pergunta se o raw já está carregado ou se
  a tabela fato já tem o dia. Aqui isso é só tempo perdido, porque cada passo foi escrito para poder
  repetir; um script cujos passos não fossem assim dobraria as vendas de um dia.
- **Quando um passo falha, a próxima execução começa do topo.** O script não faz ideia de quais
  passos terminaram da última vez; nunca lhe disseram como seria *terminado*.
- **A ordem é a de quem escreveu.** O `dim_customer` antes do `dim_book` porque essa é a ordem das
  linhas, embora nenhum dos dois precise do outro. Mude as entradas de um passo, e o script não vai
  perceber que a ordem agora está errada.

Nada disso é defeito enquanto um pipeline tem quatro passos e roda uma vez por noite. Vira defeito
quando os passos levam uma hora, ou são quarenta, ou uma falha no passo trinta manda a noite inteira de
volta ao passo um.
