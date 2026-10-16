---
title: Lendo um segredo no código, e com que frequência
version: 1
---

A API da loja lê as credenciais do banco quando precisa de uma conexão. Perguntar ao Secrets Manager toda
vez custa uma chamada toda vez, e uma chamada tem preço, latência e cota. **Perguntar uma vez e guardar a
resposta por alguns minutos** custa quase nada e ainda pega uma senha nova dentro desses minutos. É o que
este módulo faz, em `dbconfig.py`:

```python
# dbconfig.py: the database credentials, read from Secrets Manager and kept for a while
import json
import time

import boto3

client = boto3.client("secretsmanager")
cache = {"value": None, "at": 0.0}
calls = 0


def db_credentials(max_age=300):
    global calls
    if cache["value"] is None or time.monotonic() - cache["at"] > max_age:
        raw = client.get_secret_value(SecretId="shop/prod/db")["SecretString"]
        cache["value"], cache["at"] = json.loads(raw), time.monotonic()
        calls += 1
    return cache["value"]
```

`max_age` é de cinco minutos em produção. Um programa para vê-lo funcionar, `cache-demo.py`, o põe em
dois segundos, muda o segredo no meio, e imprime uma **impressão digital** da senha em vez da senha, os
primeiros caracteres do SHA-256 dela, que é o que uma linha de log sobre um segredo deve levar:

```python
# cache-demo.py: three reads, one change, and how many reached Secrets Manager
import hashlib
import json
import time

import boto3

import dbconfig


def fingerprint(creds):
    return hashlib.sha256(creds["password"].encode()).hexdigest()[:8]


print("first read ", fingerprint(dbconfig.db_credentials(max_age=2)))
new = {"username": "shop", "password": "third-pass"}
boto3.client("secretsmanager").put_secret_value(SecretId="shop/prod/db", SecretString=json.dumps(new))
print("just after ", fingerprint(dbconfig.db_credentials(max_age=2)))
time.sleep(3)
print("3 s later  ", fingerprint(dbconfig.db_credentials(max_age=2)))
print("calls:", dbconfig.calls)
```

```
ana@laptop:~/aws/secrets$ python3 cache-demo.py
first read  0c4368d9
just after  0c4368d9
3 s later   7cb5cd66
calls: 2
```

A leitura logo depois da mudança ainda devolve a senha antiga, do cache; três segundos depois o cache
venceu e a nova chega. Três leituras, duas chamadas. **Nesses segundos as duas senhas precisam
funcionar**, e é exatamente por isso que a rotação mantém `AWSPREVIOUS` válida até terminar: o banco
aceita a senha antiga enquanto toda cópia do programa em execução alcança a nova.

## Quanto vale o cache

A API da loja roda 20 contêineres. Ler a cada requisição, a 50 milhões de requisições por mês, são 50
milhões de chamadas: **250 USD por mês** a 5 centavos por 10.000. Com um cache de cinco minutos, cada
contêiner pergunta doze vezes por hora: 20 × 12 × 24 × 30 = 172.800 chamadas, **menos de 0,87 USD**. O
segredo em si custa 0,40.

Mais três hábitos mantêm os segredos no lugar:

- **nunca numa variável de ambiente embutida numa imagem** ou numa task definition em texto puro; o ECS e
  o Lambda injetam um segredo de qualquer dos dois cofres pelo ARN na partida, o que o mantém fora do
  arquivo;
- **nunca numa linha de log**, e é por isso que o demo imprimiu uma impressão digital, e nunca numa
  mensagem de exceção, que é por onde eles costumam vazar;
- **uma conexão que falha com a senha em cache lê de novo na hora** antes de falhar, para uma rotação que
  terminou há um minuto não esperar os cinco minutos.
