---
title: Estado versus histórico
version: 1
---

**A maioria dos programas guarda o estado atual e joga fora o caminho até ele; o event sourcing
guarda o caminho e trata o estado atual como algo a calcular.** Toda mudança vira um evento, um fato
no passado, acrescentado a uma lista que nunca é editada. O estado de um membro, de um empréstimo
ou de uma estante em qualquer momento é a soma desses eventos.

A ideia com que as pessoas chegam é que um log de eventos é uma trilha de auditoria, guardada ao
lado dos dados de verdade para o caso de alguém perguntar. No event sourcing o log *são* os dados de
verdade. Não existe tabela de saldos para discordar dele; um saldo mostrado numa tela foi calculado a
partir dos eventos há um instante, e pode ser calculado de novo.

Crie `~/patterns/events` e trabalhe nele durante a lição inteira:

```sh
mkdir -p ~/patterns/events
cd ~/patterns/events
```

## Um saldo sem memória

Aqui está o saldo de multas de um membro guardado do jeito de sempre, e as mesmas quatro mudanças
guardadas como histórico:

```python
# state_only.py
balance = {"bia": 0}

balance["bia"] += 150   # a late return
balance["bia"] += 250   # another one
balance["bia"] -= 100   # she pays at the desk
balance["bia"] += 50    # a correction nobody wrote down
print("state:", balance)

history = [
    ("2026-03-19", "CopyReturned", {"member": "bia", "copy": "C3", "fine": 150}),
    ("2026-03-23", "CopyReturned", {"member": "bia", "copy": "C1", "fine": 250}),
    ("2026-03-24", "FinePaid", {"member": "bia", "amount": 100}),
    ("2026-03-25", "FineCorrected", {"member": "bia", "amount": 50, "reason": "wrong due date on C1"}),
]
effect = {"CopyReturned": lambda d: d["fine"],
          "FinePaid": lambda d: -d["amount"],
          "FineCorrected": lambda d: d["amount"]}
owed = 0
for day, kind, data in history:
    owed += effect[kind](data)
    print(f"{day}  {kind:<13} owed {owed:>3}  {data}")
```

```
ana@laptop:~/patterns/events$ python3 state_only.py
state: {'bia': 350}
2026-03-19  CopyReturned  owed 150  {'member': 'bia', 'copy': 'C3', 'fine': 150}
2026-03-23  CopyReturned  owed 400  {'member': 'bia', 'copy': 'C1', 'fine': 250}
2026-03-24  FinePaid      owed 300  {'member': 'bia', 'amount': 100}
2026-03-25  FineCorrected owed 350  {'member': 'bia', 'amount': 50, 'reason': 'wrong due date on C1'}
```

As duas metades concordam: a Bia deve 350 centavos. Só uma delas sabe dizer por quê. A primeira
metade tem um número e quatro comentários que só existem no arquivo-fonte; em tempo de execução a
biblioteca sabe 350 e mais nada. Quando a Bia vai ao balcão e pergunta por que deve três reais e
cinquenta, a resposta honesta é "o computador diz que sim". A segunda metade responde linha por
linha: duas devoluções atrasadas, um pagamento, e uma correção feita em 25 de março porque o C1
estava com o vencimento errado.

## O que o histórico compra

**Perguntas em que ninguém pensou quando o código foi escrito.** "Quanto os membros pagaram de multa
em março?" é uma soma sobre eventos `FinePaid`. Só com saldos, isso nunca foi registrado, e nenhum
código posterior consegue recuperar.

**O estado em qualquer momento.** Pare de somar em 24 de março e o histórico diz que ela devia 300
naquele dia. Uma tabela de saldos atuais sobrescreveu esse número para sempre.

**Correções que continuam visíveis.** A correção de 50 centavos é um evento próprio, com um motivo.
Consertar um saldo no lugar apagaria o erro e o conserto juntos, e a próxima pessoa a olhar veria um
número sem história.

É assim que contadores trabalham há séculos, e a comparação é exata: um livro-razão só recebe
lançamentos novos, um lançamento errado é corrigido por outro lançamento, e o saldo é a soma das
linhas. A lição 8 já fazia o modelo de escrita publicar eventos; o event sourcing guarda esses
eventos como o único registro. O resto desta lição constrói o que isso exige: um store que recusa
edições, um jeito de reconstruir o estado, modelos de leitura alimentados pelo histórico, e um plano
para o dia em que os eventos precisarem mudar de forma.
