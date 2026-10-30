---
title: Só a última versão, e a exclusão que é uma atualização
version: 1
---

**O modo padrão do feed se chama última versão, e o nome é exato: ele mostra cada item como está agora,
uma vez.** O `o-1` foi gravado três vezes e apareceu uma, como `delivered`. Um leitor que quisesse saber
quando ele foi embalado não tem como descobrir, porque o feed não é um log de toda escrita; são os itens
do contêiner, ordenados pela última vez em que mudaram. Duas coisas vêm daí, e todo projeto em cima do
feed tem de aceitá-las.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 252\" role=\"img\" aria-label=\"Seis escritas em ordem, lsn 1 a 6: o-1 paid, o-2 paid, o-3 paid, o-1 packed, o-1 delivered, e o-2 apagado. O feed de última versão mostra duas entradas: o-3 paid no lsn 3 e o-1 delivered no lsn 5; os dois estados anteriores de o-1 e tudo sobre o-2 ficam de fora. O feed de todas as versões e exclusões mostra as seis, inclusive a exclusão.\" data-fig=\"l14-modes\"><text x=\"220\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 1</text><text x=\"302\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 2</text><text x=\"384\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 3</text><text x=\"466\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 4</text><text x=\"548\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 5</text><text x=\"630\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lsn 6</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">gravado, em ordem</text><rect x=\"184\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"220\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"220\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">paid</text><rect x=\"266\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"302\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-2</text><text x=\"302\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">paid</text><rect x=\"348\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"384\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-3</text><text x=\"384\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">paid</text><rect x=\"430\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"466\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"466\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">packed</text><rect x=\"512\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"548\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"548\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">delivered</text><rect x=\"594\" y=\"42\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"/><text x=\"630\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-2</text><text x=\"630\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">delete</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">última versão</text><rect x=\"184\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"/><rect x=\"266\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"/><rect x=\"348\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"384\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-3</text><text x=\"384\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">paid</text><rect x=\"430\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"/><rect x=\"512\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"548\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"548\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">delivered</text><rect x=\"594\" y=\"104\" width=\"72\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"/><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">todas as versões e exclusões</text><rect x=\"184\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"220\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"220\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">paid</text><rect x=\"266\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"302\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-2</text><text x=\"302\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">paid</text><rect x=\"348\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"384\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-3</text><text x=\"384\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">paid</text><rect x=\"430\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"466\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"466\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">packed</text><rect x=\"512\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"548\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-1</text><text x=\"548\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">delivered</text><rect x=\"594\" y=\"166\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"630\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">o-2</text><text x=\"630\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">delete</text><text x=\"370\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A última versão guarda uma entrada por item vivo; o outro modo guarda cada passo, pelo período de retenção.</text></svg>", "caption": "As seis escritas que o feed.py fez, e o que cada modo do feed devolve para elas. As duas primeiras linhas são o que o feed.py imprimiu."}
```

**Estados intermediários podem se perder.** Um leitor que consulta a cada minuto vê um pedido que foi
pago, embalado e entregue dentro daquele minuto como entregue. Nada do que o item ainda diz se perde, e
tudo o que ele não diz mais some. Se os passos importam, eles pertencem ao item, uma lista de mudanças de
status com os horários, ou ao outro modo, duas seções adiante.

**Exclusões não estão no feed de jeito nenhum.** O `o-2` foi criado e apagado, e nenhuma entrada diz
isso. Uma visão construída a partir do feed guarda um pedido apagado para sempre, porque nada mandou a
visão removê-lo. A resposta comum é apagar em dois passos: **primeiro uma atualização que marca o item
como apagado**, que o feed carrega como qualquer outra mudança, **e um time to live que remove o item
depois**, quando todo leitor já teve tempo de ver a marca.

O `feed.py` criou o contêiner com `default_ttl=-1`, que liga o time to live no contêiner sem dar um a
item nenhum; um item então só expira se trouxer o próprio `ttl`, em segundos. Salve isto como
`softdelete.py`. Ele marca `o-3` como cancelado e apagado com um `ttl` de 5, lê o feed a partir de onde
ele estava, e confere oito segundos depois:

`softdelete.py`:

```python
import time

from azure.cosmos import CosmosClient, exceptions

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
orders = CosmosClient("http://localhost:8081", KEY).get_database_client("quitanda").get_container_client("orders")

list(orders.query_items_change_feed(start_time="Beginning"))
token = orders.client_connection.last_response_headers["etag"]

order = orders.read_item("o-3", partition_key="c-7")
order.update({"status": "cancelled", "deleted": True, "ttl": 5})
orders.upsert_item(order)
for change in orders.query_items_change_feed(continuation=token):
    print("the feed shows:", change["id"], change["status"], "deleted =", change["deleted"], "ttl =", change["ttl"])

time.sleep(8)
try:
    orders.read_item("o-3", partition_key="c-7")
except exceptions.CosmosResourceNotFoundError:
    print("eight seconds later o-3 is gone, removed by its time to live")
```

```
ana@laptop:~/azure$ python softdelete.py
the feed shows: o-3 cancelled deleted = True ttl = 5
eight seconds later o-3 is gone, removed by its time to live
```

**O feed levou a marca, e o time to live fez a exclusão.** Um leitor do feed viu `o-3` com
`deleted = True` e pôde tirá-lo de qualquer coisa que construa; oito segundos depois o item tinha
sumido do contêiner, e com ele do feed. O emulador aplicou o time to live. No Azure a exclusão é feita
em segundo plano, com unidades de requisição que o contêiner não está usando para mais nada.

**O `ttl` é uma promessa aos leitores, e tem de ser mais longo que o mais lento deles.** Cinco segundos
é um número para uma lição. Um processador que roda toda noite precisa de um dia no mínimo, e um que pode
ficar parado num fim de semana precisa do fim de semana. Se o item expira antes de um leitor ver a
marca, esse leitor nunca fica sabendo da exclusão, que é o problema que a marca devia resolver.
