---
title: Sessões ou pessoas
version: 1
---

O funil da seção anterior contou **sessões**. As pessoas voltam: olham o cardápio no domingo, voltam
na segunda e pedem. Contado por sessão, isso é um fracasso e um sucesso; contado por pessoa, é um
sucesso.

```schooling-example
{"language": "python", "file": "people.py", "parts": [{"code": "import pandas as pd\n\nsessions = pd.read_csv(\"sessions.csv\")\nbest = sessions.groupby(\"visitor\")[\"step\"].max()", "note": "Para cada visitante, a etapa mais distante alcançada em qualquer das sessões dele."}, {"code": "print(f\"{len(sessions):,} sessions from {len(best):,} visitors, \"\n      f\"{len(sessions) / len(best):.2f} sessions each\")\nprint(f\"sessions that paid: {(sessions['step'] == 5).mean():.1%}\")\nprint(f\"visitors who paid in any session: {(best == 5).mean():.1%}\")", "note": "O mesmo mês contado de dois jeitos."}], "output": "55,800 sessions from 26,471 visitors, 2.11 sessions each\nsessions that paid: 14.4%\nvisitors who paid in any session: 27.0%"}
```

**14,4 por cento das sessões pagaram, e 27,0 por cento dos visitantes pagaram em pelo menos uma
sessão.** Os dois estão certos, e descrevem coisas diferentes. Um funil de sessões diz quão bem cada
visita converte, que é a lente certa para uma página ou um formulário: o checkout no celular falha por
visita. Um funil de pessoas diz quantas pessoas o site acaba transformando em clientes, que é a lente
certa para o marketing e para o negócio: algumas das sessões que "falharam" eram de pessoas que
pediram no dia seguinte.

Três regras mantêm os dois separados.

- **Diga o que um funil conta**, no título dele. "Conversão de 14 por cento" e "conversão de 27 por
  cento" do mesmo mês são as duas verdade.
- **Um funil de pessoas precisa de uma janela**: pagou na mesma sessão, em sete dias, no mês. Quanto
  mais longa a janela, maior a taxa, e mais tarde o número fica final, que é a censura da aula 12 em
  outra forma.
- **Uma pessoa só é tão boa quanto o identificador**, como a aula 9 viu nos experimentos: um visitante
  no celular e no notebook são duas pessoas para o cookie, e um funil de pessoas montado em cookies
  conta menos as pessoas que trocam de aparelho antes de pagar, justamente as que um checkout de
  celular quebrado produz.
