---
title: Falhas
version: 1
---

**Uma falha SOAP é uma resposta, não a ausência de uma.** Quando algo dá errado, o serviço ainda
manda um envelope, e o `Body` dele traz um `Fault` no lugar de um resultado. No SOAP 1.1 uma falha
tem um `faultcode` dizendo de quem é a culpa, um `faultstring` para uma pessoa e, opcionalmente, um
`detail` que pertence ao serviço e pode levar qualquer coisa, em geral um código de erro para um
programa.

Pergunte ao distribuidor sobre um ISBN que ele não vende. O `sed` troca o ISBN no caminho até o
curl, e o curl salva a resposta em `fault.xml` e imprime só o status:

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

**O status é 500, e no SOAP 1.1 ele é 500 para toda falha**, inclusive esta, em que o erro foi de
quem chamou. A regra está na própria especificação do SOAP 1.1: uma falha viaja com
`500 Internal Server Error`, seja quem for o culpado. O SOAP 1.2 mudou isso, e manda com 400 uma
falha que põe a culpa em quem chamou.

Então o hábito da aula 1, ler o status para decidir o que aconteceu, dá a resposta errada aqui. Um
500 só diz *há uma falha no corpo*. As três coisas que importam estão dentro dele:

| onde | aqui | diz |
|---|---|---|
| `faultcode` | `soap:Client` | a requisição estava errada. `soap:Server` significaria que o serviço falhou. O SOAP também define `VersionMismatch` e `MustUnderstand` |
| `faultstring` | `ISBN 9780000000000 is not in the catalogue` | uma frase para uma pessoa, escrita como o serviço quiser |
| `detail` | `E100` | o código do próprio distribuidor, que só a documentação dele explica |

Um programa deve decidir pelo código no `detail` e nunca pelo texto do `faultstring`, que alguém
pode melhorar ano que vem.

## A falha no toolkit

O zeep transforma uma falha numa exceção do Python, `zeep.exceptions.Fault`, que leva o
`faultstring` como mensagem. O `restock.py` não a captura, então o programa para ali; o `tail -1`
guarda só a última linha do traceback:

```
ana@api:~/shelf$ python3 restock.py 9780000000000 5 R-1002 2>&1 | tail -1
zeep.exceptions.Fault: ISBN 9780000000000 is not in the catalogue
ana@api:~/shelf$ python3 restock.py 9786500000023 1 R-1003 2>&1 | tail -1
zeep.exceptions.Fault: only 0 of 9786500000023 available
```

A segunda execução pediu um livro de que o distribuidor não tem nenhuma cópia. O `GetStock`
respondeu normalmente, com `QtyAvail` 0, e a falha veio do `PlaceOrder`, que recusou o pedido. Nada
foi pedido.

## O que o shelf deveria dizer no lugar

O código da própria loja não deveria precisar saber que `E200` quer dizer *cópias insuficientes*, nem
que um 500 deste parceiro muitas vezes é erro da própria loja. Cada caso ganha um status nos termos
do shelf, os que a aula 1 usou:

| do distribuidor | o shelf responde | porque |
|---|---|---|
| falha `E100`, ISBN desconhecido | **404** | a coisa perguntada não existe |
| falha `E200`, cópias insuficientes | **409** | a requisição conflita com o estado atual |
| falha `E300`, sem referência ou com quantidade abaixo de 1 | **422** | a requisição quebrou uma regra |
| uma falha `Server`, ou um código que ninguém mapeou | **502** Bad Gateway | o shelf não fez nada errado; o sistema por trás dele falhou |
| nenhuma resposta dentro do timeout | **504** Gateway Timeout | o sistema por trás dele não respondeu a tempo |
| nenhuma conexão | **502** | o sistema por trás dele não está lá |

As três últimas são os códigos de **gateway**. Um 500 diria que o próprio shelf quebrou, e um alarme
nos 500 do shelf acordaria a pessoa errada na noite ruim do distribuidor. A próxima seção escreve
esta tabela como código.
