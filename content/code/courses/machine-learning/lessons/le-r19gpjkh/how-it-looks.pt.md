---
title: Como um vazamento aparece nos números
version: 1
---

Um vazamento tem sintomas, e nenhum deles é prova. São motivos para parar e perguntar de onde vem
uma coluna, que é a única prova que existe.

**Uma nota melhor do que o problema permite.** O teto da aula 2 e o passeio da aula 3 dão uma ideia
do que estes dados conseguem: uma AUC em torno de 0,8, um valor líquido em torno de R$ 900 por mil
linhas. Um modelo com 0,958, ou com 1,0, num problema sobre quem vai cancelar uma caixa de verduras,
tem muito mais chance de estar vazando do que de ser brilhante. Comportamento humano é ruidoso, e um
modelo que diz o contrário achou algo que não é comportamento.

**Uma coluna fazendo quase todo o trabalho.** Quando tirar uma única coluna move a nota muito mais do
que tirar qualquer outra, essa coluna merece uma entrevista. A aula 19 mede quanto cada coluna
contribui; a versão grosseira é ordenar as linhas por cada coluna sozinha e ver quantas pessoas que
saíram caem no extremo. Salve isto como `suspects.py`:

```python
# suspects.py
import pandas as pd

churn = pd.read_csv("data/churn.csv")
columns = churn.select_dtypes("number").columns.drop("churned")
print(f"leavers among all rows: {churn['churned'].mean():.1%}")
print("leavers among the 10% of rows with the most extreme value of one column:")
rows = []
for col in columns:
    known = churn.dropna(subset=[col])
    k = len(known) // 10
    high = known.nlargest(k, col)["churned"].mean()
    low = known.nsmallest(k, col)["churned"].mean()
    rows.append((col, max(high, low), "highest" if high >= low else "lowest"))
for col, share, end in sorted(rows, key=lambda r: -r[1]):
    print(f"  {col:22} {share:6.1%}  ({end} values)")
```

```
ana@lab:~/ml$ python suspects.py
leavers among all rows: 5.9%
leavers among the 10% of rows with the most extreme value of one column:
  days_since_last_order   26.1%  (highest values)
  rating_90d              25.1%  (lowest values)
  skips_90d               13.9%  (highest values)
  days_since_login        12.6%  (highest values)
  late_90d                12.5%  (highest values)
  complaints_90d          12.0%  (highest values)
  support_calls_90d       10.1%  (highest values)
  orders_90d               8.0%  (lowest values)
  tenure_months            7.9%  (lowest values)
  price_month              7.5%  (highest values)
  age                      7.0%  (lowest values)
  app_user                 6.8%  (highest values)
```

O vazamento vem em primeiro, e isso é útil; mas vem em primeiro por **um ponto**, à frente de
`rating_90d`, que é uma coluna perfeitamente legítima. Uma conferência assim acha um vazamento
escancarado, e a `cancel_reason`, se fosse um número, estaria no topo com todo mundo que saiu dentro.
Um vazamento sutil é sutil exatamente porque parece uma boa variável. **Nenhuma conferência só nos
números conseguiria separar estas duas**, e a próxima seção é o que separa.

**Uma nota que cai em dados mais novos.** A divisão por tempo e, depois dela, a produção. Um modelo
que vai claramente pior nos meses posteriores do que nos meses em que foi validado ou está
encontrando um mundo mudado, que é o assunto da aula 22, ou está encontrando a ausência de algo em
que se apoiava.

**Uma relação que muda com a data.** A tabela do `subtle.py` é o sintoma mais específico que existe:
uma coluna cujo significado para o alvo muda sem parar com a data do retrato muitas vezes é medida a
partir de um ponto fixo no tempo, a exportação, e não do momento da própria linha.
