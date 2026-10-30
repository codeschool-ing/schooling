---
title: O Error Reporting junta a mesma falha numa linha só
version: 1
---

**O Error Reporting lê as entradas de erro do Cloud Logging, reconhece as que trazem um stack trace e agrupa
numa linha só aquelas cujos stack traces são iguais.** Uma falha que acontece quatro mil vezes numa hora é um
grupo com uma contagem, uma primeira e uma última aparição, e não quatro mil linhas para rolar. Não precisa de
nada instalado: uma entrada com severidade `ERROR` ou pior e um stack trace na mensagem basta, desde que o
trace esteja dentro de **uma** entrada. **Nada aqui chega ao Error Reporting**, que não tem emulador. O que roda
é um programa que escreve as entradas do jeito certo, e um agrupamento feito no seu computador para mostrar o
que o Error Reporting faria com elas.

O programa abaixo procura dois produtos que não existem, como o checkout da loja faria com uma cesta
desatualizada. Escreva-o em `~/gcp/errlog.py`:

```python
# errlog.py
"""errlog.py: an exception, written as one entry Error Reporting can group.

The whole traceback goes in the entry's message, in one JSON line, with the
service's name and version beside it.
"""
import json
import traceback


def price_of(product):
    prices = {"p-001": 2490, "p-002": 1890}
    return prices[product]


def report(exc):
    entry = {
        "severity": "ERROR",
        "message": "".join(traceback.format_exception(exc)),
        "@type": "type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent",
        "serviceContext": {"service": "shop-api", "version": "a1b2c3d"},
    }
    print(json.dumps(entry))


for product in ["p-001", "p-003", "p-004"]:
    try:
        price_of(product)
    except KeyError as exc:
        report(exc)
```

```
ana@laptop:~/gcp$ python3 errlog.py | wc -l
2
ana@laptop:~/gcp$ python3 errlog.py | jq -rs '.[0].message'
Traceback (most recent call last):
  File "/home/ana/gcp/errlog.py", line 28, in <module>
    price_of(product)
  File "/home/ana/gcp/errlog.py", line 13, in price_of
    return prices[product]
           ~~~~~~^^^^^^^^^
KeyError: 'p-003'
```

Duas linhas para duas falhas: cada traceback, com as quebras de linha, está dentro de uma string JSON, então
chega como uma entrada. Impressa com `traceback.print_exc()`, a primeira falha sozinha seriam sete entradas de
texto puro sem severidade, e o Error Reporting não veria nenhuma.

## Agrupando, à mão

O Error Reporting agrupa pelo stack trace: o tipo da exceção e os frames por onde ela passou, não os valores na
mensagem. Agrupando as duas entradas do mesmo jeito:

```
ana@laptop:~/gcp$ python3 errlog.py | jq -r '.message | split("\n") | map(select(startswith("  File"))) | join(" > ")' | sort | uniq -c
      2   File "/home/ana/gcp/errlog.py", line 28, in <module> >   File "/home/ana/gcp/errlog.py", line 13, in price_of
ana@laptop:~/gcp$ python3 errlog.py | jq -r '.message | split("\n") | map(select(length > 0)) | last'
KeyError: 'p-003'
KeyError: 'p-004'
```

Uma pilha, contada duas vezes: o Error Reporting mostraria **um grupo com duas ocorrências**, com a última
linha, `KeyError: 'p-003'`, como amostra, e o outro produto só na lista de ocorrências. Esse é o ponto do
agrupamento e também o limite dele: dois produtos faltando diferentes são um bug, com razão; mas um stack trace
que muda porque o código andou uma linha (um release novo) pode abrir um grupo novo para o mesmo bug, e por isso
o grupo mostra a versão do `serviceContext` que o relatou primeiro.

## O que um grupo faz

- **Notifica uma vez, quando é novo.** Um grupo visto pela primeira vez, ou visto de novo depois de marcado como
  resolvido, manda uma notificação aos canais do projeto. Um grupo que continua acontecendo não manda mais nada,
  por mais que aconteça.
- **Pode ser silenciado ou resolvido.** Resolvido e visto de novo é uma regressão, e reabre.
- **Liga de volta às entradas** no Cloud Logging, e de uma entrada que traz o campo de trace (lição 9), ao trace.

A única coisa que ele não é: um alerta sobre uma taxa. Um grupo que foi de três ocorrências por hora para três
mil parece o mesmo na lista, com um número maior. Essa pergunta pertence a um contador baseado em log de
severidade `ERROR` e a um alerta sobre ele (lições 10 e 14).
