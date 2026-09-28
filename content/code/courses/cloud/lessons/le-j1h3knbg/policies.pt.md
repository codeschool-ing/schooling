---
title: Uma política, linha por linha
version: 1
---

Uma **política** é um documento JSON que lista o que pode ou não pode ser feito. O mesmo formato
serve a todo lugar a que uma política se anexa — um usuário, um grupo, uma role e alguns recursos —,
então aprender a ler uma é aprender a ler todas. Ela tem uma anatomia pequena e fixa:

- `Version`, a versão da linguagem de políticas;
- `Statement`, uma lista de declarações, cada uma decidindo algo sozinha;
- em cada declaração, `Effect`, que é `Allow` ou `Deny`;
- `Action`, as operações que ela cobre, escritas `serviço:Operação`;
- `Resource`, as coisas que ela cobre, escritas como ARNs;
- opcionalmente `Condition`, as circunstâncias em que ela vale, e `Sid`, um rótulo para pessoas.

Uma declaração quer dizer: para estas ações, sobre estes recursos, nestas circunstâncias, o efeito é
este. **Cada parte estreita**; uma declaração com mais ações ou um recurso mais amplo diz sim a mais
coisas.

## Uma política, lida parte por parte

Aqui está uma política para alguém que precisa ler os relatórios deste ano e mais nada: os objetos
abaixo de `2026/` no bucket `example-reports`, e uma listagem do que existe ali. Ela foi escrita para
esta lição e não está aplicada em lugar nenhum, porque não há conta neste curso; é o documento que
você anexaria a um usuário, um grupo ou uma role.

```schooling-example
{"language": "json", "file": "read-reports-2026.json", "parts": [{"code": "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [", "note": "`Version` é a versão da **linguagem** de políticas, não uma data para manter em dia. `2012-10-17` é a atual e o valor a escrever. Sem essa linha, a AWS lê a política na versão antiga, de 2008, em que variáveis como `${aws:username}` não funcionam. `Statement` abre a lista."}, {"code": "    {\n      \"Sid\": \"ReadReports2026\",\n      \"Effect\": \"Allow\",\n      \"Action\": \"s3:GetObject\",\n      \"Resource\": \"arn:aws:s3:::example-reports/2026/*\"\n    },", "note": "A primeira declaração lê objetos. `s3:GetObject` busca um objeto, e o recurso é todo objeto cuja chave começa com `2026/` neste bucket: o `*` no fim do ARN casa com o resto da chave, barras incluídas. `Sid` é só um rótulo, para quem lê."}, {"code": "    {\n      \"Sid\": \"ListReports2026\",\n      \"Effect\": \"Allow\",\n      \"Action\": \"s3:ListBucket\",\n      \"Resource\": \"arn:aws:s3:::example-reports\",", "note": "A segunda declaração lista. `s3:ListBucket` é uma ação sobre o **bucket**, então o recurso é o ARN do bucket sem `/*` depois. Permitida sozinha, ela listaria toda chave do bucket, inclusive os anos que essa pessoa não pode ler."}, {"code": "      \"Condition\": {\n        \"StringLike\": { \"s3:prefix\": \"2026/*\" }\n      }\n    }\n  ]\n}", "note": "Por isso a condição a estreita. `StringLike` compara com curingas, e `s3:prefix` é o prefixo que o pedido pediu para listar. Uma listagem de `2026/` ou de algo abaixo é permitida; uma listagem do bucket inteiro, sem prefixo, não casa com nada e é recusada."}]}
```

Duas declarações, e não uma, porque as duas ações trabalham sobre dois tipos diferentes de recurso.
É o detalhe que mais se erra em políticas de S3: `s3:ListBucket` posto em
`arn:aws:s3:::example-reports/*` não casa com nada, porque uma listagem não é uma operação sobre
objeto nenhum. O pedido de listar é recusado, a política parece certa, e alguém perde uma tarde nisso.

## O que uma política não contém

Não há `Principal` nesse documento, e está certo. **Uma política anexada a uma identidade fala dessa
identidade**, então não precisa nomeá-la; o usuário, grupo ou role a que ela está anexada é o
principal. `Principal` aparece nos dois tipos de política que ficam em outro lugar e precisam dizer
de quem estão falando: a política de confiança, como na seção anterior, e a política baseada em
recurso, como uma política de bucket anexada ao próprio bucket.

Também não há ordem. As declarações não são lidas de cima para baixo com a primeira que casa
vencendo, como costuma acontecer com regras de firewall; a próxima seção mostra que toda declaração
que se aplica é pesada junto com as outras.

E as listas de uma declaração se multiplicam. Uma declaração com três ações e dois recursos cobre
toda ação sobre todo recurso, seis pares ao todo, e não três pares casados. Se os pares precisam ser
casados — leitura aqui, escrita ali —, precisam ser declarações separadas.

## Ações têm nomes que se consultam

Cada provedor publica a lista de ações por serviço, com o recurso sobre o qual cada ação trabalha e
as chaves de condição que ela entende. Na AWS é a *Service Authorization Reference*. A lista é longa:
só o S3 tem bem mais de cem ações. Ninguém decora; o hábito a criar é consultar a ação que você acha
que precisa, conferir que recurso ela espera e escrever exatamente isso, que é o assunto da seção
depois da próxima.
