---
title: A client built from the WSDL
version: 1
---

Writing envelopes by hand is how you find out what is on the wire. Writing them by hand **in a
program** is how you get the namespace wrong in the one message nobody tested. Every language has a
SOAP toolkit that reads the WSDL and builds the client for you; in Python it is **zeep**, which
lesson 1's packages installed. Java has JAX-WS and Apache CXF, .NET has its service references, and
Go and JavaScript have libraries of the same kind. What follows is true of all of them.

zeep can print what it understood from a contract. The list of built-in XML Schema types is long
and the same for every WSDL, so `grep -v` leaves it out:

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

Every operation with its arguments and their types, read from the contract alone. Nobody wrote
that list; if the distributor adds an operation to its WSDL, it appears here.

## A client in a few lines

`restock.py` asks for one book's stock and orders copies of it. Save it beside the others:

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

Ask for five copies of *A Hora da Estrela*, with a reference of your own for the order:

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

`client.service.GetStock` did not exist until zeep read the WSDL. It built the envelope, sent it
with the right `SOAPAction`, parsed the answer and **converted each value to the type the schema
declared**: `QtyAvail` is a Python `int` and `UnitPrice` is a `Decimal`, not a string and not a
float. `NextDelivery` stayed a string, because the schema says `xsd:string`; zeep converts what the
contract declares and nothing more.

It also checks your side before anything is sent. Call `GetStock` with an argument the contract
does not name, and the error comes from zeep, on your machine:

```
ana@api:~/shelf$ python3 -c "import zeep; zeep.Client('distributor.wsdl').service.GetStock(Isbn='9786500000030')" 2>&1 | tail -1
TypeError: {http://distributor.example/stock}GetStock() got an unexpected keyword argument 'Isbn'. Signature: `ISBN: xsd:string`
```

## What the toolkit gives, and what it costs

| it gives you | it costs you |
|---|---|
| envelopes, namespaces and `SOAPAction` right every time | a client that cannot start without the WSDL: `restock.py` downloads and parses it on every run, and the distributor's log shows that `GET` before each order |
| values in the types the schema declares | the distributor's names, `QtyAvail` and `CustomerRef`, as attributes in your code |
| arguments checked before they leave | the wire hidden: to see the XML you have to ask the toolkit for it |
| a new operation the day the WSDL has one | a changed WSDL changes your client the day it is published, whether or not you read the change |

The second row of the right-hand column is the dangerous one. `stock.QtyAvail` is convenient in
`restock.py`, which is a few lines long. Spread through the shop's code, every module that reads it
now depends on how the distributor names things, and the section on the adapter is about keeping
that from happening.
