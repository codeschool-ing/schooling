---
title: "Avro: linhas, com o esquema no topo"
version: 1
---

**Avro é um formato de linhas com codificação binária, e todo arquivo Avro começa com o seu próprio
esquema, escrito em JSON.** Ele saiu do projeto Hadoop e foi feito para o trabalho oposto ao do
Parquet: gravar registros um por vez, depressa, e lê-los de volta inteiros, enquanto o esquema muda
por baixo.

O esquema é um documento JSON que dá nome a um registro e lista os seus campos, cada um com um tipo.
Os tipos são mais ricos que os do JSON: `int` e `long` são diferentes, `float` e `double` são
diferentes, há `bytes` para dado binário, e um **tipo lógico** pode dizer que um `long` é na verdade
um instante em milissegundos. Um registro em disco é então os seus valores na ordem em que o esquema
os lista, sem nomes e sem separadores: os nomes estão no esquema, uma vez.

## Um arquivo Avro

Um arquivo Avro é um **contêiner**: um cabeçalho, depois blocos de registros. O cabeçalho guarda
quatro bytes mágicos, o esquema, o nome do codec de compressão e um **marcador de sincronia**
aleatório de 16 bytes. Todo bloco termina com esse marcador, então um leitor que cai em qualquer
ponto no meio de um arquivo grande pode avançar até o próximo marcador e começar a ler dali. Isso
torna um arquivo Avro divisível, o que a seção 09 explica.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 238\" role=\"img\" aria-label=\"Um arquivo Avro desenhado em três faixas. O cabeçalho tem os bytes mágicos Obj e 1, os metadados com avro.schema e avro.codec, e um marcador de sincronia de 16 bytes. Cada bloco tem a contagem de registros, o tamanho em bytes, os registros com os valores na ordem do esquema e sem nomes de campos, e o marcador de novo, que deixa um leitor que começa no meio do arquivo achar o próximo bloco.\" data-fig=\"avro-file\"><defs><marker id=\"avro-file-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">cabeçalho</text><rect x=\"112\" y=\"20\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"147.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Obj 1</text><rect x=\"188\" y=\"20\" width=\"180\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"278.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">avro.schema: {…}</text><rect x=\"374\" y=\"20\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"439.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">avro.codec: null</text><rect x=\"510\" y=\"20\" width=\"86\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"553.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">marcador</text><text x=\"20\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">bloco 1</text><rect x=\"112\" y=\"88\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"147.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">contagem</text><rect x=\"188\" y=\"88\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tamanho</text><rect x=\"258\" y=\"88\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"290.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">viagem</text><rect x=\"328\" y=\"88\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">viagem</text><rect x=\"398\" y=\"88\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"430.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">viagem</text><rect x=\"468\" y=\"88\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"488.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">…</text><rect x=\"514\" y=\"88\" width=\"86\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"557.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">marcador</text><text x=\"20\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">bloco 2</text><rect x=\"112\" y=\"156\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"147.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">contagem</text><rect x=\"188\" y=\"156\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tamanho</text><rect x=\"258\" y=\"156\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"290.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">viagem</text><rect x=\"328\" y=\"156\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">viagem</text><rect x=\"398\" y=\"156\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"430.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">viagem</text><rect x=\"468\" y=\"156\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"488.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">…</text><rect x=\"514\" y=\"156\" width=\"86\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"557.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">marcador</text><text x=\"112\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma viagem: os valores na ordem do esquema, sem nomes</text><text x=\"112\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o mesmo marcador depois de cada bloco: quem começa no meio do arquivo avança até o próximo</text></svg>", "caption": "Um arquivo contêiner Avro: o esquema uma vez no cabeçalho, depois blocos de registros, cada um terminando no mesmo marcador de sincronia."}
```

Salve isto como `formats/as_avro.py`. Ele declara o esquema de uma viagem, grava o mês de viagens e
lê o arquivo de volta:

```schooling-example
{"language": "python", "file": "formats/as_avro.py", "parts": [{"code": "# formats/as_avro.py\nfrom fastavro import parse_schema, reader, writer\nfrom rides import make\n\nSCHEMA = parse_schema({\n    \"type\": \"record\", \"name\": \"Ride\", \"namespace\": \"roda\",\n    \"fields\": [\n        {\"name\": \"ride_id\", \"type\": \"string\"},\n        {\"name\": \"bike_id\", \"type\": \"string\"},\n        {\"name\": \"start_station\", \"type\": \"string\"},\n        {\"name\": \"end_station\", \"type\": \"string\"},\n        {\"name\": \"started_at\",\n         \"type\": {\"type\": \"long\", \"logicalType\": \"timestamp-millis\"}},\n        {\"name\": \"minutes\", \"type\": \"int\"},\n        {\"name\": \"member\", \"type\": \"boolean\"},\n    ],\n})\n\n", "note": "O esquema, como um dicionário Python que também é JSON válido. `started_at` é um `long` com o tipo lógico `timestamp-millis`; `minutes` é um `int`, e `member` um `boolean`. `parse_schema` o confere antes de qualquer gravação."}, {"code": "if __name__ == \"__main__\":\n    with open(\"rides.avro\", \"wb\") as f:\n        writer(f, SCHEMA, make(50_000))\n    with open(\"rides.avro\", \"rb\") as f:\n        rides = reader(f)\n        print(\"fields:\", [field[\"name\"] for field in rides.writer_schema[\"fields\"]])\n        print(\"codec:\", rides.codec)\n        first = next(rides)\n    print(\"first ride:\", first[\"ride_id\"], first[\"started_at\"], first[\"minutes\"])\n", "note": "Gravar é uma chamada: o arquivo, o esquema e as viagens. Ler abre o arquivo e acha o esquema no cabeçalho, sem nenhum esquema passado; depois `next` pega a primeira viagem."}]}
```

```
ana@lab:~/roda/formats$ python as_avro.py
fields: ['ride_id', 'bike_id', 'start_station', 'end_station', 'started_at', 'minutes', 'member']
codec: null
first ride: R000001 2025-09-01 09:01:23+00:00 5
```

Os campos voltaram do arquivo, não do programa: `writer_schema` é o esquema do cabeçalho. `codec:
null` quer dizer que os blocos não estão comprimidos, que é o padrão do fastavro. E a primeira viagem
começou às 06:01:23 em Curitiba e voltou como 09:01:23 em UTC. É o mesmo instante, porque
`timestamp-millis` guarda milissegundos desde 1970 em UTC e mais nada; o fuso em que a viagem foi
gravada não faz parte do valor. Se ele importa, precisa ser um campo próprio.

O esquema está mesmo no topo do arquivo, como texto. Os primeiros cem bytes, impressos do jeito que
o Python mostra bytes:

```
ana@lab:~/roda/formats$ python -c "print(open('rides.avro', 'rb').read(100))"
b'Obj\x01\x04\x14avro.codec\x08null\x16avro.schema\xf2\x05{"type": "record", "name": "roda.Ride", "fields": [{"name": "ride'
```

`Obj` e um byte de valor 1 são a marca mágica, depois vêm as duas entradas de metadados,
`avro.codec` e `avro.schema`, com o próprio esquema começando em JSON puro.

## Onde ele é usado

A força do Avro é o registro avulso. Uma viagem codificada sozinha ocupa algumas dezenas de bytes,
sem nomes, o que serve bem a uma mensagem num fluxo, onde os eventos são enviados um a um e lidos por
programas escritos em épocas diferentes por times diferentes. Em plataformas de fluxo como o Apache
Kafka, o esquema muitas vezes fica num **registro de esquemas** (*schema registry*), um serviço que
guarda cada versão uma vez, e cada mensagem carrega um id curto que aponta para a versão com que foi
gravada. A aula 8 é sobre fluxos. E como os dois esquemas são sempre conhecidos, o de quem gravou e o
de quem lê, o Avro tem regras precisas para ler dados antigos com um esquema novo. A seção 10
as executa.
