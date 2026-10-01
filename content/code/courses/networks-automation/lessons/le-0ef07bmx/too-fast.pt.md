---
title: Quando o equipamento diz "rápido demais"
version: 1
---

A API de um equipamento roda no processador do equipamento, o mesmo que roda o roteamento. **Por
isso a maioria das APIs limita a velocidade com que um cliente pode perguntar**, e os roteadores
do laboratório permitem 30 requisições em quaisquer 10 segundos por token. Um script que faz um laço
sobre um equipamento ocupado encontra esse limite mais cedo ou mais tarde.

O que acontece então é `429 Too Many Requests`, com um cabeçalho `Retry-After` dando o número de
segundos a esperar. `Device.request` trata isso: dorme esse tempo e envia a mesma requisição de
novo, no máximo três vezes. Quarenta requisições num laço apertado:

```schooling-example
{
  "language": "python",
  "file": "burst.py",
  "parts": [
    {
      "code": "from devapi import Device\n\ncore1 = Device(\"core1\")"
    },
    {
      "code": "for i in range(40):\n    core1.request(\"GET\", \"/system\")\nprint(\"40 requests answered\")",
      "note": "**Quarenta requisições tão rápido quanto o Python consegue enviar.** O servidor permite 30 a cada 10 segundos, então algumas destas são recusadas e repetidas."
    }
  ]
}
```

```
ana@ctl:~$ time python burst.py
  429 on /system: waiting 8 s
  429 on /system: waiting 1 s
40 requests answered

real	0m11.831s
user	0m0.141s
sys	0m0.012s
```

O servidor recusou em algum ponto depois da trigésima requisição, o cliente esperou o tempo que
mandaram, e as quarenta foram respondidas. A execução inteira levou menos de doze segundos, a
maior parte esperando.

**Esperar é a resposta certa para um 429 e a errada para quase todo o resto.** Um 401 não vai
virar 200 por ser enviado de novo, e um script que tenta de novo para sempre é um script que
esconde o fato de que a senha dele foi trocada. Um 5xx pode valer uma ou duas tentativas com uma
pausa crescente, o que se chama **exponential backoff**, e depois uma falha clara.

Três hábitos evitam que um script chegue a encontrar o limite:

- **Reutilize uma sessão.** `requests.Session` mantém a conexão TCP e TLS aberta entre
  requisições, e fazer login uma vez em vez de a cada requisição economiza o login.
- **Peça o que você precisa.** Uma requisição de uma página de 50 é mais barata para o
  equipamento do que 50 requisições de um item cada.
- **Espalhe o trabalho.** Cinquenta scripts que começam no mesmo minuto são cinquenta clientes
  chegando juntos; um atraso aleatório de alguns segundos no início os distribui.
