---
title: Limites de taxa, novas tentativas e lotes
version: 1
---

A API de toda ferramenta de operação limita a velocidade com que pode ser chamada, para se proteger
exatamente do que uma sincronização faz: milhares de requisições seguidas. O CRM de mentira permite dez
por segundo. Mais rápido que isso, ele responde `429 Too Many Requests` com um cabeçalho `Retry-After`.
Salve isto como `burst.sh`; ele manda trinta requisições tão rápido quanto o `curl` consegue:

```sh
for i in $(seq 30); do
  curl -s -o /dev/null -w '%{http_code}\n' -X PUT localhost:8000/contacts/lantern-10 \
    -H 'Content-Type: application/json' -d '{"health": "lapsed"}'
done | sort | uniq -c
```

```
ana@vm:~/reverse$ bash burst.sh
      9 200
     21 429
```

Algumas aceitas, o resto recusado — quantas de cada depende da velocidade com que a sua máquina as
manda. Uma sincronização que tratasse `429` como falha marcaria esses contatos como falhos e deixaria o
CRM pela metade. O `send` do script o trata como **"ainda não"**: espera o segundo que o cabeçalho pede
e tenta de novo, até cinco vezes.

Três hábitos fazem de uma sincronização uma boa vizinha da API de outra pessoa:

- **Respeite o limite que a API declara**, e o `Retry-After` dela. Tentar de novo na hora faz a recusa
  durar mais.
- **Tente de novo o que pode dar certo depois, e só isso.** `429` e um erro do servidor (`5xx`) podem
  dar certo daqui a um minuto. Um `400` — a própria requisição está errada — vai falhar igual toda vez;
  a próxima seção é sobre eles.
- **Mande em lote onde a API permitir.** CRMs reais aceitam cem ou mil registros numa requisição, e as
  ferramentas comerciais da aula 8 usam esses endpoints em lote. Uma requisição por contato, como aqui,
  é o que faz a primeira sincronização levar minutos; é também o que deixa esta legível.
