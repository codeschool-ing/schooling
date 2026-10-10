---
title: Faults
version: 1
---

**A SOAP fault is an answer, not the absence of one.** When something goes wrong, the service still
sends an envelope, and its `Body` holds a `Fault` instead of a result. In SOAP 1.1 a fault has a
`faultcode` saying whose fault it is, a `faultstring` for a person, and, optionally, a `detail`
that belongs to the service and can carry anything, usually an error code for a program.

Ask the distributor about an ISBN it does not sell. `sed` changes the ISBN on its way to curl, and
curl saves the answer to `fault.xml` and prints only the status:

```
ana@api:~/shelf$ sed s/9786500000030/9780000000000/ getstock.xml | curl -s -o fault.xml -w '%{http_code}\n' localhost:8001/distributor -H 'Content-Type: text/xml; charset=utf-8' -H 'SOAPAction: "http://distributor.example/stock/GetStock"' --data-binary @-
500
ana@api:~/shelf$ xmllint --format fault.xml
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>ISBN 9780000000000 is not in the catalogue</faultstring>
      <detail>
        <ErrorCode xmlns="http://distributor.example/stock">E100</ErrorCode>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
```

**The status is 500, and in SOAP 1.1 it is 500 for every fault**, including this one, where the
mistake was the caller's. The rule is in the SOAP 1.1 specification itself: a fault travels with
`500 Internal Server Error`, whoever caused it. SOAP 1.2 changed that, and sends a fault that
blames the caller with 400.

So the habit from lesson 1, reading the status to decide what happened, gives the wrong answer
here. A 500 says only *there is a fault in the body*. The three things that matter are inside it:

| where | here | says |
|---|---|---|
| `faultcode` | `soap:Client` | the request was wrong. `soap:Server` would mean the service failed. SOAP also defines `VersionMismatch` and `MustUnderstand` |
| `faultstring` | `ISBN 9780000000000 is not in the catalogue` | a sentence for a person, worded however the service likes |
| `detail` | `E100` | the distributor's own code, which only its documentation explains |

A program should decide on the code in `detail` and never on the wording of `faultstring`, which
somebody may improve next year.

## The fault in the toolkit

zeep turns a fault into a Python exception, `zeep.exceptions.Fault`, carrying the `faultstring` as
its message. `restock.py` does not catch it, so the program stops there; `tail -1` keeps only the
last line of the traceback:

```
ana@api:~/shelf$ python3 restock.py 9780000000000 5 R-1002 2>&1 | tail -1
zeep.exceptions.Fault: ISBN 9780000000000 is not in the catalogue
ana@api:~/shelf$ python3 restock.py 9786500000023 1 R-1003 2>&1 | tail -1
zeep.exceptions.Fault: only 0 of 9786500000023 available
```

The second run asked for a book the distributor has none of. `GetStock` answered normally, with a
`QtyAvail` of 0, and the fault came from `PlaceOrder`, which refused the order. Nothing was placed.

## What the shelf should say instead

The shop's own code should not have to know that `E200` means *not enough copies* or that a 500
from this one partner is often the shop's own mistake. Each case gets a status in the shelf's
terms, the ones lesson 1 used:

| from the distributor | the shelf answers | because |
|---|---|---|
| fault `E100`, unknown ISBN | **404** | the thing asked about does not exist |
| fault `E200`, not enough copies | **409** | the request conflicts with the current state |
| fault `E300`, no reference or a quantity under 1 | **422** | the request broke a rule |
| a `Server` fault, or a code nobody mapped | **502** Bad Gateway | the shelf did nothing wrong; the system behind it failed |
| no answer within the timeout | **504** Gateway Timeout | the system behind it did not answer in time |
| no connection at all | **502** | the system behind it is not there |

The last three are the **gateway** codes. 500 would say the shelf itself broke, and an alarm on the
shelf's 500s would then wake the wrong person for the distributor's bad night. The next section
writes this table as code.
