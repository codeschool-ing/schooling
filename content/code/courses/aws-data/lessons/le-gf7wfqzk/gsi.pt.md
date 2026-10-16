---
title: Um índice secundário global
version: 1
---

**Um índice secundário global é uma segunda cópia, parcial, dos itens da tabela, sob chaves próprias,
mantida em dia pelo DynamoDB a cada escrita.** Não é o índice de `sql-databases`, que um planejador usa
quando julga que vale a pena. O DynamoDB não tem planejador: uma leitura só usa um índice quando a
requisição o nomeia, e uma query na tabela nunca olha para um.

**Um índice tem chave de partição e chave de ordenação próprias, e nenhuma precisa ser única.** Para o
A5 a pergunta parte de um dia, então o índice é particionado por `order_day` e ordenado por `order_id`.
Dois pedidos do mesmo dia dividem uma chave de partição ali, e a ideia é essa. Só os itens que têm os
dois atributos são copiados para ele: os pedidos, e não os perfis nem as linhas, que não têm
`order_day`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"À esquerda, a tabela: a coleção de CUSTOMER#c-17 guarda o perfil e os pedidos o-10001 de 3 de outubro e o-10002 de 5 de outubro com suas linhas; a coleção de CUSTOMER#c-19 guarda o-10006 de 3 de outubro e o-10009 de 14 de outubro. À direita, o índice by-day: a partição 2026-10-03 guarda o-10001 e o-10006, de dois clientes diferentes, e a partição 2026-10-14 guarda o-10009. Perfis e linhas não têm order_day e não são copiados.\" data-fig=\"l10-index\"><defs><marker id=\"l10-index-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a tabela, particionada por cliente</text><text x=\"440\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o índice by-day, particionado por order_day</text><rect x=\"20\" y=\"32\" width=\"300\" height=\"152\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"30\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">CUSTOMER#c-17</text><rect x=\"30\" y=\"54\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"38\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10001</text><rect x=\"30\" y=\"80\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"38\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">…#o-10001#LINE#1..3</text><text x=\"302\" y=\"91\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3 linhas</text><rect x=\"30\" y=\"106\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"38\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ORDER#2026-10-05#o-10002</text><rect x=\"30\" y=\"132\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"38\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">…#o-10002#LINE#1..3</text><text x=\"302\" y=\"143\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3 linhas</text><rect x=\"30\" y=\"158\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"38\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PROFILE</text><rect x=\"20\" y=\"196\" width=\"300\" height=\"126\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"30\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">CUSTOMER#c-19</text><rect x=\"30\" y=\"218\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"38\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10006</text><rect x=\"30\" y=\"244\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"38\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">…#o-10006#LINE#1..2</text><text x=\"302\" y=\"255\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2 linhas</text><rect x=\"30\" y=\"270\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"38\" y=\"281\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ORDER#2026-10-14#o-10009</text><rect x=\"30\" y=\"296\" width=\"280\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"38\" y=\"307\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PROFILE</text><rect x=\"440\" y=\"60\" width=\"260\" height=\"74\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"450\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">order_day = 2026-10-03</text><rect x=\"450\" y=\"82\" width=\"240\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"458\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-10001</text><text x=\"682\" y=\"93\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CUSTOMER#c-17</text><rect x=\"450\" y=\"108\" width=\"240\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"458\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-10006</text><text x=\"682\" y=\"119\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CUSTOMER#c-19</text><rect x=\"440\" y=\"150\" width=\"260\" height=\"48\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"450\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">order_day = 2026-10-05</text><rect x=\"450\" y=\"172\" width=\"240\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"458\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-10002</text><text x=\"682\" y=\"183\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CUSTOMER#c-17</text><rect x=\"440\" y=\"214\" width=\"260\" height=\"48\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"450\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">order_day = 2026-10-14</text><rect x=\"450\" y=\"236\" width=\"240\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"458\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-10009</text><text x=\"682\" y=\"247\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CUSTOMER#c-19</text><path d=\"M310,65 C380,65 380,93 448,93\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.1\" marker-end=\"url(#l10-index-ah)\"/><path d=\"M310,229 C380,229 380,119 448,119\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.1\" marker-end=\"url(#l10-index-ah)\"/><path d=\"M310,117 C380,117 380,183 448,183\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.1\" marker-end=\"url(#l10-index-ah)\"/><path d=\"M310,281 C380,281 380,247 448,247\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.1\" marker-end=\"url(#l10-index-ah)\"/><text x=\"440\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">perfis e linhas: fora do índice</text></svg>", "caption": "Os mesmos pedidos sob uma segunda chave. Cada pedido de um dia é copiado para a partição daquele dia no índice, seja de qual cliente for; itens sem order_day ficam para trás."}
```

**A projeção diz quais atributos vão para o índice.** `KEYS_ONLY` copia as chaves do índice e as da
tabela; `INCLUDE` acrescenta os atributos que nomeia; `ALL` copia os itens inteiros. Uma query num índice
global devolve só o que foi projetado, e não consegue voltar à tabela para buscar o resto, então a
projeção é decidida pelo que a pergunta precisa. O planejador de estoque precisa do total de cada
pedido:

```sh
aws dynamodb update-table --table-name quitanda \
  --attribute-definitions AttributeName=order_day,AttributeType=S AttributeName=order_id,AttributeType=S \
  --global-secondary-index-updates '[{"Create": {"IndexName": "by-day",
      "KeySchema": [{"AttributeName": "order_day", "KeyType": "HASH"},
                    {"AttributeName": "order_id", "KeyType": "RANGE"}],
      "Projection": {"ProjectionType": "INCLUDE", "NonKeyAttributes": ["total_cents"]}}}]' > /dev/null
