---
title: Asserções sobre XML com XPath
version: 1
---

**Ler uma resposta a olho acha um defeito uma vez; uma asserção o acha toda vez que alguém a roda.**
Para JSON, as lições 5 a 8 apontaram para um campo pelo caminho dele. Para XML a linguagem de
apontar é o **XPath**: `//faultcode` quer dizer *um elemento `faultcode` em qualquer lugar do
documento*, e `string(...)` transforma o que ele acha em texto que dá para comparar. O xmllint
avalia um com `--xpath`.

## O primeiro XPath não acha nada

A expressão óbvia para o número da nota é `//invoiceNumber`:

```
ana@laptop:~/boxoffice$ curl -s localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @soap/issue.xml | xmllint --xpath '//invoiceNumber' -
XPath set is empty
ana@laptop:~/boxoffice$ echo $?
10
```

*XPath set is empty*, e um código de saída 10, embora o elemento esteja claramente ali. **A causa é
o namespace, e ele pega todo mundo uma vez.** A resposta declara `xmlns="urn:example:invoice:v1"`
no `IssueInvoiceResponse`, então todo elemento dentro dele pertence a esse namespace, mesmo sem
prefixo na frente. No XPath 1.0, que é o que o xmllint fala, um nome sem prefixo quer dizer *um
elemento sem namespace*, e não existe nenhum chamado `invoiceNumber`.

Ferramentas que entendem namespaces deixam você declarar um prefixo e escrever
`//inv:invoiceNumber`; a asserção XPath do SoapUI funciona assim, como a seção 07 descreve. O
`--xpath` do xmllint não tem opção para declarar um, então o jeito portátil é casar pelo nome local
do elemento, a parte depois de qualquer prefixo:

```
ana@laptop:~/boxoffice$ curl -s localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @soap/issue.xml | xmllint --xpath 'string(//*[local-name()="invoiceNumber"])' -
NFS-000004
```

A quarta nota: toda chamada bem-sucedida até aqui recebeu um número, inclusive a que não imprimiu
nada. O mesmo truque acha coisas no WSDL, onde todo elemento tem namespace. A operação aparece com
nome duas vezes, uma no `portType` e uma no `binding`, e a ação aparece uma vez:

```
ana@laptop:~/boxoffice$ curl -s 'localhost:8085/invoice?wsdl' | xmllint --xpath '//*[local-name()="operation"]/@name' -
 name="IssueInvoice"
 name="IssueInvoice"
ana@laptop:~/boxoffice$ curl -s 'localhost:8085/invoice?wsdl' | xmllint --xpath '//*[local-name()="operation"]/@soapAction' -
 soapAction="urn:example:invoice:v1#IssueInvoice"
```

Uma falha não precisa de truque. No SOAP 1.1, `faultcode` e `faultstring` ficam de propósito sem
namespace, então o nome simples funciona:

```
ana@laptop:~/boxoffice$ sed 's/12345678909/123/' soap/issue.xml | curl -s localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @- | xmllint --xpath 'string(//faultcode)' -
soap:Client
```

## Três casos, num script

Essas expressões já são testes; falta um script para rodá-las em ordem e contar as falhas. Este
manda os três envelopes da seção 05 que um contrato consegue julgar: o válido, o CPF curto e o
valor ausente. Salve como `soap/check.sh`:

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

Parte por parte:

```schooling-example
{
  "language": "sh",
  "file": "soap/check.sh",
  "parts": [
    {
      "code": "call() {\n  curl -s -o \"$REPLY\" -w '%{http_code}' \"$URL\" --data-binary \"@$1\" \\\n    -H 'content-type: text/xml; charset=utf-8' -H \"SOAPAction: $ACTION\"\n}",
      "note": "Uma requisição. O envelope vem de um arquivo, ou do pipe quando o argumento é `-`; a resposta vai para um arquivo temporário, e o curl imprime só o código de status, que é o que `call` devolve ao `$(...)`."
    },
    {
      "code": "xp() { xmllint --xpath \"string($1)\" \"$REPLY\"; }",
      "note": "Um XPath sobre a última resposta. Embrulhar a expressão em `string()` faz o xmllint imprimir um valor, nunca um nó, e um valor vazio em vez de um erro quando nada bate."
    },
    {
      "code": "check() {\n  if [ \"$2\" = \"$3\" ]; then\n    echo \"ok   $1\"\n  else\n    echo \"FAIL $1: expected '$2', got '$3'\"\n    failures=$((failures + 1))\n  fi\n}",
      "note": "Uma asserção: um nome, o que se esperava, o que chegou. Ela imprime a linha que uma pessoa lê e conta a falha em vez de parar, então uma execução relata todos os casos."
    },
    {
      "code": "status=$(call soap/issue.xml)\ncheck 'valid order: HTTP status' 200 \"$status\"\ncheck 'valid order: no fault' false \"$(xp 'boolean(//*[local-name()=\"Fault\"])')\"\ncheck 'valid order: invoice number' true \"$(xp 'starts-with(//*[local-name()=\"invoiceNumber\"], \"NFS-\")')\"",
      "note": "O caso positivo pergunta três coisas: o status, que a resposta não é uma falha e que o número tem a forma de um número de nota. `boolean()` e `starts-with()` são funções do XPath 1.0, então a comparação acontece dentro do xmllint."
    },
    {
      "code": "status=$(sed 's/12345678909/123/' soap/issue.xml | call -)\ncheck 'short tax id: HTTP status' 500 \"$status\"\ncheck 'short tax id: faultcode' soap:Client \"$(xp '//faultcode')\"\n\nstatus=$(sed '/amountCents/d' soap/issue.xml | call -)\ncheck 'no amount: HTTP status' 500 \"$status\"\ncheck 'no amount: faultcode' soap:Client \"$(xp '//faultcode')\"",
      "note": "Os casos negativos. O `500` sozinho não prova nada no SOAP 1.1, então cada um também pede `soap:Client`: a requisição estava errada, e a falha tem de dizer isso."
    },
    {
      "code": "rm -f \"$REPLY\"\necho \"$failures failed\"\n[ \"$failures\" -eq 0 ]",
      "note": "O último comando decide o código de saída do script: `0` quando nada falhou, `1` caso contrário."
    }
  ]
}
```

Rode a partir de `~/boxoffice`, com o serviço rodando:

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

Seis asserções passam e uma falha, e a que falha nomeia o defeito da seção 05 numa linha: esperava
`soap:Client`, recebeu `soap:Server`. O script sai com `1`, que é o que permite a um pipeline parar
nele, o mesmo contrato que o Newman cumpre na lição 6. **Este teste fica vermelho até o serviço ser
corrigido**, e esse é o trabalho dele: ele é o relatório de defeito, numa forma que se confere
sozinha.

O terminal do serviço registrou cada requisição desta lição, uma linha cada, na ordem em que você as
mandou:

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

Toda falha, seja qual for a causa, aparece como `500`. Um log como este não distingue um erro de
digitação de quem testa de uma queda, o que é mais um motivo para as asserções lerem o `faultcode`.
