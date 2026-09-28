---
title: O orçamento de erro
version: 1
---

Um objetivo de 99,9% parece uma exigência de perfeição que fica um pouco aquém. Lido pelo outro lado, é
uma margem: **0,1% do tempo pode ser gasto fora do ar, e a equipe decide em que gastá-lo.** Essa margem é o
**orçamento de erro** (error budget), e tratá-la como orçamento muda a conversa. Este programa faz a conta
para um mês de 30 dias, e conta quantos failovers como o que a aula 15 mediu caberiam em cada um:

```schooling-example
{"language": "python", "file": "budget.py", "parts": [{"code": "MONTH = 30 * 24 * 60 * 60  # a 30-day month, in seconds\nFAILOVER = 3.264           # the gap lesson 15 measured, in seconds", "note": "A janela é um mês de 30 dias, dita em vez de suposta. O failover é o buraco que a aula 15 mediu no ping, da última resposta antes de o cabo ser puxado até a primeira depois."}, {"code": "for slo in (0.99, 0.999, 0.9995, 0.9999):\n    budget = MONTH * (1 - slo)", "note": "O orçamento é o que o objetivo deixa de sobra: 1% do mês com 99%, um décimo disso com 99,9%."}, {"code": "    print(f\"{slo:.2%}  budget {budget / 60:6.2f} min  \"\n          f\"= {int(budget // FAILOVER):5} failovers of {FAILOVER} s\")", "note": "Cada orçamento em minutos, e como o número de failovers inteiros daquela duração que ele absorveria."}], "output": "99.00%  budget 432.00 min  =  7941 failovers of 3.264 s\n99.90%  budget  43.20 min  =   794 failovers of 3.264 s\n99.95%  budget  21.60 min  =   397 failovers of 3.264 s\n99.99%  budget   4.32 min  =    79 failovers of 3.264 s"}
```

Duas coisas na saída merecem uma segunda olhada.

**A janela muda o número.** A aula 14 deu 43,80 minutos por mês para 99,9%, usando um doze avos de um ano
de 365 dias, que é um mês médio de cerca de 30,4 dias. Aqui, com um mês de 30 dias, dá 43,20. A diferença
é pequena, e é exatamente o tipo de diferença sobre a qual as duas partes de um contrato acabam
discutindo, e é por isso que um SLA diz qual é a janela.

**Failovers são baratos e pessoas são caras.** Com três noves, 794 failovers de 3,264 segundos cabem num
mês; com quatro noves, 79 ainda cabem. Um único incidente que precisa de uma pessoa, um chamado de
madrugada, alguém entrando no sistema, um diagnóstico e um reinício, leva muito mais: mesmo em rápidos 45
minutos ele gasta sozinho mais do que o mês inteiro de 99,9%, 43,20 minutos. **O orçamento não é gasto
pelas falhas que as máquinas resolvem; é gasto pelas que esperam alguém.** Esse é o argumento de verdade a
favor do failover automático das aulas 15 e 16, dito em minutos.

## Gastando de propósito

Um orçamento também é uma permissão. Toda mudança num sistema em produção arrisca algum tempo fora do ar:
uma implantação, uma atualização, uma configuração aplicada num balanceador. Se o orçamento do mês está
intacto, a equipe pode andar mais rápido e correr esses riscos. Se está gasto, a política sensata é parar
de mudar coisas até ele se recuperar, e pôr o esforço no que o gastou.

Isso transforma uma briga antiga entre quem constrói funcionalidades e quem mantém o serviço no ar numa
aritmética que os dois conseguem ler. **Um objetivo de 100% é uma promessa de nunca mudar nada**, porque
toda mudança tem risco; o orçamento de erro é a quantidade combinada de risco que o negócio aceita comprar
com a sua velocidade.
