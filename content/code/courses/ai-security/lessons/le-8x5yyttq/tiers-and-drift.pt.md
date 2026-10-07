---
title: Confiança que cresce, e uso que deriva
version: 2
---

Toda verificação desta aula até aqui acontece uma vez, no dia do pedido, e uma empresa não é a mesma
coisa no dia em que pede e seis meses depois. Dois mecanismos levam a decisão adiante no tempo:
**limites que crescem com um histórico limpo**, e **uma comparação entre o que a empresa declarou e o
que ela faz**.

## Tiers

As faixas são um arquivinho próprio:

```sh
cat > ~/guard/data/tiers.json <<'EOF'
{
 "sandbox": {
  "requests_a_day": 100,
  "what": "test data only, no end users"
 },
 "tier-1": {
  "requests_a_day": 5000,
  "needs": "an accepted application"
 },
 "tier-2": {
  "requests_a_day": 50000,
  "needs": "60 days at tier-1 with no incident, and a person reviewing the usage"
 }
}
EOF
```

```
ana@lab:~/guard$ cat data/tiers.json
{
 "sandbox": {
  "requests_a_day": 100,
  "what": "test data only, no end users"
 },
 "tier-1": {
  "requests_a_day": 5000,
  "needs": "an accepted application"
 },
 "tier-2": {
  "requests_a_day": 50000,
  "needs": "60 days at tier-1 with no incident, and a person reviewing the usage"
 }
}
```

Um cliente novo, mesmo aceito, começa com 5.000 requisições por dia, e um cliente em revisão começa no
sandbox com 100 e dados de teste. O passo para 50.000 exige duas coisas: sessenta dias sem incidente, e
uma pessoa olhando o que o cliente de fato fez com o primeiro tier. Os números são do curso, mas o
formato é comum a fornecedores e às plataformas construídas sobre eles: o estrago que uma chave pode
fazer é limitado pelo que ela pode fazer, então uma chave que ninguém conhece ainda pode pouco.

O tier é também a alavanca quando algo dá errado. Um cliente cujo uso está em dúvida pode voltar para o
sandbox, onde o produto continua funcionando para testes e nada chega a usuários finais, uma decisão
muito menor do que uma suspensão.

## Deriva

A Doce Lar Confeitaria foi aceita no primeiro dia: um CNPJ real, o próprio domínio e atendimento a
clientes como caso de uso. O uso dela é registrado por semana, com o tema de cada requisição. **Os
temas foram escritos pelo curso** como um classificador os rotularia; um de verdade é um classificador
como os da aula 6, com erros próprios. Quatro semanas dele, e o programa que compara cada semana com o
caso de uso declarado, o `~/guard/tools/drift.py`:

```sh
cat > ~/guard/data/partner-usage.jsonl <<'EOF'
{"account": "p-docelar", "week": "2026-W33", "topic": "customer-support", "requests": 2016}
{"account": "p-docelar", "week": "2026-W33", "topic": "other", "requests": 84}
{"account": "p-docelar", "week": "2026-W34", "topic": "customer-support", "requests": 2128}
{"account": "p-docelar", "week": "2026-W34", "topic": "other", "requests": 112}
{"account": "p-docelar", "week": "2026-W35", "topic": "customer-support", "requests": 2262}
{"account": "p-docelar", "week": "2026-W35", "topic": "product-reviews", "requests": 1521}
{"account": "p-docelar", "week": "2026-W35", "topic": "other", "requests": 117}
{"account": "p-docelar", "week": "2026-W36", "topic": "customer-support", "requests": 2058}
{"account": "p-docelar", "week": "2026-W36", "topic": "product-reviews", "requests": 7546}
{"account": "p-docelar", "week": "2026-W36", "topic": "other", "requests": 196}
EOF
```

```python
# drift.py: a customer's weekly usage against the use case it declared.
#
#   guard drift ACCOUNT [--limit PCT]
#
# It reads data/partner-usage.jsonl, one line per account, week and topic, and
# flags a week in which more than PCT percent of the requests fell outside
# the declared use case.
import argparse
import json
import os

DECLARED = {"p-docelar": "customer-support"}

p = argparse.ArgumentParser(prog="guard drift")
p.add_argument("account")
p.add_argument("--limit", type=int, default=30)
a = p.parse_args()
declared = DECLARED[a.account]

weeks = {}
with open(os.path.expanduser("~/guard/data/partner-usage.jsonl")) as f:
    for line in f:
        r = json.loads(line)
        if r["account"] == a.account:
            weeks.setdefault(r["week"], {})[r["topic"]] = r["requests"]

print("%s declared: %s" % (a.account, declared))
print("week       requests  in use case  outside  largest outside")
for week, topics in weeks.items():
    n = sum(topics.values())
    inside = topics.get(declared, 0)
    out = {t: k for t, k in topics.items() if t != declared}
    top = max(out, key=out.get) if out else "-"
    share = 100 * (n - inside) / n
    print("%s  %8d  %10.0f%%  %6.0f%%  %s%s" % (
        week, n, 100 * inside / n, share, top, "  DRIFT" if share > a.limit else ""))
print("limit: more than %d%% of a week outside the declared use case" % a.limit)
```

```
ana@lab:~/guard$ guard drift p-docelar
p-docelar declared: customer-support
week       requests  in use case  outside  largest outside
2026-W33      2100          96%       4%  other
2026-W34      2240          95%       5%  other
2026-W35      3900          58%      42%  product-reviews  DRIFT
2026-W36      9800          21%      79%  product-reviews  DRIFT
limit: more than 30% of a week outside the declared use case
```

Por duas semanas, 95% ou mais das requisições da confeitaria são atendimento. Na terceira, 42% são
outra coisa, e a maior outra coisa é `product-reviews`. Na quarta, são 79%, e o volume mais que
quadruplicou desde a segunda semana, de 2.240 para 9.800 requisições. Os dois sinais apontam para o
mesmo lado: a chave agora escreve sobretudo avaliações de produtos, o uso de avaliações falsas que a
política proíbe. Avaliações escritas pelo vendedor e postadas como se fossem de clientes enganam quem as
lê, o que o Código de Defesa do Consumidor proíbe na publicidade (art. 37), e violam as regras de todo
marketplace em que são postadas.

O que acontece depois é uma escada, não um interruptor:

1. **Perguntar.** Uma mensagem ao cliente, citando os números. Um caso de uso pode mudar por um motivo
   legítimo, como uma confeitaria que passa a escrever descrições de produtos, que um classificador
   poderia rotular como avaliações.
2. **Restringir.** De volta ao sandbox enquanto a resposta não vem, se os números forem tão grandes
   quanto os da semana 36.
3. **Suspender.** Se a resposta confirmar um uso proibido, ou não vier.

Cada degrau é registrado com quem o tomou e por quê, e os números que o justificaram vão junto. A mesma
disciplina da aula 3 e da aula 6 vale aqui: **o limiar, 30% neste curso, é uma escolha**,
registrada com o motivo e revista quando dispara sobre clientes que se mostraram corretos.

## Onde isto deixa as defesas

A aula 7 fez cada requisição levar o identificador de uma pessoa; esta aula faz cada chave levar uma
empresa conhecida e uma finalidade declarada; a aula 9 restringe o que uma requisição pode pôr para
dentro e tirar para fora. Nenhuma das três basta sozinha, e um atacante precisa passar por todas ao
mesmo tempo.
