---
title: Asserting on XML with XPath
version: 1
---

**Reading a reply by eye finds a defect once; an assertion finds it every time somebody runs it.**
For JSON, lessons 5 to 8 pointed at a field by its path. For XML the language for pointing is
**XPath**: `//faultcode` means *a `faultcode` element anywhere in the document*, and
`string(...)` turns what it finds into text you can compare. xmllint evaluates one with `--xpath`.

## The first XPath finds nothing

The obvious expression for the invoice number is `//invoiceNumber`:

```
ana@laptop:~/boxoffice$ curl -s localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @soap/issue.xml | xmllint --xpath '//invoiceNumber' -
XPath set is empty
ana@laptop:~/boxoffice$ echo $?
10
```

*XPath set is empty*, and an exit code of 10, although the element is plainly there. **The cause is
the namespace, and it catches everybody once.** The response declares
`xmlns="urn:example:invoice:v1"` on `IssueInvoiceResponse`, so every element inside it belongs to
that namespace even with no prefix in front. In XPath 1.0, which xmllint speaks, a bare name means
*an element in no namespace*, and there is none called `invoiceNumber`.

Tools that know about namespaces let you declare a prefix and write `//inv:invoiceNumber`;
SoapUI's XPath assertion works that way, as section 07 describes. xmllint's `--xpath` has no option
for declaring one, so the portable way is to match on the element's local name, the part after any
prefix:

```
ana@laptop:~/boxoffice$ curl -s localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @soap/issue.xml | xmllint --xpath 'string(//*[local-name()="invoiceNumber"])' -
NFS-000004
```

The fourth invoice: every successful call so far got a number, the one that printed nothing
included. The same trick finds things in the WSDL, where every element is namespaced. The operation
is named twice, once in `portType` and once in `binding`, and the action is written once:

```
ana@laptop:~/boxoffice$ curl -s 'localhost:8085/invoice?wsdl' | xmllint --xpath '//*[local-name()="operation"]/@name' -
 name="IssueInvoice"
 name="IssueInvoice"
ana@laptop:~/boxoffice$ curl -s 'localhost:8085/invoice?wsdl' | xmllint --xpath '//*[local-name()="operation"]/@soapAction' -
 soapAction="urn:example:invoice:v1#IssueInvoice"
```

A fault needs no trick. In SOAP 1.1, `faultcode` and `faultstring` are deliberately left in no
namespace, so the plain name works:

```
ana@laptop:~/boxoffice$ sed 's/12345678909/123/' soap/issue.xml | curl -s localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @- | xmllint --xpath 'string(//faultcode)' -
soap:Client
```

## Three cases, as a script

Those expressions are already tests; they need a script to run them in order and count the
failures. This one sends the three envelopes of section 05 that a contract can judge: the valid
one, the short tax id and the missing amount. Save it as `soap/check.sh`:

```sh
#!/usr/bin/env bash
# check.sh: three cases against the invoice service, each asserted with xmllint.
# Run it from ~/boxoffice with the service started: bash soap/check.sh
URL=http://localhost:8085/invoice
ACTION='"urn:example:invoice:v1#IssueInvoice"'
REPLY=$(mktemp)
failures=0

# call FILE: post the envelope in FILE (- reads it from the pipe) and print the
# HTTP status; the reply is left in $REPLY.
call() {
  curl -s -o "$REPLY" -w '%{http_code}' "$URL" --data-binary "@$1" \
    -H 'content-type: text/xml; charset=utf-8' -H "SOAPAction: $ACTION"
}

# xp EXPR: the value of an XPath expression over the reply, as a string.
xp() { xmllint --xpath "string($1)" "$REPLY"; }

# check NAME EXPECTED ACTUAL
check() {
  if [ "$2" = "$3" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1: expected '$2', got '$3'"
    failures=$((failures + 1))
  fi
}

status=$(call soap/issue.xml)
check 'valid order: HTTP status' 200 "$status"
check 'valid order: no fault' false "$(xp 'boolean(//*[local-name()="Fault"])')"
check 'valid order: invoice number' true "$(xp 'starts-with(//*[local-name()="invoiceNumber"], "NFS-")')"

status=$(sed 's/12345678909/123/' soap/issue.xml | call -)
check 'short tax id: HTTP status' 500 "$status"
check 'short tax id: faultcode' soap:Client "$(xp '//faultcode')"

status=$(sed '/amountCents/d' soap/issue.xml | call -)
check 'no amount: HTTP status' 500 "$status"
check 'no amount: faultcode' soap:Client "$(xp '//faultcode')"

rm -f "$REPLY"
echo "$failures failed"
[ "$failures" -eq 0 ]
```

