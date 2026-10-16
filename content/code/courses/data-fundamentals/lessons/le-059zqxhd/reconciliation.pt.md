---
title: Contando contra a origem
version: 1
---

**As verificações na porta julgam cada linha sozinha. Nenhuma linha consegue dizer se todas as outras
chegaram.** Essa pergunta precisa de uma segunda opinião de fora da cópia: a contagem que a própria
origem faz do que tem. Comparar as duas é **reconciliação**, e é assim que uma linha faltando, que não
deixa rastro nenhum no dado, vira algo que se pode ver. A seção 06 terminou com uma: a entrega do dia 15
tinha as 200 linhas que prometeu, passou em todas as verificações do arquivo, e não continha `R000151`.

O `compare.py`, na seção 05, já era uma. Ele comparou a cópia com a origem chave por chave, e achou
`R000041` faltando onde as duas cópias pareciam saudáveis sozinhas. É o tipo mais completo e o mais caro,
porque precisa de todas as chaves dos dois lados.

## Três níveis, do barato ao completo

| nível | o que se compara | quanto custa | o que escapa |
|---|---|---|---|
| **contagens** | linhas por dia, aqui e na origem | um número por dia vindo da origem | uma linha faltando e outra repetida no mesmo dia |
| **totais de controle** | a soma de uma coluna por dia, como o valor pago | mais um número por dia | uma linha faltando e outra repetida, quando os dois valores são iguais |
| **chaves** | os próprios identificadores | todas as chaves, dos dois lados | nada que falte ou se repita; elas não conferem os valores |

A maioria dos pipelines compara contagens a cada execução, totais a cada execução que envolve dinheiro, e
chaves quando os dois primeiros discordam, para descobrir quais linhas. A entrega do dia 15 caiu
exatamente no ponto cego de uma contagem: uma viagem repetida, uma faltando, e o total ainda 200.

## Uma semana de pagamentos

O provedor de pagamentos envia um extrato todo dia: o id de cada pagamento e o valor dele. A cópia da
Roda Livre da mesma semana tem duas coisas erradas, postas de propósito pelo programa abaixo, que faz os
dois papéis. No dia 17, um pagamento nunca chegou. No dia 19, um pagamento chegou duas vezes e outro
nunca chegou. Os valores ficam em **centavos**, como números inteiros, porque uma soma de valores
escritos como frações decimais pode sair errada por uma fração de centavo, e uma reconciliação que
discorda sem motivo ensina todo mundo a ignorá-la. Salve como `collect/reconcile.py`:

```python
# collect/reconcile.py
import random

random.seed(9)
# the payments provider's statement for a week: (payment id, amount in centavos)
provider = {}
for d in range(15, 22):
    n = random.randint(80, 120)
    provider[f"2025-09-{d}"] = [(f"P{d}{i:03d}", random.choice([450, 600, 900, 1200]))
                                for i in range(n)]

# our copy of the same week, with two things gone wrong
ours = {day: list(payments) for day, payments in provider.items()}
ours["2025-09-17"].pop(12)                         # one payment never arrived
ours["2025-09-19"].append(ours["2025-09-19"][5])   # one arrived twice,
ours["2025-09-19"].pop(30)                         # and another never did


def reais(cents):
    return f"{cents // 100}.{cents % 100:02d}"


print("day          provider          ours              check")
for day in provider:
    pn, ps = len(provider[day]), sum(a for _, a in provider[day])
    on, os_ = len(ours[day]), sum(a for _, a in ours[day])
    check = "ok" if (pn, ps) == (on, os_) else "COUNT" if pn != on else "SUM"
    print(f"{day}   {pn:3} {reais(ps):>9}     {on:3} {reais(os_):>9}     {check}")

# where the totals disagree, the ids say which payment
for day in provider:
    p, o = [i for i, _ in provider[day]], [i for i, _ in ours[day]]
    missing = sorted(set(p) - set(o))
    twice = sorted({i for i in o if o.count(i) > 1})
    if missing or twice:
        print(f"{day}: missing {missing}, twice {twice}")
```

```
ana@lab:~/roda/collect$ python reconcile.py
day          provider          ours              check
2025-09-15   109    804.00     109    804.00     ok
2025-09-16    86    643.50      86    643.50     ok
2025-09-17   106    805.50     105    801.00     COUNT
2025-09-18   114    880.50     114    880.50     ok
2025-09-19   105    826.50     105    822.00     SUM
2025-09-20    84    675.00      84    675.00     ok
2025-09-21    92    705.00      92    705.00     ok
2025-09-17: missing ['P17012'], twice []
2025-09-19: missing ['P19030'], twice ['P19005']
```

O dia 17 falha na contagem: 106 pagamentos no extrato, 105 na cópia. **O dia 19 tem a contagem certa e o
dinheiro errado**: 105 pagamentos dos dois lados, R$ 826,50 contra R$ 822,00. Uma verificação só de
contagens teria deixado passar. As chaves então dizem exatamente o que aconteceu em cada dia, coisa que
os totais nunca conseguiriam: `P19005` duas vezes, `P19030` nenhuma.

## Contra a origem, e no mesmo relógio

Duas regras mantêm uma reconciliação honesta. **O segundo número vem da origem**, nunca do pipeline: uma
contagem que o pipeline calcula a partir da própria cópia concorda com a cópia por construção. Aqui é o
extrato do provedor; para um banco de dados é uma contagem feita numa réplica; para um arquivo entregue é
o número que a origem escreveu ao lado dele, como na seção 06.

E **os dois lados precisam querer dizer a mesma coisa com "um dia"**. Um pagamento feito às 23:50 em
Curitiba já está no dia seguinte em UTC. Por isso, um provedor cujo extrato fecha o dia em UTC discorda
toda noite de uma cópia que o fecha em `America/Sao_Paulo`, exatamente pelos pagamentos feitos nas
últimas três horas do dia local. Acerte o relógio antes de confiar na diferença, como mostrou a quarta-feira de 27
horas da aula 1.
