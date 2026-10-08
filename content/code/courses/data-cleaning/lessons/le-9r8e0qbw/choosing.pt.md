---
title: Escolher, e fazer em SQL
version: 1
---

**A escolha decorre de duas coisas: por que o valor falta, e para que a coluna vai ser usada.** O
registro da aula 3 responde à primeira; a pergunta feita responde à segunda.

| o vazio é | para uma contagem ou soma | para uma média | para uma linha individual |
|---|---|---|---|
| um valor conhecido (desconto do site) | preencher a constante | preencher a constante | preencher a constante |
| não se aplica (retiradas) | deixar, excluir as linhas | deixar, excluir as linhas | deixar |
| MCAR | descartar, e dizer quantas sobram | descartar, ou preencher o centro | deixar vazio |
| MAR | preencher dentro dos grupos | preencher dentro dos grupos | deixar vazio |
| MNAR com limite conhecido (o cronômetro) | sinalizar, usar o limite | sinalizar, informar um piso | sinalizar |
| MNAR sem limite (a pesquisa) | informar a taxa ao lado | informar a taxa ao lado | deixar vazio |

A última coluna é igual em todas as linhas menos uma, e de propósito. **Um valor chutado preso a uma
pessoa real — a idade, a nota, a entrega dela — é uma fabricação**, por melhor que seja o método.
Imputação serve a resumos.

## As decisões, numa view

No banco, Ana escreve as decisões dos pedidos como uma view sobre a tabela bruta, para que toda
consulta leia a versão decidida e as linhas brutas fiquem intactas:

```schooling-example
{
  "language": "sql",
  "file": "fill.sql",
  "parts": [
    {
      "code": "CREATE OR REPLACE VIEW orders_filled AS\nSELECT order_id,\n",
      "note": "**Uma view, não uma tabela.** As decisões se aplicam toda vez que ela é lida, e as linhas brutas embaixo nunca mudam."
    },
    {
      "code": "       COALESCE(discount, '0')                        AS discount,\n",
      "note": "O desconto vazio do site vira o zero que ele quer dizer."
    },
    {
      "code": "       delivery_minutes,\n",
      "note": "O tempo em si fica exatamente como foi registrado, vazios inclusive."
    },
    {
      "code": "       CASE WHEN fulfilment = 'pickup'    THEN 'no delivery'\n            WHEN status = 'cancelled'     THEN 'no delivery'\n            WHEN courier = 'Rapidex'      THEN 'not reported'\n            WHEN delivery_minutes IS NULL THEN 'over 120'\n            ELSE 'recorded' END                       AS timing\n",
      "note": "**O motivo de cada vazio, numa coluna própria.** A ordem dos `WHEN` importa: um pedido cancelado da Rapidex é `no delivery`, não `not reported`, porque vale o primeiro que casa."
    },
    {
      "code": "FROM (SELECT DISTINCT * FROM raw.orders) o;\n",
      "note": "`DISTINCT` tira os 25 pedidos repetidos que a aula 1 achou."
    }
  ]
}
```

```
ana@lab:~/clean$ psql -f fill.sql
CREATE VIEW
ana@lab:~/clean$ psql -c 'SELECT timing, count(*) FROM orders_filled GROUP BY timing ORDER BY count(*) DESC'
    timing    | count 
--------------+-------
 recorded     | 14858
 not reported |  6620
 no delivery  |  6592
 over 120     |   456
(4 rows)
```

Todo vazio da frota própria agora é `over 120`, todo vazio da Rapidex `not reported`, toda retirada
e todo cancelado `no delivery`. **Nenhum tempo de entrega foi inventado**; cada vazio carrega o seu
motivo. Um relatório de atrasos conta as linhas `recorded` de 90 minutos ou mais e mais todo
`over 120`, e chega à resposta certa.

E o registro de ausências da aula 3 ganha a última coluna — o que foi feito:

| coluna | mecanismo | feito |
|---|---|---|
| `discount`, site | não falta | `COALESCE` para `0` |
| `delivery_minutes`, frota própria | MNAR, limite 120 | sinalizado `over 120` |
| `delivery_minutes`, Rapidex e retiradas | não informado, não se aplica | sinalizado |
| `birth_year` 1900 e de dois dígitos | marcador, inválido | esvaziado; resumos só sobre anos conhecidos |
| `nps` | MNAR, sem limite | deixado vazio; taxa de resposta informada com a nota |