Piece by piece:

```schooling-example
{
  "language": "sh",
  "file": "soap/check.sh",
  "parts": [
    {
      "code": "call() {\n  curl -s -o \"$REPLY\" -w '%{http_code}' \"$URL\" --data-binary \"@$1\" \\\n    -H 'content-type: text/xml; charset=utf-8' -H \"SOAPAction: $ACTION\"\n}",
      "note": "One request. The envelope comes from a file, or from the pipe when the argument is `-`; the reply goes to a temporary file, and curl prints only the status code, which becomes what `call` returns to `$(...)`."
    },
    {
      "code": "xp() { xmllint --xpath \"string($1)\" \"$REPLY\"; }",
      "note": "One XPath over the last reply. Wrapping the expression in `string()` makes xmllint print a value, never a node, and an empty value rather than an error when nothing matches."
    },
    {
      "code": "check() {\n  if [ \"$2\" = \"$3\" ]; then\n    echo \"ok   $1\"\n  else\n    echo \"FAIL $1: expected '$2', got '$3'\"\n    failures=$((failures + 1))\n  fi\n}",
      "note": "One assertion: a name, what was expected, what arrived. It prints the line a person reads and counts the failure instead of stopping, so one run reports every case."
    },
    {
      "code": "status=$(call soap/issue.xml)\ncheck 'valid order: HTTP status' 200 \"$status\"\ncheck 'valid order: no fault' false \"$(xp 'boolean(//*[local-name()=\"Fault\"])')\"\ncheck 'valid order: invoice number' true \"$(xp 'starts-with(//*[local-name()=\"invoiceNumber\"], \"NFS-\")')\"",
      "note": "The positive case asks three things: the status, that the reply is not a fault, and that the number has the shape an invoice number has. `boolean()` and `starts-with()` are XPath 1.0 functions, so the comparison happens inside xmllint."
    },
    {
      "code": "status=$(sed 's/12345678909/123/' soap/issue.xml | call -)\ncheck 'short tax id: HTTP status' 500 \"$status\"\ncheck 'short tax id: faultcode' soap:Client \"$(xp '//faultcode')\"\n\nstatus=$(sed '/amountCents/d' soap/issue.xml | call -)\ncheck 'no amount: HTTP status' 500 \"$status\"\ncheck 'no amount: faultcode' soap:Client \"$(xp '//faultcode')\"",
      "note": "The negative cases. `500` alone proves nothing in SOAP 1.1, so each one also asks for `soap:Client`: the request was wrong, and the fault has to say so."
    },
    {
      "code": "rm -f \"$REPLY\"\necho \"$failures failed\"\n[ \"$failures\" -eq 0 ]",
      "note": "The last command decides the exit status of the script: `0` when nothing failed, `1` otherwise."
    }
  ]
}
```

Run it from `~/boxoffice`, with the service running:

```
ana@laptop:~/boxoffice$ bash soap/check.sh
ok   valid order: HTTP status
ok   valid order: no fault
ok   valid order: invoice number
ok   short tax id: HTTP status
ok   short tax id: faultcode
ok   no amount: HTTP status
FAIL no amount: faultcode: expected 'soap:Client', got 'soap:Server'
1 failed
ana@laptop:~/boxoffice$ echo $?
1
```

Six assertions pass and one fails, and the failing one names the defect of section 05 in a line:
expected `soap:Client`, got `soap:Server`. The script exits with `1`, which is what lets a pipeline
stop on it, the same contract Newman keeps in lesson 6. **This test stays red until the service is
fixed**, and that is its job: it is the defect report, in a form that checks itself.

The service's own terminal has logged every request of this lesson, one line each, in the order you
sent them:

```
ana@laptop:~/boxoffice$ node soap/invoice-service.mjs
invoice service listening on http://localhost:8085
GET /invoice?wsdl 200
POST /invoice 200
POST /invoice 200
POST /invoice 500
POST /invoice 500
POST /invoice 415
POST /invoice 500
POST /invoice 200
POST /invoice 200
GET /invoice?wsdl 200
GET /invoice?wsdl 200
POST /invoice 500
POST /invoice 200
POST /invoice 500
POST /invoice 500
```

Every fault, whatever its cause, shows as `500`. A log like this one cannot tell a tester's typo
from a crash, which is one more reason the assertions read the `faultcode`.
