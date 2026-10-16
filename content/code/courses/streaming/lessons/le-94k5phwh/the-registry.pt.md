---
title: Subjects, versões e ids
version: 1
---

**Um registro guarda esquemas sob nomes chamados subjects, numera cada versão e dá a cada esquema
distinto um id.** As três palavras fazem trabalhos diferentes, e confundi-las é como as pessoas
acabam lendo o esquema errado:

| | o que é | exemplo |
|---|---|---|
| **subject** | o nome sob o qual uma série de versões é guardada | `sales-avro-value` |
| **versão** | a posição de um esquema no seu subject: 1, 2, 3… | a versão 2 de `sales-avro-value` |
| **id** | um número para o próprio esquema, o mesmo onde quer que ele esteja registrado | o id 1 |

O nome do subject segue uma convenção, não uma regra: **o nome do tópico mais `-value`** para o
esquema dos valores das mensagens, e `-key` para as chaves. O serializador Python deriva o nome do
mesmo jeito, e é por isso que ela importa. Um subject por tópico quer dizer que toda mensagem de um
tópico segue uma única série de versões, e a checagem de compatibilidade da penúltima seção é
aplicada ao longo dessa série.

## Registrando um esquema

O esquema de uma venda é um arquivo. Salve como `~/work/sale.avsc`:

```json
{
  "type": "record",
  "name": "Sale",
  "namespace": "pontofinal",
  "fields": [
    {"name": "sale", "type": "string"},
    {"name": "shop", "type": "string"},
    {"name": "book", "type": "string"},
    {"name": "qty", "type": "int"},
    {"name": "cents", "type": "long"},
    {"name": "at", "type": "string"}
  ]
}
```

A API do registro recebe um esquema como uma **string** JSON dentro de um objeto JSON, o que é
chato de digitar. Este script faz o embrulho com `jq` e envia. Salve como `~/work/register.sh`:

```sh
#!/usr/bin/env bash
# register.sh SUBJECT FILE: offer the schema in FILE as the next version of SUBJECT.
jq -n --rawfile schema "$2" '{schema: $schema}' |
  curl -s -X POST -H 'Content-Type: application/vnd.schemaregistry.v1+json' --data @- \
    "http://localhost:8080/apis/ccompat/v7/subjects/$1/versions"
echo
```

Torne-o executável com `chmod +x register.sh`. Depois, com o registro da última seção rodando,
registre a venda como a primeira versão do subject do tópico `sales-avro`, que a próxima seção
cria:

```
ubuntu@stream:~/work$ ./register.sh sales-avro-value sale.avsc
{"id":1}
ubuntu@stream:~/work$ curl -s localhost:8080/apis/ccompat/v7/subjects; echo
["sales-avro-value"]
ubuntu@stream:~/work$ curl -s localhost:8080/apis/ccompat/v7/subjects/sales-avro-value/versions/1; echo
{"subject":"sales-avro-value","version":1,"id":1,"schema":"{\"type\":\"record\",\"name\":\"Sale\",\"namespace\":\"pontofinal\",\"fields\":[{\"name\":\"sale\",\"type\":\"string\"},{\"name\":\"shop\",\"type\":\"string\"},{\"name\":\"book\",\"type\":\"string\"},{\"name\":\"qty\",\"type\":\"int\"},{\"name\":\"cents\",\"type\":\"long\"},{\"name\":\"at\",\"type\":\"string\"}]}"}
ubuntu@stream:~/work$ ./register.sh sales-avro-value sale.avsc
{"id":1}
```

O registro respondeu com o **id** do esquema, 1. O subject agora existe e a versão 1 dele guarda o
esquema, que o segundo `curl` mostra com os três números lado a lado. Oferecer o mesmo esquema de
novo não cria uma versão 2: o último comando recebeu o id 1 de volta, porque o registro reconhece
um esquema que já tem. É isso que permite a todo produtor de um tópico oferecer o seu esquema ao
iniciar sem encher o subject de cópias.

## O que vai dentro de uma mensagem

Uma mensagem não pode carregar o esquema inteiro: com algumas centenas de bytes, ele teria dez
vezes o tamanho da venda que descreve. Ela carrega o **id**, e um consumidor que encontra um id que
nunca viu pergunta ao registro uma vez e guarda a resposta. O layout é fixo, e todo cliente que
fala a API da Confluent escreve os mesmos cinco bytes na frente do corpo Avro:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O layout do valor de uma mensagem Kafka escrita por um serializador com registro de esquemas: um byte mágico, sempre 0; depois quatro bytes com o id do esquema, 00 00 00 01 para o id 1; depois o corpo Avro, os valores na ordem do esquema sem nomes de campos. O id aponta para o esquema guardado no registro, que o consumidor busca uma vez e guarda.\" data-fig=\"l6-wire\"><defs><marker id=\"l6-wire-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"30\" y=\"40\" width=\"70\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">00</text><rect x=\"104\" y=\"40\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"189\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">00 00 00 01</text><rect x=\"278\" y=\"40\" width=\"412\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">14 6e 61 74 2d 30 30 30 30 30 32 0a …</text><text x=\"65\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">byte mágico</text><text x=\"189\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">id do esquema</text><text x=\"484\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">corpo Avro</text><text x=\"65\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 byte</text><text x=\"189\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 bytes, big-endian</text><text x=\"484\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os valores, na ordem do esquema, sem nomes</text><path d=\"M 189 110 L 189 140\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l6-wire-ah-83)\"></path><rect x=\"84\" y=\"144\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"189\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o registro</text><text x=\"189\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id 1 = sale.avsc, versão 1</text><text x=\"310\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">buscado uma vez, depois guardado</text></svg>", "caption": "Cinco bytes na frente de cada mensagem bastam para qualquer leitor achar o esquema com que ela foi escrita.", "same": ["1 byte", "4 bytes, big-endian"]}
```

O primeiro byte é sempre zero, e existe para que o formato possa mudar um dia: um leitor que
encontra outra coisa sabe que não está lendo este layout. **O id tem quatro bytes, na ordem de
bytes da rede**, então o id 1 é `00 00 00 01`. Nada mais é acrescentado: nem número de versão, nem
nome de subject. A próxima seção põe vendas de verdade no tópico e olha os bytes delas.

É também por isso que **um id nunca pode ser reaproveitado para outro esquema**. Uma mensagem
escrita hoje será lida daqui a um ano, por um programa que só tem o id; se até lá o registro der
aquele id a outra coisa, a mensagem decodifica como lixo, ou como a venda errada. O registro só
acrescenta, o que é mais um motivo para um registro de laboratório que guarda os esquemas em
memória ser um registro de laboratório.
