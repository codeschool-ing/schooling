---
title: Duas direções de escalonamento
version: 1
---

A aula 1 escreveu um dos seus requisitos para esta aula: **o token de um cliente não lê a reserva de
outro cliente**. É o requisito sobre o qual mais perguntam a um testador, porque o defeito por trás
dele é o defeito grave mais comum da web, e porque nenhum scanner o encontra. Antes de testá-lo, duas
palavras precisam ficar separadas, já que as pessoas as usam como se fossem uma.

**Autenticação** responde *quem é você?* Uma senha conferida contra o seu hash, um token encontrado
na tabela de sessões. **Autorização** responde *você pode fazer isto?* — e a pergunta é feita de novo
a cada requisição, sobre uma coisa específica. O `account.py` faz a primeira em `who` e a segunda nas
duas linhas marcadas `# owner check` e `# role check`. Um sistema pode autenticar perfeitamente e
ainda deixar todo mundo ler tudo, que é exatamente o que faz a bilheteria da aula 1. A aula 8 de
`security-fundamentals` é o lugar para aprofundar a diferença.

## Para o lado e para cima

Quando a autorização falha, alguém ganha um privilégio que nunca recebeu, e a falha tem uma direção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l17-escalation\" aria-label=\"Dois papéis desenhados como dois níveis. No de baixo, duas clientes, ana e bia, cada uma com a sua reserva. No de cima, a equipe, com a lista de todas as reservas. Uma seta para o lado, de bia até a reserva de ana, é escalonamento horizontal: o mesmo papel, dados de outra pessoa, testado pela verificação de dono do account.py. Uma seta para cima, de ana até a lista da equipe, é escalonamento vertical: um papel que ela não tem, testado pela verificação de papel. As duas setas têm de terminar numa recusa.\"><defs><marker id=\"l17-escalation-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">duas direções, uma regra: a resposta é uma recusa</text><rect x=\"40.0\" y=\"50.0\" width=\"640.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"56.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">equipe</text><rect x=\"40.0\" y=\"160.0\" width=\"640.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"56.0\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">cliente</text><rect x=\"140.0\" y=\"70.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/staff/bookings</text><rect x=\"110.0\" y=\"190.0\" width=\"90.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"155.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ana</text><rect x=\"220.0\" y=\"190.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reserva 1</text><rect x=\"500.0\" y=\"190.0\" width=\"90.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"545.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">bia</text><path d=\"M500.0 207.0 L334.0 207.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#l17-escalation-nf-ah-amber)\"></path><text x=\"417.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">horizontal</text><text x=\"417.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dono: 404</text><path d=\"M155.0 190.0 L155.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#l17-escalation-nf-ah-amber)\"></path><text x=\"166.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">vertical</text><text x=\"236.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">papel: 403</text></svg>", "caption": "O escalonamento horizontal alcança os dados de outro cliente; o vertical alcança um papel. Cada um é uma sonda com duas contas.", "same": ["horizontal", "vertical"]}
```

- **Escalonamento horizontal** é alcançar para o lado: um cliente lendo, alterando ou cancelando a
  reserva de outro cliente. O mesmo papel, os dados de outra pessoa. Em geral vem de uma rota que
  busca um registro pelo id e nunca pergunta de quem ele é, e o teste habitual é o que você vai
  mandar agora: uma segunda conta pedindo o registro da primeira.
- **Escalonamento vertical** é alcançar para cima: um cliente fazendo o que só a equipe pode fazer,
  como listar todas as reservas. Os mesmos dados, um papel que ele não tem. Em geral vem de uma
  página da equipe que apenas não tem link nas telas do cliente, como se um link ausente fosse uma
  fechadura.

Os dois se testam do mesmo jeito: **duas contas, uma requisição, e uma resposta que tem de ser uma
recusa.**

## Horizontal: dois clientes

Cadastre três clientes com o mesmo pedido `/register` da aula 16: `ana`, `bia`, e `sam` para depois.
Faça o login das duas primeiras, guardando cada token num arquivo com o nome da dona, reserve um
assento como `ana` e peça essa reserva com o token de `bia`:

```
ana@nft:~/boxoffice$ for n in ana bia sam; do curl -s -X POST localhost:8001/register -d "{\"name\": \"$n\", \"password\": \"correct horse battery\"}"; done
{"ok": true}
{"ok": true}
{"ok": true}
ana@nft:~/boxoffice$ for n in ana bia; do curl -s -X POST localhost:8001/login -d "{\"name\": \"$n\", \"password\": \"correct horse battery\"}" | jq -r .token > ~/$n.token; done
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/bookings -H "Authorization: Bearer $(cat ~/ana.token)" -d '{"show_id": 990, "seat": 12, "holder": "Ana Lima"}'
{"id": 1}
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/bia.token)"
{"error": "no such booking"}
404
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/2 -H "Authorization: Bearer $(cat ~/bia.token)"
{"error": "no such booking"}
404
```

`bia` é recusada na reserva 1, que é de `ana`, com um `404`. Ela também é recusada na reserva 2, que
não existe, **com exatamente a mesma resposta.** Isso é proposital: um `403` para uma e um `404` para
a outra diria a um estranho quais números de reserva estão em uso, e quantas pessoas reservaram. Uma
recusa que parece ausência é uma escolha comum e razoável; um `403` para as duas é a outra. O que um
teste não pode aceitar é um `200`.

## Vertical: um cliente e alguém da equipe

`/staff/bookings` lista todas as reservas, e só uma conta com o papel `staff` pode lê-la. Não existe
rota que conceda o papel, de propósito: tornar alguém equipe é feito no banco, por quem opera o
serviço, que aqui é você. Peça como `ana`, depois promova `sam` e peça como ele:

```
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/staff/bookings -H "Authorization: Bearer $(cat ~/ana.token)"
{"error": "staff only"}
403
ana@nft:~/boxoffice$ sqlite3 data/account.db "UPDATE accounts SET role = 'staff' WHERE name = 'sam'"
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/login -d '{"name": "sam", "password": "correct horse battery"}' | jq -r .token > ~/sam.token
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/staff/bookings -H "Authorization: Bearer $(cat ~/sam.token)"
[{"id": 1, "owner": 1, "show_id": 990, "seat": 12}]
200
```

O `403` é a recusa; o `200` é o controle. Sem o controle, uma rota da equipe quebrada para todo mundo
passaria num teste que só conferisse que os clientes são recusados.

As duas recusas também chegaram ao log do serviço, com a conta que pediu:

```
2026-10-10 16:35:38,308 WARNING refused GET /bookings/1 to account 2: no such booking
2026-10-10 16:35:38,364 WARNING refused GET /staff/bookings to account 1: staff only
```

**Um cliente pedindo reserva após reserva que não é dele é o rastro visível de alguém procurando um
escalonamento horizontal**, e ele aparece aqui em vez de em lugar nenhum. A aula 19 volta ao que uma
linha de log precisa levar para ser útil.
