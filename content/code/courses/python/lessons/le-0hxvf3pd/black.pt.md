---
title: O `black`, e as opções que ele não tem
version: 2
---

```python
def send_invoice(customer_id, amount_cents, currency = 'BRL', notify = True, retries=3):
    result = gateway.charge( customer_id, amount_cents, currency=currency, idempotency_key=make_key(customer_id, amount_cents) )
    if result.ok == True :
        return {'status':'ok','id':result.id}
```

```python
def send_invoice(customer_id, amount_cents, currency="BRL", notify=True, retries=3):
    result = gateway.charge(
        customer_id,
        amount_cents,
        currency=currency,
        idempotency_key=make_key(customer_id, amount_cents),
    )
    if result.ok == True:
        return {"status": "ok", "id": result.id}
```

**Quatro tipos de mudança, nenhuma delas uma decisão.** Aspas duplas. Sem espaços em volta do `=`
de um argumento nomeado. Sem espaço antes de um `:`. E uma chamada que não cabe numa linha
explodida em um argumento por linha, com vírgula final.

Repare no que ele não tocou: `result.ok == True` continua ali. Isso é achado de linter, e um
formatador não tem opinião a respeito.

## Os ajustes

```toml
[tool.black]
line-length = 88
target-version = ["py312"]
```

São quase todos. **A ausência é deliberada** — um formatador com ajustes é um formatador sobre o
qual uma equipe pode discutir, e remover a discussão é o produto inteiro. `88` é um número
estranho e é o padrão, que é a única propriedade dele que importa.

## A vírgula final mágica

```python
other = charge(customer, amount, currency,)
```

```python
other = charge(
    customer,
    amount,
    currency,
)
```

Uma vírgula final que você deixa é um **pedido**: ela diz ao `black` para manter esta chamada
explodida mesmo que ela coubesse numa linha. É o único lugar em que você pode contrariá-lo, e é
útil para uma lista de argumentos que vai crescer.

Tire a vírgula e ela volta para uma linha.

## Rodando

```sh
black app/            # rewrite
black --check app/    # exit 1 if anything would change, rewrite nothing
black --diff app/     # print what it would do
```

`--check` é o que vai na CI. Ele imprime `would reformat c.py` e sai diferente de zero, e é o
comentário de revisão inteiro que ninguém precisa mais escrever.

## A primeira rodada

Ela vai reescrever o repositório inteiro. Faça isso em **um commit, sozinho**, sem nenhuma outra
mudança dentro — e então acrescente o hash desse commit ao `.git-blame-ignore-revs` e aponte o git
para ele:

```sh
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

Caso contrário o `git blame` responde "o commit de formatação" para toda linha do projeto, e o
histórico deixa de ser utilizável no dia em que você adotou a ferramenta.
