---
title: Os pedidos de dezembro: grandes, e reais
version: 1
---

**Os maiores pedidos do ano não são erros, e a evidência está nas linhas em volta deles.** Os doze
maiores:

```
ana@lab:~/clean$ python -c "from orders import orders as o; print(o.nlargest(12, 'total')[['order_id', 'ordered_at', 'name', 'total', 'status']].to_string(index=False))"
order_id           ordered_at                                 name    total    status
  126473 2025-12-13T15:58:00Z                    Clínica Bem Viver 26928.50 delivered
  126336 2025-12-12T15:28:00Z Escritório Paulista de Contabilidade 12167.00 delivered
  126316 2025-12-12T13:44:00Z Escritório Paulista de Contabilidade 12120.75 delivered
  127072 2025-12-18T17:06:00Z                     Café Aurora Ltda 11832.00 delivered
  126192 2025-12-11T12:29:00Z                    Clínica Bem Viver  8594.00 delivered
  126011 2025-12-09T14:55:00Z                  Studio Trama Design  8488.25 delivered
  126227 2025-12-11T15:47:00Z                   Agência Rota Norte  4859.25 delivered
  126813 2025-12-16T14:52:00Z Escritório Paulista de Contabilidade  4394.75 delivered
  126504 2025-12-13T18:31:00Z                  Colégio Monte Verde  4060.00 delivered
  127204 2025-12-19T18:57:00Z                   Agência Rota Norte  3919.00 delivered
  126024 2025-12-09T17:55:00Z                   Agência Rota Norte  3893.00 delivered
  127172 2025-12-19T14:23:00Z                     Café Aurora Ltda  3770.00 delivered
```

Todos são de dezembro, todos foram entregues, e todo nome é de uma empresa. Todo pedido acima de
R$ 1.000, agrupado por quem o fez:

```
ana@lab:~/clean$ python -c "from orders import orders as o; big = o[o['total'] > 1000]; print(big.groupby('name')['total'].agg(['count', 'min', 'max']).round(2).to_string()); print(big['ordered_at'].str[:10].min(), big['ordered_at'].str[:10].max())"
                                      count      min       max
name                                                          
Agência Rota Norte                        3  3893.00   4859.25
Café Aurora Ltda                          2  3770.00  11832.00
Clínica Bem Viver                         2  8594.00  26928.50
Colégio Monte Verde                       3  1210.00   4060.00
Enzo Simões Santana                       1  1807.00   1807.00
Escritório Paulista de Contabilidade      3  4394.75  12167.00
Luana Lopes                               1  2721.50   2721.50
Marcelo Monteiro                          1  2516.00   2516.00
Murilo Santos                             1  1370.00   1370.00
Studio Trama Design                       3  1664.00   8488.25
Tiago Teixeira Ribeiro                    1  1333.90   1333.90
2025-01-14 2025-12-19
```

Seis dos nomes são empresas — um escritório de contabilidade, uma clínica, um colégio, um café, uma
agência, um estúdio de design — com dois ou três pedidos cada. As cinco linhas restantes são pessoas,
e quatro delas são os totais digitados da seção anterior, já explicados. A quinta, R$ 1.333,90, é um
pedido doméstico de oito cestas e três pacotes de açúcar, ao qual a seção do catálogo volta.

Os pedidos das empresas são todos de dezembro, na quinzena antes do Natal, e os itens têm a cara do
que são:

```
ana@lab:~/clean$ python -c "from lines import lines as l; from orders import orders as o; big = o[(o['total'] > 1000) & o['name'].str.contains('Ltda', na=False)]['order_id'].iloc[0]; print(l[l['order_id'] == big][['code', 'quantity', 'unit', 'unit_price', 'line_cents']].to_string(index=False))"
 code  quantity unit  unit_price  line_cents
00284      60.0   un       119.9      719400
00165      40.0   un        12.9       51600
00675      37.5   kg         8.9       33375
00831      90.0   un        28.9      260100
00502      60.0   un         4.9       29400
00248      30.0   un        11.9       35700
00374      10.0   kg         4.5        4500
00900      20.0   un        16.9       33800
00731       5.0   kg         5.9        2950
00322      12.5   kg         9.9       12375
```

Sessenta cestas, noventa unidades de um produto, trinta e sete quilos e meio de outro: **um
escritório comprando cestas de Natal para a equipe.** Todo item é coerente com o total, o cliente é
uma empresa, e a data combina com o propósito.

Então esses pedidos ficam, sem mudança. O que eles precisam é de um rótulo e não de uma correção,
porque respondem a algumas perguntas e distorcem outras:

- para a **receita**, entram: o dinheiro chegou;
- para o **pedido típico de uma família**, não: os R$ 26.928,50 de uma clínica mexem numa média de
  cestas comuns, e um time de marketing planejando uma campanha para famílias não deveria vê-los;
- para o **crescimento de dezembro**, precisam ser ditos em voz alta: um gerente comparando dezembro
  com novembro deveria saber quanto do salto foram dezesseis pedidos corporativos.

Uma marca como `corporate order` deixa cada relatório escolher, e a aula 12 transforma esse tipo de
rótulo numa coluna. **Apagá-los teria deixado todo relatório errado na mesma direção; mantê-los sem
rótulo deixa alguns relatórios errados sem que ninguém perceba.**
