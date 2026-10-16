---
title: Logs, escritos para uma pessoa e lidos por um programa
version: 1
---

**Um log é uma fonte que ninguém projetou como fonte: linhas escritas para uma pessoa ler de
madrugada, que depois um programa precisa desmontar.** Toda requisição à API da Roda Livre passa por um
servidor web, e o servidor escreve uma linha sobre ela num log de acesso: quem pediu, quando, o quê, e
como foi. Ninguém pensou essas linhas para analytics. Elas existem para que quem está de plantão possa
ler o que aconteceu. Também são o único registro de toda requisição que a API já respondeu, inclusive
as que falharam e não deixaram linha em banco nenhum.

É isso que faz um log valer a leitura. Um banco sabe da viagem que foi encerrada. O log sabe também que
a primeira tentativa de encerrá-la falhou com erro e que o app tentou de novo dois segundos depois.

## Desmontando uma linha

Um servidor web como o nginx escreve, por padrão, num layout chamado combined log format. Uma linha
dele, da API da Roda Livre:

```
203.0.113.7 - - [15/Sep/2025:08:03:11 -0300] "GET /v1/stations/ST02 HTTP/1.1" 200 512 "-" "RodaApp/3.4 (Android 14)"
```

O endereço de onde veio a requisição, dois campos que quase sempre são `-`, o horário com a diferença
para o UTC, a requisição em si, o código de status, o tamanho da resposta em bytes, a página de onde
veio, e o programa que pediu. Nada marca onde um campo termina a não ser espaços, colchetes e aspas,
então um programa o lê com uma **expressão regular**: um padrão que dá nome a cada campo e diz com o que
ele se parece.

Este programa guarda oito linhas de uma manhã de segunda, uma delas quebrada, e as analisa:

```python
# sources/parse_log.py
import re
from collections import Counter

LOG = """\
203.0.113.7 - - [15/Sep/2025:08:03:11 -0300] "GET /v1/stations/ST02 HTTP/1.1" 200 512 "-" "RodaApp/3.4 (Android 14)"
198.51.100.23 - - [15/Sep/2025:08:03:12 -0300] "POST /v1/rides HTTP/1.1" 201 88 "-" "RodaApp/3.4 (iOS 18)"
203.0.113.7 - - [15/Sep/2025:08:03:15 -0300] "GET /v1/stations/ST05 HTTP/1.1" 200 498 "-" "RodaApp/3.4 (Android 14)"
192.0.2.140 - - [15/Sep/2025:08:03:15 -0300] "GET /v1/stations HTTP/1.1" 200 6120 "-" "Mozilla/5.0"
198.51.100.23 - - [15/Sep/2025:08:03:19 -0300] "POST /v1/rides/R000301/end HTTP/1.1" 500 41 "-" "RodaApp/3.4 (iOS 18)"
198.51.100.23 - - [15/Sep/2025:08:03:21 -0300] "POST /v1/rides/R000301/end HTTP/1.1" 200 64 "-" "RodaApp/3.4 (iOS 18)"
203.0.113.9 - - [15/Sep/2025:08:03:2
192.0.2.140 - - [15/Sep/2025:08:03:24 -0300] "GET /v1/stations/ST11 HTTP/1.1" 404 30 "-" "Mozilla/5.0"
"""
LINE = re.compile(r'(?P<ip>\S+) \S+ \S+ \[(?P<time>[^\]]+)\] '
                  r'"(?P<method>\S+) (?P<path>\S+) \S+" (?P<status>\d{3}) (?P<bytes>\d+) '
                  r'"[^"]*" "(?P<agent>[^"]*)"')

parsed, rejected = [], []
for number, line in enumerate(LOG.splitlines(), start=1):
    match = LINE.fullmatch(line)
    if match:
        parsed.append(match.groupdict())
    else:
        rejected.append(number)

print(parsed[0])
print(len(parsed), "lines parsed; rejected line numbers:", rejected)
print("by status:", dict(sorted(Counter(p["status"] for p in parsed).items())))
```

```
ana@lab:~/roda/sources$ python parse_log.py
{'ip': '203.0.113.7', 'time': '15/Sep/2025:08:03:11 -0300', 'method': 'GET', 'path': '/v1/stations/ST02', 'status': '200', 'bytes': '512', 'agent': 'RodaApp/3.4 (Android 14)'}
7 lines parsed; rejected line numbers: [7]
by status: {'200': 4, '201': 1, '404': 1, '500': 1}
```

Todo campo é texto, inclusive o status e o tamanho, porque uma expressão regular acha texto e nada
mais; transformar `"512"` em número e o horário em horário é o passo seguinte, e é outro passo. A linha
7 foi cortada no meio do horário, do jeito que uma linha termina quando um servidor é parado enquanto a
escreve. **O programa diz o número da linha que não conseguiu ler em vez de descartá-la.** Um analisador
que pulasse o que não casa relataria sete requisições como se sete tivessem sido feitas, e no dia em
que o formato do log do servidor mudar, pularia todas as linhas com o mesmo silêncio.

As duas requisições a `/v1/rides/R000301/end` são a nova tentativa: um `500` às 08:03:19 e um `200` dois
segundos depois. Contado de forma ingênua, é uma falha em sete requisições. Contado pelo que o cliente
viveu, é uma viagem que terminou, dois segundos atrasada.

## Duas coisas para pedir

**Logs que já venham em campos.** Muitas aplicações conseguem escrever cada linha como um objeto JSON
em vez de uma frase, um hábito chamado log estruturado. Os campos chegam com nome e a expressão regular
vai embora, junto com o jeito dela de falhar.

**Menos do que está neles.** O primeiro campo de toda linha é um endereço IP, e um endereço pode ser
ligado a uma pessoa. A LGPD trata informação que pode identificar uma pessoa como dado pessoal, com nome
junto ou não. Um log copiado inteiro para a plataforma de dados leva esse dado junto, guardado enquanto
a cópia durar. A aula 7 é sobre coletar só o que a pergunta precisa.
