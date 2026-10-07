---
title: Primeiro olhar, e um número que ninguém deveria publicar
version: 1
---

**Antes de qualquer limpeza, descubra o que você recebeu.** Não o que os arquivos deveriam
conter: o que há neles, de que tamanho são e qual sistema escreveu cada um. Ana começa pelo
diretório:

```
ana@lab:~/clean$ ls -l raw
total 6908
-r--r--r-- 1 ana ana  244696 Oct  6 23:50 customers.csv
-r--r--r-- 1 ana ana     286 Oct  6 23:50 fx_rates_2025.csv
-r--r--r-- 1 ana ana    3659 Oct  6 23:50 invoices.csv
-r--r--r-- 1 ana ana 2488556 Oct  6 23:50 order_items.csv
-r--r--r-- 1 ana ana 2405696 Oct  6 23:50 orders.csv
-r--r--r-- 1 ana ana    2790 Oct  6 23:50 products.csv
-r--r--r-- 1 ana ana 1270312 Oct  6 23:50 store_sales.csv
-r--r--r-- 1 ana ana  638586 Oct  6 23:50 survey.csv
-r--r--r-- 1 ana ana     630 Oct  6 23:50 targets_2025.csv
ana@lab:~/clean$ wc -l raw/*.csv
   2414 raw/customers.csv
     13 raw/fx_rates_2025.csv
     61 raw/invoices.csv
  99162 raw/order_items.csv
  28552 raw/orders.csv
     73 raw/products.csv
  23595 raw/store_sales.csv
  26495 raw/survey.csv
      7 raw/targets_2025.csv
 180372 total
```

Nove arquivos e cerca de 180 mil linhas. Cada um vem de um lugar diferente, e o lugar é o que
prevê os seus defeitos:

| arquivo | escrito por | uma linha é |
|---|---|---|
| `customers.csv` | o CRM, exportado no seu próprio calendário | uma conta de cliente |
| `orders.csv` | o site e o aplicativo | um pedido online |
| `order_items.csv` | o site e o aplicativo | um produto num pedido |
| `products.csv` | o catálogo, mantido pelos compradores | um produto e seu preço |
| `store_sales.csv` | o caixa antigo das cinco lojas | uma venda no balcão |
| `survey.csv` | a pesquisa de satisfação | um convite, respondido ou não |
| `invoices.csv` | o contas a pagar | a nota de um fornecedor |
| `fx_rates_2025.csv` | o financeiro | o câmbio lançado para um mês |
| `targets_2025.csv` | a planilha do time comercial | as metas do ano de uma loja |

**`wc -l` conta linhas, não registros**, e a diferença é no mínimo uma linha de cabeçalho por
arquivo. Um campo com quebra de linha dentro de aspas aumentaria a diferença; estes arquivos não
têm nenhum, coisa que a aula 2 verifica em vez de supor.

## As primeiras linhas

```
ana@lab:~/clean$ head -4 raw/orders.csv
order_id,customer_id,channel,ordered_at,fulfilment,total,discount,delivery_fee,payment,status,courier,delivery_minutes
100001,C00820,app,2025-01-01 07:00:30,delivery,66.60,0,9.90,card,delivered,Rapidex,
100002,C00223,app,2025-01-01 08:07:08,pickup,46.70,0,0.00,card,delivered,,
100003,C00333,site,2025-01-01T11:24:01Z,delivery,108.30,,9.90,pix,delivered,Rapidex,
```

Três linhas bastam para ver a forma do trabalho. O aplicativo escreve `2025-01-01 07:00:30` e o
site escreve `2025-01-01T11:24:01Z` na mesma coluna — dois formatos, e o `Z` diz que o segundo está
em UTC e o primeiro não. O aplicativo escreve um desconto `0` e o site deixa vazio. O pedido
retirado na loja não tem entregador, o que está certo, nem tempo de entrega, o que também está
certo; os pedidos da Rapidex têm entregador e não têm tempo de entrega, o que é outra coisa
completamente. As aulas 3 e 7 voltam a tudo isso.

## O número

O diretor comercial quer um número: a receita dos pedidos online entregues em 2025. O banco o
entrega sem reclamar:

```
ana@lab:~/clean$ psql -c "SELECT count(*) AS orders, sum(total::numeric) AS revenue FROM raw.orders WHERE status = 'delivered'"
 orders |  revenue   
--------+------------
  26533 | 2502874.70
(1 row)
```

R$ 2.502.874,70 de 26.533 pedidos. A consulta é SQL correto e rodou. **E não dá para defendê-la**,
por motivos que esta aula mede um de cada vez:

- alguns números de pedido aparecem duas vezes no arquivo, então alguns pedidos contam duas vezes;
- alguns totais foram digitados à mão, e um total digitado pode estar errado e continuar sendo um
  número;
- as lojas também venderam comida, num arquivo de outro formato, e a consulta nunca o leu;
- alguns pedidos pertencem a clientes que o arquivo de clientes não contém, então qualquer recorte
  por cliente vai perdê-los.

Nada disso levanta erro. **É isso que faz da qualidade de dados uma disciplina e não uma sessão de
depuração**: os defeitos que importam são os que produzem um número plausível.
