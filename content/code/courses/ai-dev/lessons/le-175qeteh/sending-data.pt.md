---
title: O que sai junto com a requisição
version: 1
---

A aula 10 perguntou para onde os dados vão. Esta seção trata do que vai: **clientes põem em e-mails
coisas de que o modelo não precisa**, e um programa que repassa o e-mail repassa tudo.

```
Hi, the payment failed at checkout with code E1042. My card is 4111 1111 1111 1111
and my CPF is 123.456.789-09, in case you need them. Reply to marta@example.com.
```

## Mandado como veio

```
ana@dev:~/shop$ python triage.py data/emails/3.txt
The checkout code E1042 means the payment timed out and no money was taken. The customer can try again in a minute.
ana@dev:~/shop$ tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; print(json.load(sys.stdin)["request"]["messages"][0]["content"])'
Hi, the payment failed at checkout with code E1042. My card is 4111 1111 1111 1111
and my CPF is 123.456.789-09, in case you need them. Reply to marta@example.com.

```

A resposta está certa, e **o provedor agora guarda um número de cartão, um CPF e um endereço de
e-mail** que não tiveram papel nenhum nela. O segundo comando imprime a requisição como o labllm a
recebeu, que é o que qualquer provedor recebe.

## Tirando o que o modelo não precisa

```python
"""Remove what the model does not need before a request leaves the shop."""
import re

PATTERNS = [
    ("EMAIL", re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")),
    ("CPF", re.compile(r"\b\d{3}\.\d{3}\.\d{3}-\d{2}\b")),
    ("CARD", re.compile(r"\b(?:\d[ -]?){13,19}\b")),
    ("SECRET", re.compile(r"(?i)\b(token|secret|password|api_key)\s*[=:]\s*\S{8,}")),
]


def redact(text):
    for label, pattern in PATTERNS:
        text = pattern.sub(f"[{label}]", text)
    return text
```

```
ana@dev:~/shop$ python triage.py data/emails/3.txt --redact
The checkout code E1042 means the payment timed out and no money was taken. The customer can try again in a minute.
ana@dev:~/shop$ tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; print(json.load(sys.stdin)["request"]["messages"][0]["content"])'
Hi, the payment failed at checkout with code E1042. My card is [CARD]
and my CPF is [CPF], in case you need them. Reply to [EMAIL].
```

**A mesma resposta, e nenhum dos três saiu da loja.** O modelo precisava do código de erro e da
palavra "payment"; recebeu os dois. Os dados são trocados por rótulos, então o modelo ainda sabe que
um cartão foi mencionado e pode dizer isso numa resposta, sem o número.

## O que um padrão consegue e não consegue fazer

- **Ele pega formatos, não significado.** Um número de cartão escrito com pontos, um CPF sem
  pontuação, um endereço escrito por extenso passam. Teste os padrões em mensagens reais, e
  acrescente os que escapam.
- **Ele pode pegar demais.** O padrão de cartão também casa qualquer sequência de 13 a 19 dígitos,
  como um código de rastreio longo. Decida qual erro é pior para a tarefa, e teste esse.
- **Guarde os valores reais do seu lado.** A resposta ainda precisa chegar a `[EMAIL]`. O programa
  que a manda usa o endereço que já tinha; o modelo nunca precisou dele.
- **Segredos também são dados pessoais.** O padrão `SECRET` é o que o assistente da aula 3 usou, pelo
  mesmo motivo: uma chave colada numa mensagem de suporte não pode ir adiante.