```

```
ana@laptop:~/aws$ aws dynamodb describe-table --table-name quitanda --query "Table.GlobalSecondaryIndexes[].[IndexName,IndexStatus,Projection.ProjectionType,Projection.NonKeyAttributes[0]]" --output text
by-day	ACTIVE	INCLUDE	total_cents
```

**O moto informa o índice como `ACTIVE` na linha seguinte, e a AWS não faria isso.** Criar um índice
numa tabela que já tem itens começa um **backfill**: a AWS lê a tabela inteira e escreve no índice cada item que se qualifica. Até terminar, o índice fica em `CREATING` e recusa
queries, por minutos numa tabela
pequena e horas numa grande. Isso não foi rodado aqui; o moto monta o índice na mesma chamada.

## Lendo o índice

```
ana@laptop:~/aws$ python3 pages.py 2026-10-01 by-day
page 1: read    738 items, returned    738,    66,997 bytes returned, last page
1 page, 738 items read, 738 returned, 66,997 bytes returned, 8.5 read units for them
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --index-name by-day --key-condition-expression 'order_day = :d' --expression-attribute-values '{":d": {"S": "2026-10-01"}}' --max-items 2 --query 'Items[]' --output json
[
    {
        "pk": {
            "S": "CUSTOMER#c-20"
        },
        "sk": {
            "S": "ORDER#2026-10-01#o-10010"
        },
        "order_day": {
            "S": "2026-10-01"
        },
        "order_id": {
            "S": "o-10010"
        },
        "total_cents": {
            "N": "7467"
        }
    },
    {
        "pk": {
            "S": "CUSTOMER#c-23"
        },
        "sk": {
            "S": "ORDER#2026-10-01#o-10015"
        },
        "order_day": {
            "S": "2026-10-01"
        },
        "order_id": {
            "S": "o-10015"
        },
        "total_cents": {
            "N": "16227"
        }
    }
]
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --index-name by-day --key-condition-expression 'order_day = :d' --expression-attribute-values '{":d": {"S": "2026-10-01"}}' --consistent-read --select COUNT

aws: [ERROR]: An error occurred (ValidationException) when calling the Query operation: Consistent reads are not supported on global secondary indexes
```

**Uma página, 738 itens lidos e 738 devolvidos, 8,5 unidades de leitura.** O scan leu 34.100 itens para
a mesma resposta e custou 364,5. Cada item voltou com as chaves da tabela, as do índice e
`total_cents`, que é o que a projeção prometeu; o cliente está em `pk`, porque a chave da tabela sempre
vai junto. A tela que atualiza a cada minuto passa a custar 43.200 × 8,5 = 367.200 unidades de leitura
por mês, uns sete centavos, e cresce com o número de pedidos de um dia e não com o histórico.

**Um índice global é eventualmente consistente, e isso é recusado em vez de aproximado.** A escrita cai
primeiro na tabela e chega ao índice um instante depois, numa fração de segundo em condições normais
segundo a documentação da AWS, e mais tarde quando falta capacidade ao índice. Uma leitura que precisa
ver a própria escrita um milissegundo depois lê a tabela.

## O que o índice custa em troca

**Toda escrita num item que o índice guarda é também uma escrita no índice.** Carregar de novo os 10.029
pedidos daria 10.029 unidades de escrita a mais, e um update que muda `order_day` são duas escritas no
índice: a entrada antiga sai e a nova entra. O índice também é armazenado e cobrado como uma tabela, pelo
mesmo preço por GB da linha de armazenamento da tabela de preços, com cerca de cem bytes a mais por item.
E com capacidade provisionada, assunto da lição 11, ele tem capacidade própria: um índice que não dá conta
atrasa as escritas da tabela a que pertence. A lição 11 também volta à chave dele, porque os pedidos de um
dia inteiro sob uma chave de partição é a forma que uma partição quente toma.
