---
title: Uma noite que quebrou sem erro
version: 1
---

O vigia se paga na noite em que algo dá errado lá atrás e nada falha. **Faça uma de propósito.** O
engano de unidade mais comum em cargas de dados é converter um valor que já tinha sido convertido: o
`spend_180d` está em centavos, e uma carga que o multiplica por cem de novo deixa um número
perfeitamente válido em cada linha. Quebre a fotografia desta noite desse jeito e rode a noite de
novo:

```
ana@dev:~/ml$ sqlite3 features.db "UPDATE offline SET spend_180d = spend_180d * 100 WHERE as_of = '2026-02-28'"
ana@dev:~/ml$ python score_batch.py 2026-02-28
3355 members scored as of 2026-02-28 by lapse version 1; 16603 rows in lapse_scores
ana@dev:~/ml$ python watch.py 2026-02-28; echo "exit status $?"
ok    members scored         before  3312.000   tonight  3355.000
ALARM mean p_lapse           before     0.174   tonight     0.001
ALARM share over 0.2         before     0.241   tonight     0.000
ok    tenure_days median     before   430.000   tonight   437.000
ok    recency_days median    before    20.000   tonight    20.000
ok    visits_180d median     before     6.000   tonight     5.000
ALARM spend_180d median      before 52910.000   tonight 5191000.000
ok    basket_avg median      before  9485.000   tonight  9486.000
ok    online_share median    before     0.250   tonight     0.231
ok    shops_180d median      before     2.000   tonight     2.000
3 alarm(s) for 2026-02-28
exit status 1
```

**O lote relatou sucesso.** Pontuou 3.355 membros, como na noite anterior, e os gravou na tabela que o
marketing lê. Nada levantou erro, porque nada estava malformado: cada valor era um número, na coluna
certa, do tipo certo.

**O vigia não.** A mediana de `spend_180d` saltou cem vezes, e o modelo, vendo cada membro gastar cem
vezes mais do que qualquer um com quem treinou, decidiu que ninguém se afastaria: probabilidade média
de 0,001 e ninguém acima de 0,2. A lista do mês do marketing teria saído vazia, ou pior, montada com
quem ficasse no topo de uma coluna de quase zeros. Status de saída 1, três alarmes, e o da entrada
nomeia a causa.

O conserto é da própria feature store: refazer a fotografia desta noite a partir da loja, que a lição
6 tornou um passo que pode rodar de novo, e então pontuar a noite outra vez, que a lição 8 também
tornou um passo que pode rodar de novo:

```
ana@dev:~/ml$ python featurestore.py snapshot 2026-02-28 && python score_batch.py 2026-02-28
2026-02-28: 3355 members
3355 members scored as of 2026-02-28 by lapse version 1; 16603 rows in lapse_scores
ana@dev:~/ml$ python watch.py 2026-02-28; echo "exit status $?"
ok    members scored         before  3312.000   tonight  3355.000
ok    mean p_lapse           before     0.174   tonight     0.174
ok    share over 0.2         before     0.241   tonight     0.243
ok    tenure_days median     before   430.000   tonight   437.000
ok    recency_days median    before    20.000   tonight    20.000
ok    visits_180d median     before     6.000   tonight     5.000
ok    spend_180d median      before 52910.000   tonight 51910.000
ok    basket_avg median      before  9485.000   tonight  9486.000
ok    online_share median    before     0.250   tonight     0.231
ok    shops_180d median      before     2.000   tonight     2.000
exit status 0
```

De volta aos números da primeira execução. **Duas propriedades construídas antes fizeram do conserto
uma linha**: a fotografia pode ser refeita para um único dia, e o lote substitui uma noite em vez de
somar a ela. Um pipeline sem elas precisaria de alguém apagando linhas à mão de madrugada, sob
pressão, que é como uma carga ruim vira duas.
