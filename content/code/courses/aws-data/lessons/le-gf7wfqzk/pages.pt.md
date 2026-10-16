---
title: Páginas, Limit e LastEvaluatedKey
version: 1
---

**Toda leitura que pode devolver mais de um item devolve páginas, e um programa que lê uma página acha
que leu tudo.** A primeira seção mostrou páginas de 1 MB, que é o limite do servidor. O `--limit` é o de
quem chama: no máximo tantos itens por página. O botão "mostrar mais" de um app é exatamente isso, cinco
pedidos por vez:

```
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}}' --limit 5 --no-paginate --query '[Items[].sk.S,LastEvaluatedKey]'
[
    [
        "ORDER#2026-10-03#o-10001",
        "ORDER#2026-10-03#o-10001#LINE#1",
        "ORDER#2026-10-03#o-10001#LINE#2",
        "ORDER#2026-10-03#o-10001#LINE#3",
        "ORDER#2026-10-05#o-10002"
    ],
    {
        "pk": {
            "S": "CUSTOMER#c-17"
        },
        "sk": {
            "S": "ORDER#2026-10-05#o-10002"
        }
    }
]
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}}' --limit 5 --no-paginate --exclusive-start-key '{"pk": {"S": "CUSTOMER#c-17"}, "sk": {"S": "ORDER#2026-10-05#o-10002"}}' --query '[Items[].sk.S,LastEvaluatedKey]'
[
    [
        "ORDER#2026-10-05#o-10002#LINE#1",
        "ORDER#2026-10-05#o-10002#LINE#2",
        "ORDER#2026-10-05#o-10002#LINE#3",
        "ORDER#2026-10-12#o-10003",
        "ORDER#2026-10-12#o-10003#LINE#1"
    ],
    {
        "pk": {
            "S": "CUSTOMER#c-17"
        },
        "sk": {
            "S": "ORDER#2026-10-12#o-10003#LINE#1"
        }
    }
]
```

**A resposta trouxe a chave do último item devolvido, e a requisição seguinte começou depois dele.**
`LastEvaluatedKey` é a posição, e mandá-la de volta como `--exclusive-start-key` continua dali; a segunda
página começou na linha depois de `ORDER#2026-10-05#o-10002`. Uma página que volta sem
`LastEvaluatedKey` é a última, e esse é o único sinal confiável. A página de 1 MB da primeira seção e a
de cinco itens aqui são o mesmo mecanismo, e o `pages.py` é o laço dele.

**Foi o `--no-paginate` que fez a linha de comando mostrar uma página só.** Sem ele, a linha de comando
segue a `LastEvaluatedKey` sozinha, como fez no scan da primeira seção, e o `--max-items` e o
`--starting-token` da própria CLI paginam o resultado para uma pessoa lendo um terminal. Um programa que
usa o client do boto3 recebe uma página por chamada e precisa de um laço.

## O limite é contado antes do filtro

**O `Limit` limita os itens lidos, não os devolvidos.** Com filtro, uma página pode voltar curta ou vazia
enquanto há mais resultados adiante:

```
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --filter-expression 'order_day = :d' --expression-attribute-values '{":d": {"S": "2026-10-01"}}' --limit 100 --no-paginate --query '[Count,ScannedCount]' --output text
5	100
```

**Cem itens lidos, cinco devolvidos, e a página não diz nada sobre os outros 733 pedidos do dia.** Um
programa que pediu `Limit` 100 querendo dizer "os cem primeiros pedidos de 1º de outubro", e tomou uma
página como resposta, mostraria cinco e pararia. A mesma armadilha se esconde dentro da página de 1 MB:
um scan filtrado cujos resultados estão longe uns dos outros devolve páginas com `Count` 0 e uma
`LastEvaluatedKey`, e um laço que para na primeira página vazia para cedo. O laço para quando falta a
chave, nunca numa página vazia.

**Uma `LastEvaluatedKey` é a chave da tabela, e entregá-la a um navegador é entregar a chave.** Aqui ela
nomeia um cliente. Um app que pagina para um usuário em geral a codifica ou a guarda no servidor. Ele também confere se a próxima requisição ainda é para a partição daquele usuário, porque uma chave mandada de
volta por um cliente é uma chave que o cliente poderia ter escrito.
