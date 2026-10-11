---
title: Avro, e ler com um esquema diferente do de quem escreveu
version: 1
---

**Avro é um formato binário em que nada pode ser escrito sem um esquema, e nada pode ser lido sem
o esquema com que foi escrito.** O esquema é JSON: um registro com um nome e uma lista de campos,
cada um com um tipo. Os dados não são JSON. São os valores um atrás do outro, sem nomes de campos
e sem pontuação, na ordem em que o esquema os lista.

Essa segunda metade é onde o Avro difere do que a maioria espera. Em JSON, `{"qty": 2}` diz a que
campo o 2 pertence. Em Avro o 2 é só um número numa posição, e só o esquema diz que aquela posição
é `qty`. Então um leitor com o esquema errado não recebe um campo faltando: recebe lixo, ou um
erro. A resposta do Avro é fazer do **esquema de quem escreveu** algo que o leitor sempre tem, e
deixar o leitor trazer **o seu próprio esquema** também, e então resolver a diferença entre os
dois.

## Uma venda, três esquemas

`fastavro` é uma implementação de Avro em Python. Instale agora; a linha de instalação da próxima
seção o cita de novo, o que não custa nada:

```sh
pip install fastavro==1.13.1
```

Este programa escreve uma venda com um primeiro esquema e a lê de volta com outros dois. Salve como
`~/work/avro_demo.py`:

```schooling-example
{
  "language": "python",
  "file": "avro_demo.py",
  "parts": [
    {
      "code": "\"\"\"avro_demo.py: one sale written with one schema and read with others.\"\"\"\nimport io\nimport json\n\nimport fastavro\n\n\ndef schema(*fields):\n    return fastavro.parse_schema({\"type\": \"record\", \"name\": \"Sale\",\n                                  \"namespace\": \"pontofinal\", \"fields\": list(fields)})\n\n\nBASE = [{\"name\": \"sale\", \"type\": \"string\"}, {\"name\": \"shop\", \"type\": \"string\"},\n        {\"name\": \"book\", \"type\": \"string\"}, {\"name\": \"qty\", \"type\": \"int\"}]",
      "note": "`parse_schema` confere um esquema e o prepara. Toda versão aqui é o mesmo registro, `pontofinal.Sale`, com os mesmos quatro primeiros campos; o que muda é o final."
    },
    {
      "code": "V1 = schema(*BASE, {\"name\": \"cents\", \"type\": \"long\"})\nV2 = schema(*BASE, {\"name\": \"amount\", \"type\": \"long\", \"aliases\": [\"cents\"]},\n            {\"name\": \"till\", \"type\": \"string\", \"default\": \"unknown\"})\nV3 = schema(*BASE, {\"name\": \"cents\", \"type\": \"long\"}, {\"name\": \"till\", \"type\": \"string\"})\n",
      "note": "A **v1** é o que os caixas escrevem. A **v2** renomeia `cents` para `amount`, guardando o nome antigo como alias, e acrescenta `till` com um valor padrão. A **v3** acrescenta `till` sem valor padrão."
    },
    {
      "code": "sale = {\"sale\": \"nat-000002\", \"shop\": \"natal\", \"book\": \"bk-08\", \"qty\": 2, \"cents\": 17980}\nout = io.BytesIO()\nfastavro.schemaless_writer(out, V1, sale)\nbody = out.getvalue()\nprint(\"json:\", len(json.dumps(sale)), \"bytes\")\nprint(\"avro:\", len(body), \"bytes:\", body.hex(\" \"))\n",
      "note": "A venda é escrita com a v1, sem o arquivo contêiner que o Avro também define, como são as mensagens do Kafka. O tamanho dela é impresso ao lado do tamanho da mesma venda em JSON."
    },
    {
      "code": "print(\"read with v2:\", fastavro.schemaless_reader(io.BytesIO(body), V1, V2))\ntry:\n    fastavro.schemaless_reader(io.BytesIO(body), V1, V3)\nexcept Exception as e:\n    print(\"read with v3:\", type(e).__name__, e)",
      "note": "**Ler pede dois esquemas**: aquele com que os bytes foram escritos e aquele que o leitor quer. O Avro resolve a diferença campo a campo."
    }
  ]
}
```

```
ubuntu@stream:~/work$ python avro_demo.py
json: 82 bytes
avro: 27 bytes: 14 6e 61 74 2d 30 30 30 30 30 32 0a 6e 61 74 61 6c 0a 62 6b 2d 30 38 04 f8 98 02
read with v2: {'sale': 'nat-000002', 'shop': 'natal', 'book': 'bk-08', 'qty': 2, 'amount': 17980, 'till': 'unknown'}
read with v3: SchemaResolutionError No default value for field till in pontofinal.Sale
```

Vale ler os 27 bytes uma vez. `14` é o comprimento da primeira string, `nat-000002`, que tem dez
caracteres: o Avro escreve inteiros numa forma compacta em que dez vira `14`. Depois os dez
caracteres, `6e 61 74…`. Depois `0a`, um comprimento de cinco, e `natal`; mais cinco, e `bk-08`;
`04`, que é o 2 de `qty`; e `f8 98 02`, que é 17980. **Não há um único nome de campo ali.**

## O que a resolução faz

Quando o esquema do leitor difere do de quem escreveu, o Avro casa os campos **pelo nome** e
aplica uma lista curta de regras:

| a diferença | o que acontece |
|---|---|
| quem escreveu tem um campo que o leitor não tem | ele é pulado |
| o leitor tem um campo que quem escreveu não tinha, com valor padrão | usa-se o padrão |
| o leitor tem um campo que quem escreveu não tinha, sem valor padrão | a leitura falha |
| o leitor renomeia um campo e lista o nome antigo em `aliases` | o antigo é lido com o nome novo |
| um tipo muda para um mais largo, `int` para `long` | ele é promovido |

A segunda e a terceira linhas são a execução acima: `till` voltou como `unknown` na v2, e a v3 nem
conseguiu ler. **Um valor padrão é o que torna seguro acrescentar um campo**, e vale ler isso ao
contrário: um campo acrescentado sem padrão é um campo que nenhuma mensagem antiga consegue
satisfazer.

A quarta linha é a renomeação de que o caixa da última seção precisava, feita do jeito certo: o
leitor declara que `amount` antes se chamava `cents`. É também a regra que as pessoas lembram
errado. Um alias é o conhecimento que o leitor tem do passado, então só ajuda um leitor que já foi
atualizado; um leitor ainda na v1 que recebe uma mensagem escrita com a v2 procura `cents`, encontra
`amount` e falha. Qual lado atualiza primeiro é uma pergunta com resposta, e as duas últimas
seções desta lição a dão.

A outra coisa que a execução mostra é o custo de carregar nomes. A mesma venda tem 82 bytes em
JSON e 27 em Avro, porque o corpo Avro é os valores e nada mais. Num tópico de cem milhões de
vendas, essa diferença é a maior parte do disco.
