---
title: "A imutabilidade ajuda: o que não muda não precisa de trava"
version: 1
---

**Toda corrida desta lição precisou de estado compartilhado e escrito. Tire a escrita e não sobra
nada sobre o que correr.** Um objeto que não muda depois de construído pode ser lido por qualquer
número de threads ao mesmo tempo, sem trava e sem cuidado, porque todo leitor vê a mesma coisa
enquanto o objeto existir. A lição 15 defendeu a imutabilidade como um jeito de raciocinar sobre o
código; com threads ela vira um jeito de continuar correto.

O que muda, em vez disso, é *qual* objeto é o atual. Uma atualização constrói um valor novo e troca
uma referência para apontar para ele. Um leitor que pegou a referência antiga fica com um valor
antigo completo e coerente; um leitor que chega depois pega o novo completo. Ninguém consegue ver
metade de cada.

## Uma leitura rasgada, e uma limpa

As regras de multa da biblioteca têm dois números: centavos por dia e dias de carência. Esta noite
elas mudam de 50 centavos sem carência para 100 centavos com dois dias de carência. Um balcão
calcula uma multa enquanto a mudança acontece. O programa faz isso duas vezes, uma com um dicionário
mutável e outra com uma dataclass congelada, e para o leitor no pior momento de propósito.

```schooling-example
{"language": "python", "file": "rules.py", "parts": [
 {"code": "# rules.py\nimport dataclasses\nimport threading\nfrom dataclasses import dataclass\n\n\n@dataclass(frozen=True)\nclass FineRules:\n    daily_cents: int\n    grace_days: int\n\n\ndef fine(rules: FineRules, days_late: int) -> int:\n    return max(days_late - rules.grace_days, 0) * rules.daily_cents", "note": "`frozen=True` faz a dataclass recusar atribuições depois de construída. As regras são um valor, como na lição 12."},
 {"code": "\nmutable = {\"daily_cents\": 50, \"grace_days\": 0}\ncurrent = FineRules(daily_cents=50, grace_days=0)\nhalfway = threading.Event()\nread_done = threading.Event()", "note": "Dois lugares onde as regras moram: um dicionário mudado campo a campo e uma referência para um objeto congelado. Os dois eventos deixam a thread principal ler exatamente no meio de uma atualização."},
 {"code": "\ndef update_mutable() -> None:\n    mutable[\"daily_cents\"] = 100\n    halfway.set()\n    read_done.wait()\n    mutable[\"grace_days\"] = 2", "note": "Atualizar o dicionário leva duas escritas, e um leitor pode chegar entre elas."},
 {"code": "\ndef update_frozen() -> None:\n    global current\n    new = FineRules(daily_cents=100, grace_days=2)\n    halfway.set()\n    read_done.wait()\n    current = new", "note": "Atualizar as regras congeladas constrói o valor novo inteiro primeiro e depois muda uma referência. O leitor chega no mesmo ponto: depois do trabalho, antes da troca."},
 {"code": "\ndef show(label: str, rules: FineRules) -> None:\n    print(f\"{label:<8} {rules.daily_cents} cents a day, {rules.grace_days} days' grace,\"\n          f\" 3 days late costs {fine(rules, 3)}\")\n\n\ndef demo(label: str, update, snapshot) -> None:\n    halfway.clear()\n    read_done.clear()\n    writer = threading.Thread(target=update)\n    writer.start()\n    halfway.wait()\n    show(label, snapshot())\n    read_done.set()\n    writer.join()", "note": "`demo` inicia quem escreve, lê quando ele está no meio e depois o deixa terminar. `snapshot` diz como cada versão lê suas regras."},
 {"code": "\nif __name__ == \"__main__\":\n    print(\"old: 50 cents, no grace -> new: 100 cents, 2 days' grace\")\n    demo(\"mutable\", update_mutable, lambda: FineRules(**mutable))\n    demo(\"frozen\", update_frozen, lambda: current)\n    show(\"after\", current)\n    try:\n        current.daily_cents = 0\n    except dataclasses.FrozenInstanceError as err:\n        print(\"refused:\", err)", "note": "As duas versões, as regras congeladas depois de feita a troca e uma tentativa de mudar um objeto congelado no lugar."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 rules.py
old: 50 cents, no grace -> new: 100 cents, 2 days' grace
mutable  100 cents a day, 0 days' grace, 3 days late costs 300
frozen   50 cents a day, 0 days' grace, 3 days late costs 150
after    100 cents a day, 2 days' grace, 3 days late costs 100
refused: cannot assign to field 'daily_cents'
```

Leia a segunda linha com atenção. O leitor mutável viu o preço novo com a carência antiga, e cobrou
300 centavos por três dias de atraso. Pelas regras antigas essa multa era 150; pelas novas, 100.
**O leitor calculou uma multa a partir de um conjunto de regras que ninguém nunca configurou.** Isso
é uma leitura rasgada (*torn read*), e uma trava em volta das duas escritas e da leitura a
corrigiria, ao preço de todo leitor pegar a trava.

O leitor congelado viu as regras antigas, inteiras, e cobrou 150. Um instante depois a referência
apontava para as regras novas, inteiras, e a multa era 100. Nenhuma trava foi pega em lugar
nenhum. A última linha é a garantia que torna isso seguro: ninguém consegue mudar esses campos
depois de o objeto ser construído, nem por acidente em algum outro módulo.

## A regra por trás, e as letras miúdas

**Compartilhe o que é imutável; confine o que é mutável.** Confinado quer dizer pertencente a
exatamente uma thread, a única que mexe nele; as outras threads mandam mensagens para ela. Essa
segunda metade é o modelo de atores da lição 17, e `queue.Queue` é o jeito pronto do Python de
passar a posse de um valor de uma thread para outra.

Duas letras miúdas. Primeiro, trocar a referência é seguro no CPython porque atribuir uma variável
global é um passo único que nenhuma thread consegue ver pela metade. O mesmo movimento em outras
linguagens precisa de uma palavra para ele:

| linguagem | como um valor imutável novo é publicado para outras threads |
|---|---|
| Python | atribuição simples da referência |
| Java | um campo `volatile` ou uma `AtomicReference`; um campo comum pode nunca ser visto por outra thread |
| Go | `atomic.Pointer[T]`, ou um mutex; `go test -race` relata uma escrita e uma leitura comuns |
| TypeScript | não é preciso num único event loop; entre workers, uma mensagem com uma cópia do valor |

Segundo, *congelado* só vai até a profundidade dos campos. Uma dataclass congelada que guarda uma
`list` impede você de trocar a lista e deixa qualquer um fazer append nela. Use tuplas e outros
objetos congelados até o fim, como a lição 15 fez, ou a trava que você evitou volta pela porta dos
fundos.

A imutabilidade não remove toda corrida. Uma troca baseada no que você leu, *ler as regras, somar
um dia de carência, publicar*, é ler-modificar-escrever de novo, e duas threads fazendo isso ao
mesmo tempo perdem uma atualização exatamente como `race.py` perdeu. Quem escreve ainda precisa se
revezar, ou ter um dono único. Quem lê, que costuma ser a maioria, não precisa de nada.
