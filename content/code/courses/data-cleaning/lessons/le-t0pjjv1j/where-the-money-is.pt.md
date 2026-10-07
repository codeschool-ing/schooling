---
title: Onde está o dinheiro
version: 1
---

Decompor um total por categoria é a pergunta mais comum que uma empresa faz aos seus dados. Ela
precisa das categorias da aula 8, da junção verificada da aula 11 e dos valores dos itens que a aula
7 converteu, e é por isso que aparece tão tarde:

```
ana@lab:~/clean$ python -c "from explore import sold; r = sold.groupby('category', dropna=False)['line_cents'].sum() / 100; print(r.sort_values(ascending=False).to_string()); print(round(r.sum(), 2))"
category
Cestas               861595.30
Mercearia            421614.40
Frutas               290519.50
Legumes              219490.20
Verduras             188922.10
Ovos e laticínios    186290.80
Grãos e cereais      137732.50
NaN                   37761.35
2343926.15
```

Os itens dos pedidos entregues somam R$ 2.343.926,15. É menos que os totais dos pedidos, porque um
item não tem frete nem desconto, e **uma decomposição precisa dizer qual das duas coisas ela soma**.
Uma fração da "receita" calculada sobre itens e comparada com um total calculado sobre pedidos nunca
fecharia em 100%.

O ranking diz que as cestas, as caixas prontas, trazem mais de um terço de tudo, R$ 861.595,30, e a
Mercearia vem em segundo. As duas merecem um segundo olhar antes de alguém agir em cima delas:

- **A Mercearia inclui o açúcar.** A partir de julho todo pacote foi cobrado a R$ 134,90 em vez de
  R$ 12,90, e a aula 9 calculou o excesso em R$ 115.412,00 somando todos os pedidos. Um ranking de
  categorias feito em cima disso daria à prateleira da mercearia um dinheiro que os clientes não
  deveriam ter pago.
- **A última linha não tem categoria**, R$ 37.761,35. São os itens dos dois códigos que o catálogo
  não tem, achados nas aulas 7 e 11. Eles ficam como uma linha própria em vez de serem descartados
  ou espalhados pelas outras, porque **uma decomposição que perde 1,6% do dinheiro em silêncio deixa
  de somar o total que diz decompor**.

Os dois cuidados são a mesma ideia: uma decomposição só é tão boa quanto a limpeza por trás de cada
linha, e as linhas que mais impressionam são as primeiras a conferir.
