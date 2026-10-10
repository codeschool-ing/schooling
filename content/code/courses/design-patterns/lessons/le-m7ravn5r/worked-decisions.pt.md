---
title: Três decisões da biblioteca, argumentadas
version: 1
---

**Uma decisão sobre um padrão é tão boa quanto a força que ela nomeia e o custo que ela admite.**
Esta seção pega três pedidos que a biblioteca poderia mesmo fazer e argumenta cada um até o fim: a
força numa frase, os candidatos, o que cada um custaria e a escolha. Em todos os casos a resposta é
menor que o candidato mais impressionante, e o argumento diz o que mudaria isso.

## Caso 1: multas que variam por categoria e por tipo de item

*A força.* Estudantes agora pagam 25 centavos por dia e funcionários não pagam nada; uma categoria
de idosos chega no próximo semestre, a 25 centavos. À parte, os filmes devem ser multados no máximo
pelo preço do filme, porque um DVD que custa 12 reais não deveria acumular uma multa de 15.

*Os candidatos.* Uma classe strategy por categoria, escolhida por uma factory; um dicionário de
taxas; um dicionário de funções.

*O argumento.* As duas forças são de natureza diferente, e tratá-las como uma só é como a versão em
camadas das seções anteriores aconteceu. A categoria muda **um número**, então pertence aos dados,
onde uma categoria nova é uma linha e nenhum código novo. O tipo de item muda **um cálculo**, então
precisa de código, e vale o argumento da lição 15: em Python uma função já é um objeto que dá para
guardar num dicionário, então o padrão strategy é um dicionário de funções.

```schooling-example
{"language": "python", "file": "policies.py", "parts": [
 {"code": "# policies.py\nfrom typing import Callable\n\nDAILY_CENTS = {\"adult\": 50, \"student\": 25, \"staff\": 0, \"senior\": 25}", "note": "A categoria é dado. A categoria de idosos foi uma linha, e a próxima também será."},
 {"code": "\ndef daily(category: str, days_late: int, price: int) -> int:\n    return max(days_late, 0) * DAILY_CENTS[category]\n\n\ndef capped(category: str, days_late: int, price: int) -> int:\n    return min(daily(category, days_late, price), price)", "note": "O tipo de item é código: duas funções com a mesma assinatura. `daily` ignora `price`, que é o pequeno custo de pôr as duas numa família."},
 {"code": "\nRULES: dict[str, Callable[[str, int, int], int]] = {\"book\": daily, \"film\": capped}\n\n\ndef fine(kind: str, category: str, days_late: int, price: int) -> int:\n    return RULES[kind](category, days_late, price)", "note": "A strategy na sua forma mínima: um dicionário de tipo para função, e uma função que o consulta."},
 {"code": "\nif __name__ == \"__main__\":\n    cases = [(\"book\", \"adult\", 10, 4990), (\"book\", \"student\", 10, 4990),\n             (\"film\", \"adult\", 30, 1200), (\"book\", \"staff\", 30, 4990)]\n    for kind, category, days, price in cases:\n        print(f\"{kind:<5} {category:<8} {days:>2} days late: {fine(kind, category, days, price):>4} cents\")", "note": "Quatro casos, com preços em centavos: um livro de 49,90 e um filme de 12,00."}
]}
```

```
ana@laptop:~/patterns/choosing$ python3 policies.py
book  adult    10 days late:  500 cents
book  student  10 days late:  250 cents
film  adult    30 days late: 1200 cents
book  staff    30 days late:    0 cents
```

O filme com trinta dias de atraso deveria 1500 centavos e foi limitado ao seu preço, 1200. *A
escolha:* uma tabela para a taxa e um dicionário de funções para a regra. *O que a mudaria:* se uma
regra precisasse de configuração e estado próprios, como uma multa que cresce depois de enviado um
aviso, uma classe pequena por regra começaria a compensar, e o dicionário guardaria instâncias em
vez de funções.

## Caso 2: avisar três partes do sistema que um livro voltou

*A força.* Quando um empréstimo é devolvido, o balcão de multas precisa acertar a multa, o membro
recebe um e-mail e as estatísticas contam a devolução. No ano que vem o balcão de reservas também
vai querer saber.

*Os candidatos.* Três chamadas em sequência dentro de `give_back`; um observer, como uma lista de
ouvintes; um message broker entre processos.

*O argumento.* Três chamadas em sequência fariam o empréstimo saber de e-mail e de estatística, e
cada ouvinte novo obrigaria a editar o empréstimo. Isso é uma força, e é exatamente a
aplicabilidade do observer. Um broker é outra resposta, para outra força: ouvintes em outros
processos, ou eventos que precisam sobreviver a um reinício. Nenhuma das duas é verdade aqui, e um
broker acrescentaria um servidor para manter, um formato para combinar e a defasagem da lição 9.

*A escolha:* uma lista de ouvintes no mesmo processo, com o retrato da lição 18 se houver threads.
*O que a mudaria:* o e-mail virar um serviço separado, ou a exigência de que nenhuma devolução se
perca quando o processo cai. Aí a lista vira uma outbox e uma fila, que é o assunto da lição 7 de
`architecture`.

## Caso 3: provar quando um livro foi devolvido

*A força.* Uma sócia contesta uma multa e diz que devolveu *Vidas Secas* no dia 3. A biblioteca vê
que o empréstimo está fechado e não vê quando, nem quem o fechou.

*Os candidatos.* Event sourcing para empréstimos, como na lição 9; uma tabela só de acréscimo com os
eventos de empréstimo ao lado do estado atual; uma coluna `returned_by` e outra `returned_at`.

*O argumento.* A força é **auditoria**: responder *o que aconteceu, e quando*. Event sourcing
responde, e também faz do log de eventos a fonte da verdade, com fold, snapshots e eventos
versionados para manter. Nada no pedido exige reconstruir o estado a partir do histórico. Duas
colunas resolvem a contestação e perdem a segunda mudança se uma devolução for corrigida um dia.
Uma tabela só de acréscimo responde a toda pergunta desse tipo e deixa o modelo do empréstimo como
está.

*A escolha:* uma tabela `loan_events` só de acréscimo, escrita na mesma transação que a mudança no
empréstimo. *O que a mudaria:* a biblioteca querer reproduzir o histórico em visões novas, como
"quanto duraram os empréstimos em 2025, por filial", com frequência suficiente para o estado atual
deixar de ser o que interessa. É aí que o projeto da lição 9 começa a pagar pelo seu maquinário.

## O que os três têm em comum

Cada decisão nomeou uma força, rejeitou pelo menos uma resposta maior dizendo o custo dela e anotou
o acontecimento que a reabriria. Essa última parte é a mais pulada. Uma escolha com a condição de
reabertura anexada é uma que a próxima pessoa consegue revisitar sem ter de adivinhar por que ela
foi feita, e é isso que a seção 07 transforma num documento.
