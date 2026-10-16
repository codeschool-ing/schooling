---
title: Dimensionar o conserto, e testá-lo
version: 1
---

Uma etapa quebrada é motivo para agir; o tamanho do prêmio decide a urgência. A estimativa padrão
pergunta o que a etapa produziria se funcionasse tão bem quanto em outro lugar:

```schooling-example
{"language": "python", "file": "sizing.py", "parts": [{"code": "import pandas as pd\n\nsessions = pd.read_csv(\"sessions.csv\")\nat_checkout = sessions[sessions[\"step\"] >= 4]\nrate = at_checkout.groupby(\"device\")[\"step\"].apply(lambda s: (s == 5).mean())\nmobile = at_checkout[at_checkout[\"device\"] == \"mobile\"]", "note": "Só as sessões que chegaram ao checkout, e a fração delas que pagou, por aparelho."}, {"code": "paid_now = (mobile[\"step\"] == 5).sum()\npaid_if = len(mobile) * rate[\"desktop\"]\nprint(f\"checkout to paid: desktop {rate['desktop']:.1%}, mobile {rate['mobile']:.1%}\")\nprint(f\"mobile sessions at checkout in March: {len(mobile):,}, of which paid: {paid_now:,}\")\nprint(f\"if mobile paid like desktop: {paid_if:,.0f}, that is {paid_if - paid_now:,.0f} more in a month\")", "note": "O que a etapa do celular produziria na taxa do computador, como teto do que vale consertá-la."}], "output": "checkout to paid: desktop 82.8%, mobile 48.3%\nmobile sessions at checkout in March: 9,242, of which paid: 4,467\nif mobile paid like desktop: 7,652, that is 3,185 more in a month"}
```

**Se o checkout no celular pagasse na taxa do computador, março teria tido 3.185 sessões pagas a
mais.** Contra as 8.062 que o funil inteiro produziu, é um número grande, e vale dizê-lo com cuidado.

- **É um teto, não uma previsão.** O celular talvez nunca alcance o notebook: digitar um número de
  cartão numa tela pequena sempre vai perder alguém. O jeito honesto de dizer é "até".
- **Conta sessões.** Algumas falhas no celular voltaram e pagaram em outra visita ou aparelho, então os
  pedidos extras são menos que as sessões pagas extras; o funil de pessoas da seção anterior é como
  limitar isso.
- **Supõe que as pessoas continuam as mesmas.** Consertar o checkout não muda nada em quem chega a ele,
  então a estimativa mantém as etapas de cima fixas, o que é razoável para um conserto tão no fundo do
  funil.

## Do funil ao experimento

Um funil acha onde olhar e quanto está em jogo; **ele não mostra que uma mudança funciona**. Esse é o
trabalho de um teste A/B. O checkout de um passo das aulas 7 a 11 é exatamente essa história: o funil
apontou a etapa de pagamento no celular, a hipótese da aula 7 a nomeou, e o experimento mediu o que a
página nova fez. Um funil comparado antes e depois de um redesenho, em vez disso, é a comparação de
antes e depois que a aula 7 mostrou ser pouco confiável.

## O que um funil não enxerga

Um funil registra as etapas que alguém definiu. Um visitante que sai no cardápio porque faltava uma
receita que ele queria parece igual a um que só estava olhando. **Por que as pessoas param é uma
pergunta para outras evidências**: os termos buscados no site, os erros registrados em cada etapa e,
pelo menos de vez em quando, perguntar a alguns clientes.
