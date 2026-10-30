---
title: Tabelas intercaladas, um pedido guardado com o cliente
version: 1
---

**Uma tabela intercalada guarda cada linha filha ao lado da linha pai, na parte do pai da faixa de
chaves.** `Orders` é declarada `INTERLEAVE IN PARENT Customers`, então os pedidos de `c-17` ficam
guardados fisicamente depois da linha de `c-17`, ordenados pela própria chave, antes de começar o
próximo cliente. Uma leitura de um cliente com todos os pedidos é então uma sequência contígua de
linhas, num split, num servidor. Num banco espalhado por muitas máquinas, essa é a diferença entre um
join que lê um lugar e um join que pergunta a vários.

**A ideia errada é que intercalar é uma chave estrangeira.** Ela impõe o que uma chave estrangeira
impõe, e mais, mas o que ela faz é posicionar. Uma chave estrangeira de `sql-databases` diz que uma
linha precisa se referir a um pai que existe; não diz nada sobre onde cada um fica, porque num servidor
tudo fica num lugar. Intercalar é uma afirmação sobre a faixa de chaves, e o Spanner só consegue
cumpri-la porque a chave da filha começa com a do pai.

## A chave tem de começar com a chave do pai

**A chave primária de uma filha repete a chave do pai como primeiras colunas**, e é essa regra que
torna o posicionamento possível. `Orders` tem chave `(CustomerId, OrderId)`, que começa com o
`(CustomerId)` de `Customers`. Uma tabela que tenta se intercalar sem isso é recusada quando o schema
muda:

```
ana@laptop:~/gcp$ gcloud spanner databases ddl update shop --instance=quitanda --ddl='CREATE TABLE OrderNotes (OrderId INT64 NOT NULL, Note STRING(MAX)) PRIMARY KEY (OrderId), INTERLEAVE IN PARENT Customers'
ERROR: (gcloud.spanner.databases.ddl.update) HTTPError 400: {"code":9,"message":"Table OrderNotes does not reference parent key column CustomerId."}
```

**A recusa diz qual coluna ela queria.** Uma nota por pedido seria intercalada em `Orders`, com chave
`(CustomerId, OrderId, NoteId)`: três níveis, cada um começando com o de cima, e toda linha dos três
guardada junto, debaixo do cliente.

## Um cliente, lido num lugar

Um segundo cliente com dois pedidos, gravados pela linha de comando. `OrderId` fica de fora, então o
`DEFAULT` dele pega o próximo valor da sequência bit-reversed:

```
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Customers --data=CustomerId=c-18,Name=Bruno,District=Mooca
commitTimestamp: '2026-10-30T18:46:57.337764Z'
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Orders --data=CustomerId=c-18,Day=2026-10-29,TotalCents=4590
commitTimestamp: '2026-10-30T18:46:58.063079Z'
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Orders --data=CustomerId=c-18,Day=2026-10-30,TotalCents=1380
commitTimestamp: '2026-10-30T18:46:58.790722Z'
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql="SELECT c.Name, o.OrderId, o.Day, o.TotalCents FROM Customers c JOIN Orders o ON o.CustomerId = c.CustomerId WHERE c.CustomerId = 'c-18'"
Name   OrderId              Day         TotalCents
Bruno  3161526938414088192  2026-10-30  1380
Bruno  5467369947627782144  2026-10-29  4590
```

**O join lê a parte da faixa de chaves de um cliente**, `c-18` e os pedidos guardados depois dele.
Numa instância real isso é um split e um servidor; o emulador devolve as mesmas linhas do seu único
processo, e não consegue mostrar a diferença em de onde elas foram lidas.

## Um índice é uma tabela com chave própria

**Um índice secundário é uma segunda tabela que o Spanner mantém ordenada pela chave do índice**,
atualizada na mesma transação que toda escrita na tabela. Os analistas querem pedidos por dia, o que a
chave de `Orders`, que começa pelo cliente, não consegue dar, então o dia ganha um índice, e `STORING`
copia o total para dentro dele para que a consulta nunca precise voltar à tabela:

```
ana@laptop:~/gcp$ gcloud spanner databases ddl update shop --instance=quitanda --ddl='CREATE INDEX OrdersByDay ON Orders(Day) STORING (TotalCents)'
Schema updating...
.....done.
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql="SELECT Day, CustomerId, TotalCents FROM Orders@{FORCE_INDEX=OrdersByDay} WHERE Day = '2026-10-29'"
Day         CustomerId  TotalCents
2026-10-29  c-18        4590
```

**`@{FORCE_INDEX=OrdersByDay}` nomeia o índice a ler**, que é como uma consulta o declara em vez de
deixar a escolha ao planejador; `CustomerId` e `OrderId` vêm com toda entrada do índice, porque são a
chave da linha para a qual ela aponta. E este índice é o problema da seção anterior de novo: a chave
dele começa com `Day`, então todo pedido gravado hoje cai no fim da faixa de chaves do índice, num
split. **Um índice também pode ser intercalado**, quando começa com a chave do pai:

```
ana@laptop:~/gcp$ gcloud spanner databases ddl update shop --instance=quitanda --ddl='CREATE INDEX OrdersByCustomerDay ON Orders(CustomerId, Day), INTERLEAVE IN Customers'
Schema updating...
.....done.
```

**`OrdersByCustomerDay` fica guardado dentro da parte de cada cliente da faixa de chaves**, ao lado dos
pedidos que indexa, então "os pedidos da Ana em outubro" é um lugar só para ler, e os pedidos novos se
espalham com os clientes. Ele responde a uma pergunta diferente da de `OrdersByDay`, e essa é a troca:
um índice que espalha as escritas é um índice pelo cliente primeiro, e "todo pedido de um dia" vira
então uma consulta que pergunta à parte de todo cliente.

## O que a regra do pai recusa, e o que ela apaga

**Uma linha filha não pode existir sem o pai.** Um pedido para um cliente que ninguém criou é recusado,
com uma frase que nomeia as duas tabelas; o programa da próxima seção encontra isso dentro de uma
transação. E `ON DELETE CASCADE`, no schema, decide o que acontece com os filhos quando o pai sai:

```
ana@laptop:~/gcp$ gcloud spanner rows delete --instance=quitanda --database=shop --table=Customers --keys=c-18
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql="SELECT COUNT(*) AS orders FROM Orders WHERE CustomerId = 'c-18'"
orders
0
```

**Apagar `c-18` apagou os dois pedidos na mesma escrita.** Sem `ON DELETE CASCADE` o delete seria
recusado enquanto o cliente tivesse pedidos, que é a outra escolha e às vezes a mais segura: uma tabela
de pedidos é um registro de vendas, e os contadores da Quitanda prefeririam que o delete de um cliente
falhasse a que levasse as vendas junto.

## Quando não intercalar

**Intercale o que é lido junto, e só isso.** Os pedidos de um cliente são lidos com o cliente em toda
visita ao app, então eles pertencem juntos. O estoque de um produto não tem nada a ver com cliente
nenhum, e `Stock` é uma tabela própria. E um pai com um número enorme de filhos é um sinal de alerta:
todo filho de um pai fica na parte desse pai da faixa de chaves, então um pai que recebe a maior parte
das escritas é um hotspot por outro caminho, o mesmo que um contador criou na seção anterior.
