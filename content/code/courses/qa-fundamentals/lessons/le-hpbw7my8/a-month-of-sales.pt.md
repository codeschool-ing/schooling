---
title: Um mês de vendas, contado
version: 1
---

**Antes da entrega, o defeito da pessoa de sessenta anos custou dois comandos para ser achado e um
caractere para ser corrigido.** Vale ver o que o mesmo defeito custa se for para produção, e não é
preciso imaginar: um programa curto pode vender um mês de ingressos pelo `tickets.py` e contar.

As vendas reais do Cine Aurora não estão neste curso, então o programa inventa um mês plausível a partir
de uma semente fixa. O que ele cobra não é inventado: todo preço vem do próprio `price` da loja. Salve-o
em `~/aurora`, ao lado do `tickets.py`, como `overcharge.py`.

```schooling-example
{"language": "python", "file": "overcharge.py", "parts": [{"code": "# overcharge.py\nimport random\nfrom tickets import brl, price\n", "note": "Usa o `price` e o `brl` da própria loja, do `tickets.py`, então cobra exatamente o que a loja cobraria. Deixe os dois arquivos em `~/aurora`."}, {"code": "\nDAYS = [\"thu\", \"fri\", \"sat\", \"sun\", \"mon\", \"tue\", \"wed\"]\nSESSIONS = [\"14:00\", \"16:30\", \"19:00\", \"21:30\"]\n", "note": "Uma semana começando na quinta, que é o dia em que os filmes estreiam no Brasil, e as quatro sessões de uma sala."}, {"code": "\nrng = random.Random(30)\nsold = tickets = extra = 0\nfor n in range(30):\n    day = DAYS[n % 7]\n    for _ in range(120):\n        age = rng.randint(15, 80)\n        time = rng.choice(SESSIONS)\n        paid = price(age, False, day, time)\n        sold += 1\n", "note": "Trinta dias de 120 vendas online cada, para clientes de 15 a 80 anos, nenhum estudante. As vendas são inventadas, a partir de uma semente fixa, então toda execução produz o mesmo mês e os seus números batem com estes."}, {"code": "        if age == 60 and day != \"wed\":\n            tickets += 1\n            extra += paid - paid // 2\n", "note": "Quem tem sessenta anos deveria ter pago meia. Na quarta todo mundo paga meia de qualquer jeito, então o defeito não custa nada nesse dia e não é contado."}, {"code": "\nprint(sold, \"tickets sold in 30 days\")\nprint(tickets, \"of them to a sixty-year-old, outside a Wednesday\")\nprint(brl(extra), \"charged too much\")\n", "note": "Os três números que uma gerente pediria."}]}
```

```
lia@lab:~/aurora$ python overcharge.py
3600 tickets sold in 30 days
41 of them to a sixty-year-old, outside a Wednesday
R$ 658,00 charged too much
```

**Quarenta e um ingressos, R$ 658,00.** Isso é uma sala, um mês, só vendas online. É o menor dos quatro
custos da seção anterior, o que dá para contar, e já é mais do que a correção jamais custou.

## O que a conta não inclui

Veja no que cada um desses quarenta e um ingressos se transforma quando o defeito é achado:

- **achar os clientes.** A loja registra uma venda; pode registrar ou não a idade que foi digitada. Se não
  registra, ninguém consegue dizer quais dos 3600 ingressos foram para alguém de sessenta anos, e o
  reembolso vira um aviso no balcão pedindo que as pessoas se apresentem;
- **reembolsá-los**, por um provedor de pagamento que cobra uma tarifa por estorno;
- **as conversas.** A Célia fica sabendo pelos clientes fiéis antes de qualquer outra pessoa, e cada
  conversa é dez minutos da noite dela;
- **o segundo defeito.** O programa acima precisou pular as quartas, porque na quarta a loja cobra meia de
  todo mundo. Enquanto o escrevia, a Lia percebeu o que essa linha implica para um estudante numa quarta. A
  aula 6 roda esse caso.

Nenhum desses tem um número na saída, e todos são reais. Essa é a forma honesta da curva famosa: a parte
que dá para contar é pequena, e ela é o piso.

## Contando ao contrário

Agora mude uma coisa. Suponha que o defeito tivesse sido achado e corrigido antes da primeira venda. O
programa imprimiria `R$ 0,00`, e todos os itens da lista acima sumiriam junto. **A economia de achar um
defeito cedo é tudo o que teria acontecido depois**, e a maior parte disso nunca aparece no relatório de
ninguém, e é exatamente por isso que os times a subestimam.

O programa também mostra um hábito que vale manter: quando alguém pergunta *quão grave é?*, meça antes de
responder. "Alguns aposentados foram cobrados a mais" provoca um dar de ombros. "Quarenta e um ingressos
num mês numa sala, R$ 658,00 antes das tarifas de estorno" faz uma correção entrar na agenda.
