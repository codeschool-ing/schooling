---
title: O que o SDK manda sem pedir
version: 1
---

Olhe de novo o frame de `checkout` acima: **`"card": "'4111 1111 1111 1111'"`**. Ninguém escreveu o
número do cartão no evento. O SDK recolhe toda variável local de todo frame por padrão, porque é isso
que torna o evento útil, e o número do cartão era uma variável local.

É o vazamento da aula 10 por outro caminho. Lá o número do cartão chegou aos logs porque uma linha
de depuração registrou um objeto inteiro. Aqui ele chega aos servidores de um terceiro porque uma
exceção aconteceu numa função que o tinha no escopo. **O padrão de um rastreador de erros é mandar
mais do que você pensaria em escrever.** O SDK limpa alguns nomes por padrão, `password`, `token`,
`authorization`, `cookie` e uns trinta outros no total, e troca os valores deles por `[Filtered]`.
`card` não está na lista, e nenhum nome que o seu próprio código inventou está.

A correção tem a forma da da aula 10: uma lista de nomes cujos valores são segredos, aplicada antes de
qualquer coisa sair. Aqui é um argumento do `init`:

```
ana@obs:~/shop$ sed -n '/^sentry_sdk.init/,/^)/p' scratch/tracked.py
sentry_sdk.init(
    dsn="https://key@errors.example.invalid/1",
    transport=ToFile,
    release="shop@1.4.0",
    environment="lab",
    event_scrubber=EventScrubber(denylist=DEFAULT_DENYLIST + ["card"]),
)
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python tracked.py 2>&1 | tail -2
INFO:checkout:pricing kettle x 2
INFO:checkout:applying coupon WELCOME20
ana@obs:~/shop$ jq '.exception.values[0].stacktrace.frames[] | select(.function == "checkout") | .vars' scratch/event.json
{
  "sku": "'kettle'",
  "qty": "2",
  "card": "[Filtered]",
  "coupon": "'WELCOME20'",
  "total_cents": "9800"
}
```

Três hábitos evitam que isso seja uma lista que alguém lembra de aumentar:

- **Limpe na saída, e de novo na chegada.** Os produtos também limpam no servidor, por padrão de
  texto, e têm opções para descartar as variáveis locais por inteiro. Use os dois; a lista do SDK
  protege a rede e a cópia do fornecedor, e a lista do servidor pega o que a do SDK deixou passar.
- **Mantenha o `send_default_pii` desligado**, como ele vem por padrão. Ligado, ele acrescenta o
  endereço IP do usuário, cookies e cabeçalhos da requisição a todo evento, e cookies de sessão estão na lista da aula 10
  das coisas que nunca se escrevem.
- **Trate o fornecedor como um lugar para onde os dados vão.** Um evento guardado numa região do
  fornecedor no exterior é uma transferência de dados pessoais pela LGPD, com as obrigações que vêm
  com ela. A maioria dos produtos oferece uma região europeia ou local e um contrato para ela, e a
  escolha pertence à avaliação, não ao incidente.
