---
title: Um cliente construído a partir do WSDL
version: 1
---

Escrever envelopes à mão é como você descobre o que vai pelo fio. Escrevê-los à mão **dentro de um
programa** é como você erra o namespace justo na mensagem que ninguém testou. Toda linguagem tem um
toolkit de SOAP que lê o WSDL e constrói o cliente para você; em Python é o **zeep**, que os pacotes
da aula 1 instalaram. Java tem JAX-WS e Apache CXF, .NET tem as service references, e Go e
JavaScript têm bibliotecas do mesmo tipo. O que vem a seguir vale para todos eles.

O zeep consegue imprimir o que entendeu de um contrato. A lista de tipos embutidos do XML Schema é
longa e igual para todo WSDL, então o `grep -v` a deixa de fora:

```
ana@api:~/shelf$ python3 -m zeep 'http://127.0.0.1:8001/distributor?wsdl' | grep -v '^     xsd:'

Prefixes:
     ns0: http://distributor.example/stock

Global elements:
     ns0:GetStock(ISBN: xsd:string)
     ns0:GetStockResponse(ISBN: xsd:string, QtyAvail: xsd:int, UnitPrice: xsd:decimal, NextDelivery: xsd:string)
     ns0:PlaceOrder(ISBN: xsd:string, Qty: xsd:int, CustomerRef: xsd:string)
     ns0:PlaceOrderResponse(OrderNo: xsd:string, Repeated: xsd:boolean)
     

Global types:

Bindings:
     Soap11Binding: {http://distributor.example/stock}StockBinding

Service: DistributorService
     Port: StockPort (Soap11Binding: {http://distributor.example/stock}StockBinding)
         Operations:
            GetStock(ISBN: xsd:string) -> ISBN: xsd:string, QtyAvail: xsd:int, UnitPrice: xsd:decimal, NextDelivery: xsd:string
            PlaceOrder(ISBN: xsd:string, Qty: xsd:int, CustomerRef: xsd:string) -> OrderNo: xsd:string, Repeated: xsd:boolean
```

Cada operação com seus argumentos e os tipos deles, lidos só do contrato. Ninguém escreveu essa
lista; se o distribuidor acrescentar uma operação ao WSDL, ela aparece aqui.

## Um cliente em poucas linhas

O `restock.py` pergunta o estoque de um livro e pede cópias dele. Salve-o ao lado dos outros:

```python
# shelf/restock.py
"""Order copies of one book from the distributor, through a client built from its WSDL.

    python3 restock.py ISBN QUANTITY REFERENCE
"""
import sys

import zeep

isbn, quantity, reference = sys.argv[1], int(sys.argv[2]), sys.argv[3]
client = zeep.Client("http://127.0.0.1:8001/distributor?wsdl")

stock = client.service.GetStock(ISBN=isbn)
print(stock)
order = client.service.PlaceOrder(ISBN=isbn, Qty=quantity, CustomerRef=reference)
print("order", order.OrderNo, "repeated" if order.Repeated else "new")
```

Peça cinco cópias de *A Hora da Estrela*, com uma referência sua para o pedido:

```
ana@api:~/shelf$ python3 restock.py 9786500000030 5 R-1001
{
    'ISBN': '9786500000030',
    'QtyAvail': 25,
    'UnitPrice': Decimal('18.90'),
    'NextDelivery': '20261012'
}
order PO100001 new
```

`client.service.GetStock` não existia até o zeep ler o WSDL. Ele montou o envelope, o enviou com o
`SOAPAction` certo, leu a resposta e **converteu cada valor para o tipo que o schema declarou**:
`QtyAvail` é um `int` do Python e `UnitPrice` é um `Decimal`, nem string nem float. `NextDelivery`
continuou string, porque o schema diz `xsd:string`; o zeep converte o que o contrato declara e nada
mais.

Ele também confere o seu lado antes de qualquer coisa ser enviada. Chame `GetStock` com um argumento
que o contrato não nomeia, e o erro vem do zeep, na sua máquina:

```
ana@api:~/shelf$ python3 -c "import zeep; zeep.Client('distributor.wsdl').service.GetStock(Isbn='9786500000030')" 2>&1 | tail -1
TypeError: {http://distributor.example/stock}GetStock() got an unexpected keyword argument 'Isbn'. Signature: `ISBN: xsd:string`
```

## O que o toolkit dá, e o que ele custa

| ele dá a você | ele custa a você |
|---|---|
| envelopes, namespaces e `SOAPAction` certos toda vez | um cliente que não sobe sem o WSDL: o `restock.py` o baixa e o lê a cada execução, e o log do distribuidor mostra esse `GET` antes de cada pedido |
| valores nos tipos que o schema declara | os nomes do distribuidor, `QtyAvail` e `CustomerRef`, como atributos no seu código |
| argumentos conferidos antes de saírem | o fio escondido: para ver o XML você tem de pedir ao toolkit |
| uma operação nova no dia em que o WSDL tiver uma | um WSDL alterado altera o seu cliente no dia em que é publicado, você tendo lido a mudança ou não |

A segunda linha da coluna da direita é a perigosa. `stock.QtyAvail` é conveniente no `restock.py`,
que tem poucas linhas. Espalhado pelo código da loja, todo módulo que o lê passa a depender de como
o distribuidor dá nome às coisas, e a seção sobre o adaptador trata de impedir que isso aconteça.
