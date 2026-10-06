---
title: Ligar uma funcionalidade para alguns clientes
version: 1
---

O arquivo de flags é criado com a funcionalidade a 10%. Nenhum deploy, nenhum reinício: o
`flags.load()` lê o arquivo na próxima requisição.

```
ana@laptop:~/shipquote$ echo '{"delivery_estimate": 10}' > ~/envs/flags.json
ana@laptop:~/shipquote$ for c in c1 c2 c3 c4 c5 c6 c7 c8; do curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=$c"; echo; done
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40", "days": 4}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40", "days": 4}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
ana@laptop:~/shipquote$ for i in $(seq 1000); do curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=800&customer=c$i"; echo; done | grep -c days
110
```

De oito clientes, dois, `c3` e `c5`, agora veem `"days": 4`. Em mil clientes, 110 veem: perto de 10%,
e não exatamente, porque o hash espalha os clientes por igual entre os baldes só na média.

Depois, 50%:

```
ana@laptop:~/shipquote$ echo '{"delivery_estimate": 50}' > ~/envs/flags.json
ana@laptop:~/shipquote$ for i in $(seq 1000); do curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=800&customer=c$i"; echo; done | grep -c days
503
ana@laptop:~/shipquote$ for c in c3 c3 c3; do curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=$c"; echo; done
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40", "days": 4}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40", "days": 4}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40", "days": 4}
```

503 em mil. E o `c3`, perguntado três vezes, recebe a estimativa todas as vezes.

## Duas propriedades que importam

- **O mesmo cliente recebe a mesma resposta.** O balde vem de um hash do id do cliente, não de um
  sorteio a cada requisição. Um cliente que via a estimativa de entrega há um minuto continua vendo;
  um sorteio mostraria e esconderia o campo em atualizações alternadas.
- **Aumentar mantém todo mundo que já estava dentro.** Um cliente está dentro quando o balde dele fica
  abaixo da porcentagem. Ir de 10 para 50 acrescenta os baldes de 10 a 49; os baldes de 0 a 9
  continuam abaixo de 50. Então `c3` e `c5`, dentro a 10%, continuam dentro a 50%, e ninguém que tinha
  a funcionalidade a perde enquanto ela se espalha.

O nome da flag entra no hash junto com o id do cliente. Sem ele, toda flag a 10% escolheria os mesmos
10% de clientes, e esse décimo azarado seria o grupo de teste de todo experimento que a loja fizesse.

## Um canário para uma funcionalidade

Isto é um canário, levado do roteador para dentro do código. A diferença é o que ele isola: o canário
do roteador testa um release inteiro, tudo o que mudou nele; a flag testa uma funcionalidade, seja lá
o que mais o release contenha. Os dois precisam da mesma coisa para servir: uma medição separada pelo
grupo em que o cliente estava, comparada entre os grupos.
